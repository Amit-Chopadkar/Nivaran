import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cryptography/cryptography.dart';
import '../models/mesh_message.dart';
import 'local_storage_service.dart';
import 'supabase_service.dart';

/// Mesh service using Nearby Connections API.
/// Works over Bluetooth + WiFi Direct (no internet needed).
/// In airplane mode: turn BT back on manually, the BLE transport still works.
class MeshService extends ChangeNotifier {
  static const Strategy strategy = Strategy.P2P_CLUSTER;
  static const String _serviceId = 'com.safeher.mesh';

  /// Our own stable UUID for this device/session
  final String userId = const Uuid().v4();

  /// Human-readable name shown to peers
  String userName;

  /// Name broadcasted over BLE (includes our short ID to prevent tie collisions)
  String get _broadcastName => '${userId.substring(0, 8)}|$userName';

  /// All peers we have seen: endpointId -> displayName
  final Map<String, String> nearbyEndpoints = {};

  /// Peers that are fully connected: endpointId -> displayName
  final Map<String, String> connectedPeers = {};

  /// Maps endpointId -> peer's userId (UUID) — populated via handshake
  final Map<String, String> endpointToUserId = {};

  /// Reverse: peer userId -> endpointId
  final Map<String, String> userIdToEndpoint = {};

  /// Supabase Realtime Channel for Internet Broadcast Sync
  RealtimeChannel? _broadcastChannel;

  /// Stream for call signalling messages (non-chat)
  final _signalingController = StreamController<MeshMessage>.broadcast();
  Stream<MeshMessage> get signalingStream => _signalingController.stream;

  Timer? _ttlTimer;

  /// Stream for new chat messages
  final _chatMessageController = StreamController<MeshMessage>.broadcast();
  Stream<MeshMessage> get chatMessageStream => _chatMessageController.stream;

  bool isAdmin = false; // Set this to true from settings for the 'Gateway' device

  /// Toggle admin/gateway mode and notify listeners.
  void toggleAdmin() {
    isAdmin = !isAdmin;
    notifyListeners();
  }

  // ─── Mesh Security ───
  static final _cipher = AesGcm.with256bits();
  static final _key = SecretKey([
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
    17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32
  ]); // In a real app, this should be derived from a shared secret or PBKDF2

  MeshService({this.userName = 'Nivaran User'});

  void updateUserName(String name) {
    if (name.isNotEmpty && userName != name) {
      userName = name;
      notifyListeners();
    }
  }

  // ─── Public API ─────────────────────────────────────────────────────────

