import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/safety_service.dart';
import 'auto_fir_screen.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  bool _isCountingDown = false;
  int _countdown = 5;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startCountdown() {
    setState(() {
      _isCountingDown = true;
      _countdown = 5;
    });
    HapticFeedback.heavyImpact();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
      });
      HapticFeedback.mediumImpact();

      if (_countdown <= 0) {
        timer.cancel();
        _activateSOS();
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountingDown = false;
      _countdown = 5;
    });
  }

  void _activateSOS() {
    final service = context.read<SafetyService>();
    service.activateSOS();
    HapticFeedback.heavyImpact();
    setState(() {
      _isCountingDown = false;
    });
  }

  void _deactivateSOS() {
    final service = context.read<SafetyService>();
    service.deactivateSOS();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $launchUri');
      }
    } catch (e) {
      debugPrint('Launch Error: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SafetyService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (service.isSOSActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.dangerRed,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'SOS ACTIVE',
                        style: TextStyle(
                          color: AppTheme.dangerRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Main SOS Button Section
              _buildSOSSection(service, isDark),
              
              const SizedBox(height: 32),
              
              if (!service.isSOSActive) ...[
                // Emergency Contacts Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Emergency Contacts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => service.fetchContacts(),
                      icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 20),
                      tooltip: 'Sync Contacts',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (service.emergencyContacts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'No trusted contacts saved. Please add them in Settings.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  _buildEmergencyList(service, isDark),
                
                const SizedBox(height: 32),
                
                // Full Width Action Cards
                _buildActionCard(
                  title: 'Call Police',
                  subtitle: 'Direct call to 100',
                  icon: Icons.local_police_rounded,
                  iconColor: AppTheme.dangerRed,
                  isDark: isDark,
                  onTap: () => _makePhoneCall('100'),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  title: 'Report Incident',
                  subtitle: 'Navigates to report form',
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppTheme.cautionYellow,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AutoFirScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  title: 'Share My Location',
                  subtitle: 'Sends live location to saved contacts',
                  icon: Icons.location_on_rounded,
                  iconColor: AppTheme.accentBlue,
                  isDark: isDark,
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Sharing live location...'),
                        backgroundColor: AppTheme.safeGreen,
                        behavior: Brightness.dark == Theme.of(context).brightness ? null : SnackBarBehavior.floating,
                      ),
                    );
                    
                    final safetyService = context.read<SafetyService>();
                    // Automatically sends background SMS + opens native messenger with current location
                    await safetyService.sendNativeSMSAlerts();
                  },
                ),
              ],

              if (service.isSOSActive) ...[
                const SizedBox(height: 24),
                _buildActiveActions(service, isDark),
                const SizedBox(height: 24),
                if (service.sosLog.isNotEmpty)
                  _buildSOSLog(service, isDark),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSSection(SafetyService service, bool isDark) {
    if (service.isSOSActive) {
      return _buildActiveSOSView();
    }
    
    if (_isCountingDown) {
      return _buildCountdownView(isDark);
    }
    
    return _buildSOSButton();
  }

  Widget _buildSOSButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return GestureDetector(
          onLongPress: _startCountdown,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Long press to activate SOS'),
                backgroundColor: AppTheme.darkCard,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          child: Column(
            children: [
              Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.sosGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.dangerRed.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: AppTheme.dangerRed.withValues(alpha: 0.15),
                        blurRadius: 60,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emergency_rounded, color: Colors.white, size: 40),
                      SizedBox(height: 4),
                      Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'HOLD TO ACTIVATE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Will alert contacts & share location',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountdownView(bool isDark) {
    return Column(
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.dangerRed.withValues(alpha: 0.1),
            border: Border.all(color: AppTheme.dangerRed, width: 4),
          ),
          child: Center(
            child: Text(
              '$_countdown',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: AppTheme.dangerRed,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'ACTIVATING SOS...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.dangerRed,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _cancelCountdown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSOSView() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (i * 0.3 * _pulseAnim.value);
                  return Container(
                    width: 150 * scale,
                    height: 150 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.dangerRed.withValues(alpha: 0.3 - i * 0.08),
                        width: 2,
                      ),
                    ),
                  );
                },
              );
            }),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.sosGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.dangerRed.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Column(
               mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic_rounded, color: Colors.white, size: 36),
                  SizedBox(height: 4),
                  Text(
                    'RECORDING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'SOS IS ACTIVE',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.dangerRed,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Emergency contacts have been notified',
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyList(SafetyService service, bool isDark) {
    return Column(
      children: [
        // User's specifically added Trusted Contacts
        ...service.emergencyContacts.map((contact) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildListCard(
            number: contact.phone,
            subtitle: contact.name,
            icon: Icons.person_rounded,
            iconColor: AppTheme.accentBlue,
            isDark: isDark,
            onTap: () => _makePhoneCall(contact.phone),
          ),
        )),
        
        // National Emergency Numbers
        _buildListCard(
          number: '1091',
          subtitle: "Women's helpline number",
          icon: Icons.support_agent_rounded,
          iconColor: const Color(0xFF3B82F6),
          isDark: isDark,
          onTap: () => _makePhoneCall('1091'),
        ),
        const SizedBox(height: 12),
        _buildListCard(
          number: '100',
          subtitle: 'Police',
          icon: Icons.local_police_rounded,
          iconColor: const Color(0xFF1E293B),
          isDark: isDark,
          onTap: () => _makePhoneCall('100'),
        ),
        const SizedBox(height: 12),
        _buildListCard(
          number: '102',
          subtitle: 'Pregnancy medic',
          icon: Icons.medical_services_rounded,
          iconColor: const Color(0xFF10B981),
          isDark: isDark,
          onTap: () => _makePhoneCall('102'),
        ),
        const SizedBox(height: 12),
        _buildListCard(
          number: '108',
          subtitle: 'Ambulance',
          icon: Icons.airport_shuttle_rounded,
          iconColor: const Color(0xFFF59E0B),
          isDark: isDark,
          onTap: () => _makePhoneCall('108'),
        ),
        const SizedBox(height: 12),
        _buildListCard(
          number: '101',
          subtitle: 'Fire service',
          icon: Icons.local_fire_department_rounded,
          iconColor: const Color(0xFFEF4444),
          isDark: isDark,
          onTap: () => _makePhoneCall('101'),
        ),
      ],
    );
  }

  Widget _buildListCard({
    required String number,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final bgColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final shadowColor = isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFCE7F3), // Soft pink background
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 32, color: iconColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.call,
                    size: 20,
                    color: isDark ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final bgColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final shadowColor = isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveActions(SafetyService service, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionBtn(
                icon: Icons.location_on_rounded,
                label: 'Share Location',
                color: AppTheme.accentBlue,
                isDark: isDark,
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Updating live location...'),
                      backgroundColor: AppTheme.safeGreen,
                    ),
                  );
                  
                  final safetyService = context.read<SafetyService>();
                  // This now handles both background SMS and opening the native SMS app with all contacts
                  await safetyService.sendNativeSMSAlerts();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionBtn(
                icon: Icons.phone_rounded,
                label: 'Call 112',
                color: AppTheme.safeGreen,
                isDark: isDark,
                onTap: () => _makePhoneCall('112'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _deactivateSOS,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE2E8F0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: Text(
              'I\'m Safe - Deactivate SOS',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSLog(SafetyService service, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        itemCount: service.sosLog.take(6).length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == 0 ? AppTheme.safeGreen : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    service.sosLog[index],
                    style: TextStyle(
                      fontSize: 13,
                      color: index == 0 
                          ? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))
                          : Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: index == 0 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
