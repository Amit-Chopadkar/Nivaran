import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_contact_card.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> with TickerProviderStateMixin {
  bool _isRinging = false;
  bool _isOnCall = false;
  int _callDuration = 0;
  Timer? _callTimer;
  Timer? _ringTimer;
  String _selectedCaller = 'Mom';
  int _delay = 5;
  
  late AnimationController _ringAnimController;
  late Animation<double> _ringAnim;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Map<String, String>> _callerProfiles = [
    {'name': 'Mom', 'number': '+91 98765 43210'},
    {'name': 'Dad', 'number': '+91 98765 43211'},
    {'name': 'Boss', 'number': '+91 98765 43212'},
    {'name': 'Best Friend', 'number': '+91 98765 43213'},
    {'name': 'Boyfriend', 'number': '+91 98765 43214'},
  ];

  @override
  void initState() {
    super.initState();
    _ringAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _ringAnim = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _ringAnimController, curve: Curves.easeInOut),
    );
  }

  void _scheduleFakeCall() {
    HapticFeedback.mediumImpact();
    _ringTimer = Timer(Duration(seconds: _delay), () {
      if (mounted) {
        setState(() => _isRinging = true);
        _ringAnimController.repeat(reverse: true);
        _playRingtone();
        HapticFeedback.heavyImpact();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fake call from $_selectedCaller in $_delay seconds'),
        backgroundColor: AppTheme.accentBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _answerCall() {
    _ringAnimController.stop();
    setState(() {
      _isRinging = false;
      _isOnCall = true;
    });
    _stopRingtone();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _callDuration++);
      }
    });
  }

  void _endCall() {
    _callTimer?.cancel();
    _ringAnimController.stop();
    setState(() {
      _isOnCall = false;
      _isRinging = false;
      _callDuration = 0;
    });
    _stopRingtone();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _ringTimer?.cancel();
    _ringAnimController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
    } catch (e) {
      debugPrint('Error playing ringtone: $e');
    }
  }

  Future<void> _stopRingtone() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping ringtone: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRinging) return _buildRingingScreen();
    if (_isOnCall) return _buildOnCallScreen();
    return _buildSetupScreen();
  }

  Widget _buildSetupScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fake Call'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accentBlue.withValues(alpha: 0.15), AppTheme.darkCard],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.phone_callback_rounded, color: AppTheme.accentBlue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Escape Mode',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Simulate an incoming call to help you leave uncomfortable situations safely.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Caller selection
            Text('Choose Caller', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            ...(_callerProfiles.map((profile) {
              final isSelected = profile['name'] == _selectedCaller;
              
              // Map profiles to images if they match common emergency types
              String? avatarPath;
              IconData? fallbackIcon;
              Color iconBgColor = AppTheme.primaryPurple.withValues(alpha: 0.1);

              if (profile['name'] == 'Police') {
                avatarPath = 'assets/images/officer_man.png';
              } else if (profile['name'] == 'Mom' || profile['name'] == 'Dad') {
                fallbackIcon = profile['name'] == 'Mom' ? Icons.woman_rounded : Icons.man_rounded;
                iconBgColor = AppTheme.primaryPink.withValues(alpha: 0.2);
              } else {
                fallbackIcon = Icons.person_rounded;
              }

              return PremiumContactCard(
                name: profile['name']!,
                subtitle: profile['number']!,
                isSelected: isSelected,
                avatarPath: avatarPath,
                fallbackIcon: fallbackIcon,
                iconBgColor: iconBgColor,
                onTap: () => setState(() => _selectedCaller = profile['name']!),
                onCallTap: () {
                  setState(() => _selectedCaller = profile['name']!);
                  _scheduleFakeCall();
                },
              );
            })),
            const SizedBox(height: 24),

            // Delay setting
            Text('Call Delay', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [3, 5, 10, 15, 30].map((seconds) {
                final isSelected = seconds == _delay;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _delay = seconds),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accentBlue.withValues(alpha: 0.2) : AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.accentBlue : Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${seconds}s',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Start button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _scheduleFakeCall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppTheme.accentBlue.withValues(alpha: 0.4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Schedule Fake Call',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRingingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1628), Color(0xFF0F0F1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _ringAnimController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _ringAnim.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentBlue.withValues(alpha: 0.2),
                      ),
                      child: Center(
                        child: Text(
                          _selectedCaller[0],
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppTheme.accentBlue),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                _selectedCaller,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Incoming Call...',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CallButton(
                      icon: Icons.call_end_rounded,
                      color: AppTheme.dangerRed,
                      label: 'Decline',
                      onTap: _endCall,
                    ),
                    _CallButton(
                      icon: Icons.call_rounded,
                      color: AppTheme.safeGreen,
                      label: 'Answer',
                      onTap: _answerCall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnCallScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1628), Color(0xFF0F0F1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.safeGreen.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Text(
                    _selectedCaller[0],
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppTheme.safeGreen),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _selectedCaller,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDuration(_callDuration),
                style: const TextStyle(fontSize: 18, color: AppTheme.safeGreen),
              ),
              const Spacer(flex: 2),
              // Call actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallAction(icon: Icons.mic_off_rounded, label: 'Mute'),
                  _CallAction(icon: Icons.volume_up_rounded, label: 'Speaker'),
                  _CallAction(icon: Icons.dialpad_rounded, label: 'Keypad'),
                ],
              ),
              const Spacer(),
              _CallButton(
                icon: Icons.call_end_rounded,
                color: AppTheme.dangerRed,
                label: 'End Call',
                onTap: _endCall,
                size: 70,
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final double size;

  const _CallButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.4),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _CallAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CallAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          child: Icon(icon, color: AppTheme.textPrimary, size: 22),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }
}