  Future<void> init() async {
    await _safeStop();
    await startAdvertising();
    await startDiscovery();

    // ─── Supabase Realtime Broadcast Sync ───
    final supabase = Supabase.instance.client;

    // Fetch history so users don't miss past alerts
    try {
      final history = await supabase
          .from('mesh_broadcasts')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
          
      for (var data in history.reversed) {
        final id = data['id'];
        final senderId = data['sender_id'];
        if (id == null || senderId == null || senderId == userId) continue;

        final isFromAdmin = data['is_admin'] == true;
        if (isFromAdmin && !connectedPeers.containsKey(senderId)) {
           userIdToEndpoint[senderId] = senderId;
           endpointToUserId[senderId] = senderId;
           connectedPeers[senderId] = 'Command Center';
        } else if (!connectedPeers.containsKey(senderId)) {
           connectedPeers[senderId] = data['sender_name'] ?? 'Remote User';
        }

        if (!LocalStorageService.chatBox.containsKey(id)) {
           final msg = MeshMessage(
             id: id,
             senderId: senderId,
             senderName: data['sender_name'] ?? 'Remote User',
             receiverId: 'broadcast',
             payload: data['payload'] ?? '',
             timestamp: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
             type: 'chat',
             deliveryStatus: 'delivered_to_admin',
           );
           await LocalStorageService.addMessage(msg);
           _chatMessageController.add(msg);
        }
      }
    } catch (e) {
      debugPrint('[Mesh] Failed to fetch broadcast history: $e');
    }

    await _broadcastChannel?.unsubscribe();
    
    _broadcastChannel = supabase.channel('public:mesh_broadcasts').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'mesh_broadcasts',
      callback: (payload) async {
        final data = payload.newRecord;
        // Don't echo our own messages back (tracked by sender_id)
        if (data['sender_id'] == userId) return;

        // Prefix name with [ADMIN] for clarity if it's from the dashboard


        final msg = MeshMessage(
          id: data['id'] ?? const Uuid().v4(),
          senderId: data['sender_id'] ?? 'unknown',
          senderName: data['sender_name'] ?? 'Remote User',
          receiverId: 'broadcast',
          payload: data['payload'] ?? '',
          timestamp: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
          type: 'chat',
          deliveryStatus: 'delivered_to_admin',
        );

        // Slight hack to pass the sender name through the UI without breaking MeshMessage structure:
        // By changing the broadcast sender ID artificially or registering an 'admin' endpoint,
        // we can cheat it. For now, since it resolves via connectedPeers, let's inject a fake peer.
        final isFromAdmin = data['is_admin'] == true;
        if (isFromAdmin && !connectedPeers.containsKey(msg.senderId)) {
           userIdToEndpoint[msg.senderId] = msg.senderId;
           endpointToUserId[msg.senderId] = msg.senderId;
           connectedPeers[msg.senderId] = 'Command Center';
        } else if (!connectedPeers.containsKey(msg.senderId)) {
           // Provide a fallback name for remote mobile users via Supabase
           connectedPeers[msg.senderId] = data['sender_name'] ?? 'Remote User';
        }

        if (!LocalStorageService.chatBox.containsKey(msg.id)) {
           await LocalStorageService.addMessage(msg);
           _chatMessageController.add(msg);
           notifyListeners();
        }
      },
    );
    _broadcastChannel?.subscribe();

