import 'package:hive_flutter/hive_flutter.dart';
import '../models/mesh_message.dart';
import '../models/evidence.dart';

class LocalStorageService {
  static const String chatBoxName = 'mesh_chats';
  static const String evidenceBoxName = 'evidence_vault';
  static const String processedBoxName = 'mesh_processed';
  static const String pendingRelayBoxName = 'mesh_pending';
  static const String settingsBoxName = 'app_settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MeshMessageAdapter());
    Hive.registerAdapter(EvidenceAdapter());
    
    // Attempt to open chatBox, wipe if schema mismatch
    try {
      await Hive.openBox<MeshMessage>(chatBoxName);
    } catch (e) {
      await Hive.deleteBoxFromDisk(chatBoxName);
      await Hive.openBox<MeshMessage>(chatBoxName);
    }

    try {
      await Hive.openBox<MeshMessage>(pendingRelayBoxName);
    } catch (e) {
      await Hive.deleteBoxFromDisk(pendingRelayBoxName);
      await Hive.openBox<MeshMessage>(pendingRelayBoxName);
    }

    await Hive.openBox<Evidence>(evidenceBoxName);
    await Hive.openBox<bool>(processedBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box<MeshMessage> get chatBox => Hive.box<MeshMessage>(chatBoxName);

  static Future<void> addMessage(MeshMessage message) async {
    await chatBox.put(message.id, message);
  }

  static Future<void> updateDeliveryStatus(String messageId, String status) async {
    final msg = chatBox.get(messageId);
    if (msg != null) {
      msg.deliveryStatus = status;
      await msg.save();
    }
  }

  static List<MeshMessage> getMessagesAwaitingAck() {
    return chatBox.values
        .where((m) => m.ackRequired && (m.deliveryStatus == 'pending' || m.deliveryStatus == 'relayed' || m.deliveryStatus == 'unconfirmed'))
        .toList();
  }

  static List<MeshMessage> getMessagesFor(String peerId) {
    final messages = chatBox.values
        .where((m) =>
            (m.senderId == peerId || m.receiverId == peerId || m.receiverId == 'broadcast') &&
            m.type == 'chat')
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }
  
  static List<MeshMessage> getAllChatMessages() {
    return chatBox.values.where((m) => m.type == 'chat').toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Mesh Protocol Helpers
  static Box<bool> get processedBox => Hive.box<bool>(processedBoxName);
  static Box<MeshMessage> get pendingBox => Hive.box<MeshMessage>(pendingRelayBoxName);

  static Future<void> markProcessed(String messageId) async {
    await processedBox.put(messageId, true);
  }

  static bool isProcessed(String messageId) {
    return processedBox.containsKey(messageId);
  }

  static Future<void> queuePendingRelay(MeshMessage msg) async {
    await pendingBox.put(msg.id, msg);
  }

  static List<MeshMessage> getPendingRelays() {
    return pendingBox.values.toList();
  }

  static Future<void> removePendingRelay(String messageId) async {
    await pendingBox.delete(messageId);
  }

  static Box get settingsBox => Hive.box(settingsBoxName);

  static bool get isOnboardingCompleted => settingsBox.get('onboarding_completed', defaultValue: false);

  static Future<void> setOnboardingCompleted(bool value) async {
    await settingsBox.put('onboarding_completed', value);
  }
}
