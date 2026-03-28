import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/mesh_message.dart';
import '../services/mesh_service.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../services/mesh_call_service.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import 'mesh_call_screen.dart';

class MeshChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;

  const MeshChatScreen({super.key, required this.peerId, required this.peerName});

  @override
  State<MeshChatScreen> createState() => _MeshChatScreenState();
}

class _MeshChatScreenState extends State<MeshChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshService>();
    final messages = LocalStorageService.getMessagesFor(widget.peerId);
    // Check connected: widget.peerId is now userId; resolve to endpointId
    final peerEndpointId = mesh.userIdToEndpoint[widget.peerId];
    final isConnected = peerEndpointId != null && mesh.connectedPeers.containsKey(peerEndpointId);

    // If it's the broadcast screen, we just show all messages sent/received via broadcast
    final isGroup = widget.peerId == 'broadcast';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isGroup ? 'Admin Broadcast' : widget.peerName, style: const TextStyle(fontSize: 16)),
            Text(
              isGroup ? 'Private Secure Channel' : (isConnected ? 'Connected securely' : 'Offline/Unreachable'),
              style: TextStyle(
                fontSize: 12,
                color: isConnected || isGroup ? AppTheme.safeGreen : AppTheme.textMuted,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.darkBg,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!isGroup && peerEndpointId != null)
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: () {
                // Pass the endpointId to the call service (needed for Nearby payload routing)
                context.read<MeshCallService>().startCall(peerEndpointId);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MeshCallScreen()));
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isGroup ? _buildSupabaseMessages(mesh) : _buildMeshMessages(mesh, messages),
          ),
          _buildMessageInput(mesh),
        ],
      ),
    );
  }

  Widget _buildMeshMessages(MeshService mesh, List<MeshMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return _buildMessageBubble(msg, mesh.userId, false);
      },
    );
  }

  Widget _buildSupabaseMessages(MeshService mesh) {
    final auth = context.read<AuthService>();
    final email = auth.currentUserEmail;
    
    if (email == null) return const Center(child: Text('Please login to view messages', style: TextStyle(color: Colors.white)));

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.getAdminMessages(email),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));
        }
        
        final data = snapshot.data ?? [];
        final messages = data.map((m) => MeshMessage(
          id: m['id'].toString(),
          senderId: m['is_admin'] ? 'admin' : mesh.userId,
          receiverId: 'broadcast',
          payload: m['message'] ?? '',
          timestamp: DateTime.parse(m['created_at']),
          type: 'chat',
        )).toList();

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            return _buildMessageBubble(msg, mesh.userId, true);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(MeshMessage msg, String myId, bool isGroup) {
    final isMe = msg.senderId == myId;
    final isAdmin = msg.senderId == 'admin';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryPurple : (isAdmin ? AppTheme.accentBlue.withValues(alpha: 0.3) : AppTheme.darkCard),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isAdmin ? Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.5)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAdmin)
              const Text(
                'OFFICIAL ADMIN',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentBlue, letterSpacing: 1),
              ),
            Text(
              msg.payload,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5)),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isDelivered ? Icons.done_all : Icons.done,
                    size: 12,
                    color: msg.isDelivered ? AppTheme.accentBlue : Colors.white.withValues(alpha: 0.5),
                  ),
                  if (msg.isDelivered)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        'ADM',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.accentBlue),
                      ),
                    ),
                ],
                if (!isMe && msg.hopCount > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Relayed: ${msg.hopCount} hops',
                    style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4), fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(MeshService mesh) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.peerId == 'broadcast' ? 'Type a secure message...' : 'Type an offline message...',
                hintStyle: TextStyle(color: AppTheme.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.darkCard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.primaryPurple,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () async {
                final text = _messageController.text.trim();
                if (text.isEmpty) return;

                final msg = MeshMessage(
                  id: const Uuid().v4(),
                  senderId: mesh.userId,
                  receiverId: widget.peerId,
                  payload: text,
                  timestamp: DateTime.now(),
                  type: 'chat',
                );

                _messageController.clear();

                if (widget.peerId == 'broadcast') {
                  final auth = context.read<AuthService>();
                  if (auth.currentUserEmail != null) {
                    await SupabaseService.sendAdminMessage(
                      userEmail: auth.currentUserEmail!,
                      message: text,
                      isAdmin: false,
                    );
                  }
                } else {
                  await mesh.sendDirectMessage(widget.peerId, msg);
                }

                _scrollToBottom();
              },
            ),
          ),
        ],
      ),
    );
  }
}
