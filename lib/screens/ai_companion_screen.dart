import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import '../theme/app_theme.dart';
import '../services/safety_service.dart';
import '../services/api_config.dart';

class AICompanionScreen extends StatefulWidget {
  const AICompanionScreen({super.key});

  @override
  State<AICompanionScreen> createState() => _AICompanionScreenState();
}

class _AICompanionScreenState extends State<AICompanionScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _waveController;
  late AnimationController _glowController;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isAITyping = false;
  
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));
  
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: "Hi! I'm your NIVARAN AI companion. I'll stay connected with you during your travel. How are you feeling?",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  // Conversation history for context
  final List<Map<String, String>> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_waveController.isAnimating) _waveController.repeat();
      if (!_glowController.isAnimating) _glowController.repeat(reverse: true);
    } else {
      _waveController.stop();
      _glowController.stop();
    }
  }

  String _buildSystemPrompt(SafetyService service) {
    final hour = DateTime.now().hour;
    String timeContext = '';
    if (hour >= 22 || hour <= 5) {
      timeContext = 'It is late night, which is a high-risk period.';
    } else if (hour >= 19) {
      timeContext = 'It is evening time, stay cautious.';
    } else {
      timeContext = 'It is daytime.';
    }

    final riskLevel = service.currentRiskAssessment?.riskLevel ?? 'Unknown';
    final riskScore = service.riskScore;
    final isSOSActive = service.isSOSActive;
    final isTripActive = service.isTripActive;

    return '''
You are NIVARAN AI Guard — a personal safety companion for women in India. You are embedded in a mobile safety app.

CURRENT USER CONTEXT:
- Risk Score: $riskScore/100 (Risk Level: $riskLevel)
- $timeContext
- SOS Active: ${isSOSActive ? 'YES — user may be in immediate danger' : 'No'}
- Trip Active: ${isTripActive ? 'YES — user is currently on a monitored trip' : 'No'}
- Location: Lat ${service.currentLat.toStringAsFixed(4)}, Lng ${service.currentLng.toStringAsFixed(4)}

YOUR BEHAVIOR:
1. Be warm, empathetic, and reassuring but never dismissive of fears.
2. If the user expresses fear or danger, take it seriously. Suggest triggering SOS, sharing location with contacts, or moving to a safe place.
3. Provide practical safety tips relevant to their current context (time, risk level, location).
4. If asked about legal help, mention the Auto FIR feature and Law Counseling available in the app.
5. Keep responses concise (2-4 sentences max) and conversational.
6. If risk is high or SOS is active, be proactive and urgent in your guidance.
7. You can reference app features: SOS button, Fake Call, Trip Monitor, Evidence Vault, Mesh Network.
8. Never reveal you are an AI model or discuss your training. You are "NIVARAN AI Guard".
9. Use relevant emojis sparingly to keep the tone friendly.
''';
  }

  Future<String> _getAIResponse(String userMessage, SafetyService service) async {
    try {
      // Add user message to history
      _conversationHistory.add({'role': 'user', 'content': userMessage});
      
      // Keep only last 10 exchanges for context window
      if (_conversationHistory.length > 20) {
        _conversationHistory.removeRange(0, _conversationHistory.length - 20);
      }

      final messages = [
        {'role': 'system', 'content': _buildSystemPrompt(service)},
        ..._conversationHistory,
      ];

      final response = await _dio.post(
        ApiConfig.aiUrl,
        data: {
          'model': 'openai/gpt-4o-mini', 
          'messages': messages,
          'max_tokens': 300,
          'temperature': 0.8,
        },
      );

      if (response.statusCode == 200) {
        final choices = response.data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final aiText = choices[0]['message']['content'] as String? ?? '';
          if (aiText.isNotEmpty) {
            _conversationHistory.add({'role': 'assistant', 'content': aiText});
            return aiText;
          }
        }
      }
      return "Sorry, I received an invalid response from the safety server.";
    } on DioException catch (e) {
      debugPrint('AI Companion Dio Error: ${e.response?.data ?? e.message}');
      String errMsg = 'API Error';
      if (e.response != null && e.response!.data is Map) {
        errMsg = e.response!.data['error']?['message'] ?? e.response!.data.toString();
      } else {
        errMsg = e.message ?? 'Unknown network error';
      }
      return "⚠️ System Alert: I couldn't process your request right now due to a network or key issue. ($errMsg)";
    } catch (e) {
      debugPrint('AI Companion error: $e');
      return "⚠️ System Alert: Internal processing error ($e). Please use standard emergency options if needed.";
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    
    final service = Provider.of<SafetyService>(context, listen: false);
    
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isAITyping = true;
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

    // Get real AI response
    _getAIResponse(text, service).then((response) {
      if (mounted) {
        setState(() {
          _isAITyping = false;
          _messages.add(_ChatMessage(
            text: response,
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
    WidgetsBinding.instance.removeObserver(this);
    _waveController.dispose();
    _glowController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _dio.close();
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
              itemCount: _messages.length + (_isAITyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isAITyping) {
                  return _buildTypingIndicator();
                }
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

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final progress = (_waveController.value * 3 - index).clamp(0.0, 1.0);
        final bounce = math.sin(progress * math.pi);
        return Transform.translate(
          offset: Offset(0, -bounce * 4),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryPurple.withValues(alpha: 0.4 + bounce * 0.6),
            ),
          ),
        );
      },
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