    _ttlTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final awaiting = LocalStorageService.getMessagesAwaitingAck();
      final now = DateTime.now();
      bool changed = false;
      for (var msg in awaiting) {
         if (now.difference(msg.timestamp).inSeconds > 120 && (msg.deliveryStatus == 'pending' || msg.deliveryStatus == 'relayed')) {
            msg.deliveryStatus = 'unconfirmed';
            msg.save();
            changed = true;
         }
      }
      if (changed) notifyListeners();
    });
  }

  Future<void> stopAll() async {
    _ttlTimer?.cancel();
    await _safeStop();
    await _broadcastChannel?.unsubscribe();
    _broadcastChannel = null;
    connectedPeers.clear();
    nearbyEndpoints.clear();
    endpointToUserId.clear();
    userIdToEndpoint.clear();
    notifyListeners();
  }

  Future<void> _prepareAndSendMessage(String? endpointId, MeshMessage msg) async {
    // 1. Mark as processed locally to avoid looping back to self
    await LocalStorageService.markProcessed(msg.id);
    
    // 2. Initialize path trace
    msg.pathTrace = [userId];
    msg.hopCount = 0;

    // 3. Encrypt payload
    final secureMsg = await _encryptMessage(msg);

    // 4. Send or Queue
    if (endpointId != null) {
      await _sendBytes(endpointId, secureMsg);
    } else {
      await LocalStorageService.queuePendingRelay(secureMsg);
      debugPrint('[Mesh] Peer offline – message queued for relay');
    }
  }

  /// Send a direct message. [peerUserId] is the peer's UUID.
  Future<void> sendDirectMessage(String peerUserId, MeshMessage msg) async {
    await LocalStorageService.addMessage(msg);
    notifyListeners();
    final endpointId = userIdToEndpoint[peerUserId];
    await _prepareAndSendMessage(endpointId, msg);
  }

  Future<void> broadcastMessage(MeshMessage msg) async {
    await LocalStorageService.addMessage(msg);
    notifyListeners();
    
    // 1. Flooding: Send to all connected peers
    final connectedIds = List<String>.from(connectedPeers.keys);
    if (connectedIds.isEmpty) {
      await _prepareAndSendMessage(null, msg);
    } else {
      for (final id in connectedIds) {
        await _prepareAndSendMessage(id, msg);
      }
    }

    // Also push to Supabase for the Admin Dashboard and remote users
    try {
      Supabase.instance.client.from('mesh_broadcasts').insert({
        'id': msg.id,
        'sender_id': msg.senderId,
        'sender_name': msg.senderName, // use message senderName instead
        'payload': msg.payload,
        'is_admin': isAdmin,
      }).catchError((e) {
        debugPrint('[Mesh] Failed to sync broadcast to Supabase: $e');
      });
    } catch (e) {
      debugPrint('[Mesh] Failed to sync broadcast to Supabase: $e');
    }
  }

  /// Send directly to a BLE endpointId (used by call signaling)
  Future<void> sendToEndpoint(String endpointId, MeshMessage msg) async {
    await _sendBytes(endpointId, msg);
  }

  // ─── Advertising ─────────────────────────────────────────────────────────

  Future<void> startAdvertising() async {
    try {
      await Nearby().startAdvertising(
        _broadcastName,
        strategy,
        serviceId: _serviceId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
      debugPrint('[Mesh] Advertising started ($_broadcastName)');
    } catch (e) {
      debugPrint('[Mesh] Advertising error: $e');
    }
  }

  // ─── Discovery ───────────────────────────────────────────────────────────

  Future<void> startDiscovery() async {
    try {
      await Nearby().startDiscovery(
        _broadcastName,
        strategy,
        serviceId: _serviceId,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: (id) {
          nearbyEndpoints.remove(id);
          notifyListeners();
          debugPrint('[Mesh] Endpoint lost: $id');
        },
      );
      debugPrint('[Mesh] Discovery started');
    } catch (e) {
      debugPrint('[Mesh] Discovery error: $e');
    }
  }

  // ─── Connection Handlers ─────────────────────────────────────────────────

  void _onEndpointFound(String id, String name, String serviceId) {
    debugPrint('[Mesh] Found endpoint $id ($name)');
    if (connectedPeers.containsKey(id)) return;
    
    // Parse the broadcast name
    final parts = name.split('|');
    final peerShortId = parts[0];
    final peerName = parts.length > 1 ? parts.sublist(1).join('|') : name;

    nearbyEndpoints[id] = peerName;
    notifyListeners();

    // Deterministic tie-breaker to prevent collision
    final myShortId = userId.substring(0, 8);
    if (myShortId.compareTo(peerShortId) > 0) {
      debugPrint('[Mesh] I am initiating connection to $id');
      Nearby().requestConnection(
        _broadcastName,
        id,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      ).catchError((e) {
        debugPrint('[Mesh] requestConnection error: $e');
        return false;
      });
    } else {
      debugPrint('[Mesh] Waiting for $id to initiate connection');
    }
  }

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    debugPrint('[Mesh] Connection initiated with $endpointId (${info.endpointName})');
    
    final name = info.endpointName;
    final parts = name.split('|');
    final peerName = parts.length > 1 ? parts.sublist(1).join('|') : name;

    nearbyEndpoints[endpointId] = peerName;
    notifyListeners();

    Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: (id, update) {},
    ).catchError((e) {
      debugPrint('[Mesh] acceptConnection error: $e');
      return false;
    });
  }

  void _onConnectionResult(String endpointId, Status status) {
    final name = nearbyEndpoints[endpointId] ?? endpointId;
    debugPrint('[Mesh] Connection result $endpointId ($name): $status');
    if (status == Status.CONNECTED) {
      connectedPeers[endpointId] = name;
      nearbyEndpoints[endpointId] = name;
      notifyListeners();
      // Send handshake immediately
      _sendHandshake(endpointId);
      // Sync any pending relays for this new peer
      _syncAllPendingRelays(endpointId);
    } else {
      connectedPeers.remove(endpointId);
      notifyListeners();
    }
  }

  void _onDisconnected(String endpointId) async {
    debugPrint('[Mesh] Disconnected $endpointId');
    final peerUserId = endpointToUserId[endpointId];
    if (peerUserId != null) userIdToEndpoint.remove(peerUserId);
    endpointToUserId.remove(endpointId);
    connectedPeers.remove(endpointId);
    nearbyEndpoints.remove(endpointId);
    notifyListeners();

    // If a connection drops (e.g., WiFi turned off, forcing a fallback to Bluetooth),
    // Nearby Connections may not automatically call onEndpointFound again for peers still in range.
    // Restarting both discovery and advertising forces a fresh scan so we can quickly reconnect over the fallback medium.
    await Future.delayed(const Duration(seconds: 2));
    try {
      await Nearby().stopDiscovery();
      await Nearby().stopAdvertising();
      await startDiscovery();
      await startAdvertising();
    } catch (e) {
      debugPrint('[Mesh] Error restarting mesh on disconnect: $e');
    }
  }

  // ─── Payload Handlers ────────────────────────────────────────────────────

  Future<void> _onPayloadReceived(String endpointId, Payload payload) async {
    if (payload.type != PayloadType.BYTES || payload.bytes == null) return;
    try {
      final jsonStr = utf8.decode(payload.bytes!);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final type = json['type'] as String? ?? '';

      // Handle handshake
      if (type == 'handshake') {
        final peerUserId = json['userId'] as String;
        final peerName = json['name'] as String? ??
            connectedPeers[endpointId] ?? 'Unknown';
        endpointToUserId[endpointId] = peerUserId;
        userIdToEndpoint[peerUserId] = endpointId;
        connectedPeers[endpointId] = peerName;
        nearbyEndpoints[endpointId] = peerName;
        debugPrint('[Mesh] Handshake: $endpointId => userId=$peerUserId name=$peerName');
        notifyListeners();
        
        // Sync any queued offline messages
        _syncPendingMessages(peerUserId, endpointId);
        return;
      }

      if (type == 'receipt') {
        final msgId = json['messageId'] as String;
        // On local receipt, mark relayed
        await LocalStorageService.updateDeliveryStatus(msgId, 'relayed');
        notifyListeners();
        return;
      }

      final msg = MeshMessage.fromJson(json);

      // ─── Multi-Hop Protocol ───
      // 1. Deduplication
      if (LocalStorageService.isProcessed(msg.id)) {
        _sendReceipt(endpointId, msg.id);
        return;
      }
      await LocalStorageService.markProcessed(msg.id);

      // 2. Security: Decrypt if needed
      MeshMessage processedMsg = msg;
      if (msg.isEncrypted) {
        processedMsg = await _decryptMessage(msg);
      }

      if (processedMsg.type != 'chat' && processedMsg.type != 'sos_alert') {
        debugPrint('[Mesh] Signalling: ${processedMsg.type}');
        _signalingController.add(processedMsg);
        return;
      }

      if (processedMsg.type == 'sos_alert') {
        debugPrint('[Mesh] SOS Alert Relay/Recv from ${processedMsg.senderName}');
        try {
          final sosData = jsonDecode(processedMsg.payload);
          final String? timestampStr = sosData['timestamp'];
          final DateTime? triggerTime = timestampStr != null ? DateTime.tryParse(timestampStr) : null;

          // Try to upload to Superbase on behalf of offline sender if we have internet
          SupabaseService.logSOSEvent(
            userEmail: sosData['user_email'] ?? 'unknown',
            type: 'Crime',
            latitude: sosData['latitude'] ?? 0.0,
            longitude: sosData['longitude'] ?? 0.0,
            blockchainHash: null,
            createdAt: triggerTime,
          ).then((result) {
            if (result['success'] == true) {
              debugPrint('Supabase: Peer SOS Alert logged successfully for ${sosData['user_email']}');
            }
          });
        } catch (e) {
          debugPrint('[Mesh] SOS Alert parsing error: $e');
        }
      } else {
        debugPrint('[Mesh] Relay/Recv from ${processedMsg.senderId}: "${processedMsg.payload}" (Hops: ${processedMsg.hopCount})');

        // 3. Local Delivery
        if (processedMsg.receiverId == userId || processedMsg.receiverId == 'broadcast' || (isAdmin && processedMsg.receiverId == 'admin')) {
             if (!LocalStorageService.chatBox.containsKey(processedMsg.id)) {
                await LocalStorageService.addMessage(processedMsg);
                _chatMessageController.add(processedMsg);
                notifyListeners();
             }

             // Special: Admin node sends a receipt back through the mesh
             if (isAdmin && processedMsg.receiverId == 'admin') {
               _sendAdminReceipt(processedMsg);
             }
        }
      }
      
      // If we received an admin receipt, notify the UI
      if (processedMsg.type == 'admin_ack' || processedMsg.type == 'admin_receipt') {
        String originalMsgId = processedMsg.payload;
        if (processedMsg.type == 'admin_ack') {
          try {
            final adminAckData = jsonDecode(processedMsg.payload);
            originalMsgId = adminAckData['message_id'] as String;
          } catch (_) {}
        }
        await LocalStorageService.updateDeliveryStatus(originalMsgId, 'delivered_to_admin');
        notifyListeners();
      }

      // 4. Relay Logic: Controlled Flooding
      await _relayMeshMessage(processedMsg, endpointId);
    } catch (e) {
      debugPrint('[Mesh] Error handling payload: $e');
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Future<void> _sendHandshake(String endpointId) async {
    try {
      final handshake = jsonEncode({
        'type': 'handshake',
        'userId': userId,
        'name': userName,
      });
      final bytes = Uint8List.fromList(utf8.encode(handshake));
      await Nearby().sendBytesPayload(endpointId, bytes);
      debugPrint('[Mesh] Handshake sent to $endpointId');
    } catch (e) {
      debugPrint('[Mesh] Handshake error: $e');
    }
  }

  Future<void> _sendBytes(String endpointId, MeshMessage msg) async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(msg.toJson())));
      await Nearby().sendBytesPayload(endpointId, bytes);
      debugPrint('[Mesh] Sent ${msg.type} to $endpointId (${bytes.length} bytes)');
    } catch (e) {
      debugPrint('[Mesh] Error sending to $endpointId: $e');
    }
  }

  Future<void> _sendReceipt(String endpointId, String messageId) async {
    try {
      final receipt = jsonEncode({
        'type': 'receipt',
        'messageId': messageId,
      });
      final bytes = Uint8List.fromList(utf8.encode(receipt));
      await Nearby().sendBytesPayload(endpointId, bytes);
    } catch (e) {
      debugPrint('[Mesh] Receipt error: $e');
    }
  }

  // ─── Multi-Hop Mesh Logic ───

  Future<void> _relayMeshMessage(MeshMessage msg, String fromEndpointId) async {
    // Increment hops and trace path
    msg.hopCount++;
    if (!msg.pathTrace.contains(userId)) {
      msg.pathTrace = [...msg.pathTrace, userId];
    }

    // Controlled Flooding: Forward to all connected peers except the source
    bool relayed = false;
    for (final id in connectedPeers.keys) {
      if (id != fromEndpointId) {
        await _sendBytes(id, msg);
        relayed = true;
      }
    }

    // Store and Forward: If no other peers are connected, queue for future relay
    if (!relayed && msg.receiverId != userId) {
      await LocalStorageService.queuePendingRelay(msg);
      debugPrint('[Mesh] Message ${msg.id} queued for future relay');
    }
  }

  Future<void> _syncAllPendingRelays(String newEndpointId) async {
    final pending = LocalStorageService.getPendingRelays();
    if (pending.isEmpty) return;

    debugPrint('[Mesh] Syncing ${pending.length} pending relays to $newEndpointId');
    for (final msg in pending) {
      // Don't relay back to anyone in the path trace to avoid immediate circles
      if (!msg.pathTrace.contains(endpointToUserId[newEndpointId])) {
        await _sendBytes(newEndpointId, msg);
        // After one successful relay in a cluster, we can consider removing it from pending
        // or keep it for other neighbors depending on flooding strategy.
        // For controlled flooding, we keep it for some time or until a receipt is received.
        // For now, let's keep it until TTL or next sync.
      }
    }
    
    // Also opportunistically retry unconfirmed/pending messages that require ACK
    final awaiting = LocalStorageService.getMessagesAwaitingAck();
    for (var msg in awaiting) {
       if (!msg.pathTrace.contains(endpointToUserId[newEndpointId])) {
         // Mark as relayed again and retransmit
         await LocalStorageService.updateDeliveryStatus(msg.id, 'relayed');
         await _sendBytes(newEndpointId, msg);
       }
    }
  }

  // ─── Security Helpers ───

  Future<MeshMessage> _encryptMessage(MeshMessage msg) async {
    try {
      final nonce = List<int>.generate(12, (i) => i); // Non-random for demo consistency, use random in prod
      final secretBox = await _cipher.encrypt(
        utf8.encode(msg.payload),
        secretKey: _key,
        nonce: nonce,
      );
      final encryptedPayload = base64Encode(secretBox.concatenation());
      
      return MeshMessage(
        id: msg.id,
        senderId: msg.senderId,
        receiverId: msg.receiverId,
        payload: encryptedPayload,
        timestamp: msg.timestamp,
        type: msg.type,
        deliveryStatus: msg.deliveryStatus,
        hopCount: msg.hopCount,
        pathTrace: msg.pathTrace,
        isEncrypted: true,
        senderName: msg.senderName,
        ackRequired: msg.ackRequired,
      );
    } catch (e) {
      debugPrint('[Mesh] Encryption error: $e');
      return msg;
    }
  }

  Future<MeshMessage> _decryptMessage(MeshMessage msg) async {
    try {
      final data = base64Decode(msg.payload);
      final secretBox = SecretBox.fromConcatenation(
        data,
        nonceLength: 12,
        macLength: 16,
      );
      final clearText = await _cipher.decrypt(
        secretBox,
        secretKey: _key,
      );
      
      return MeshMessage(
        id: msg.id,
        senderId: msg.senderId,
        receiverId: msg.receiverId,
        payload: utf8.decode(clearText),
        timestamp: msg.timestamp,
        type: msg.type,
        deliveryStatus: msg.deliveryStatus,
        hopCount: msg.hopCount,
        pathTrace: msg.pathTrace,
        isEncrypted: false,
        senderName: msg.senderName,
        ackRequired: msg.ackRequired,
      );
    } catch (e) {
      debugPrint('[Mesh] Decryption error: $e');
      return msg; // Return encrypted if failed
    }
  }

  Future<void> _sendAdminReceipt(MeshMessage originalMsg) async {
    final payloadJson = jsonEncode({
      'message_id': originalMsg.id,
      'admin_id': userId,
      'ack_timestamp': DateTime.now().toIso8601String(),
      'status': 'received_by_admin',
    });
    
    final receipt = MeshMessage(
      id: const Uuid().v4(),
      senderId: userId, // I am the admin
      senderName: userName,
      receiverId: originalMsg.senderId,
      payload: payloadJson, // Payload is the original message ID
      timestamp: DateTime.now(),
      type: 'admin_ack',
      pathTrace: [userId],
      hopCount: 0,
    );
    
    debugPrint('[Mesh] Admin Receipt sent for message ${originalMsg.id}');
    await _relayMeshMessage(receipt, 'admin_self');
  }

  Future<void> _syncPendingMessages(String peerUserId, String endpointId) async {
    // Allows brief delay for connection to stabilize
    await Future.delayed(const Duration(milliseconds: 500));
    final msgs = LocalStorageService.getMessagesFor(peerUserId);
    int sentCount = 0;
    for (final m in msgs) {
      if (m.senderId == userId && m.deliveryStatus != 'delivered_to_admin' && m.type == 'chat') {
        await _sendBytes(endpointId, m);
        sentCount++;
      }
    }
    if (sentCount > 0) debugPrint('[Mesh] Synced $sentCount offline messages to $peerUserId');
  }

  Future<void> _safeStop() async {
    try { await Nearby().stopAdvertising(); } catch (_) {}
    try { await Nearby().stopDiscovery(); } catch (_) {}
    try { await Nearby().stopAllEndpoints(); } catch (_) {}
  }
}
