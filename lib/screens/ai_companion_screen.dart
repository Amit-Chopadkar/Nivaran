import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../services/safety_service.dart';

class AICompanionScreen extends StatefulWidget {
  const AICompanionScreen({super.key});

  @override
  State<AICompanionScreen> createState() => _AICompanionScreenState();
}

class _AICompanionScreenState extends State<AICompanionScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _glowController;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: "Hi! I'm your SafeHer AI companion. I'll stay connected with you during your travel. How are you feeling?",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  final List<String> _aiResponses = [
    "I'm monitoring your surroundings. Everything looks safe right now. Your risk score is low. 🛡️",
    "I notice you're in a well-lit area. That's great! I'll keep tracking your location.",
    "Stay alert! I've detected slightly higher activity in your area. Would you like me to alert your contacts?",
    "Your trusted contacts can see your location. Would you like me to send them a check-in message?",
    "I'm here with you. Remember, you can say 'help me' at any time to trigger an emergency alert.",
    "Based on current data, the safest route is via the main road. Would you like navigation directions?",
    "I've detected that you've been stationary for a while. Everything okay? Tap to confirm you're safe.",
    "Night mode activated. I've enhanced monitoring and your emergency contacts have been notified of your route.",
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
    });
    _messageController.clear();
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        final random = math.Random();
        setState(() {
          _messages.add(_ChatMessage(
            text: _aiResponses[random.nextInt(_aiResponses.length)],
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _glowController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SafetyService>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPurple.withValues(alpha: 0.3 + _glowController.value * 0.2),
                        blurRadius: 10 + _glowController.value * 5,
                        spreadRadius: _glowController.value * 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
                );
              },
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Companion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('Always watching over you', style: TextStyle(fontSize: 11, color: AppTheme.safeGreen)),
              ],
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: service.isAICompanionActive ? AppTheme.safeGreen.withValues(alpha: 0.15) : AppTheme.textMuted.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: service.isAICompanionActive ? AppTheme.safeGreen : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  service.isAICompanionActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    color: service.isAICompanionActive ? AppTheme.safeGreen : AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryPurple.withValues(alpha: 0.1), AppTheme.darkCard],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                _CompanionStat(icon: Icons.shield_rounded, label: 'Risk: ${service.riskScore}%', color: service.riskScore <= 30 ? AppTheme.safeGreen : AppTheme.cautionYellow),
                Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.05)),
                _CompanionStat(icon: Icons.location_on_rounded, label: 'Tracking', color: AppTheme.accentBlue),
                Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.05)),
                _CompanionStat(icon: Icons.mic_rounded, label: 'Listening', color: AppTheme.accentViolet),
              ],
            ),
          ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Quick replies
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _QuickReply(text: "I'm safe", onTap: () => _sendMessage("I'm safe")),
                _QuickReply(text: 'Check area', onTap: () => _sendMessage('Can you check if this area is safe?')),
                _QuickReply(text: 'Share location', onTap: () => _sendMessage('Share my location with contacts')),
                _QuickReply(text: 'Nearest safe place', onTap: () => _sendMessage('Where is the nearest safe place?')),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.mic_rounded, color: AppTheme.primaryPurple),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Chat with AI companion...',
                          hintStyle: TextStyle(color: AppTheme.textMuted),
                          border: InputBorder.none,
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_messageController.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AppTheme.primaryPurple.withValues(alpha: 0.2)
              : AppTheme.darkCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: Border.all(
            color: msg.isUser
                ? AppTheme.primaryPurple.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                color: msg.isUser ? AppTheme.textPrimary : AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class _CompanionStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CompanionStat({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _QuickReply extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _QuickReply({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.2)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppTheme.primaryPurple, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
