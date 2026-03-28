import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/safety_service.dart';

import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/sos_background_service.dart';
import 'contacts_screen.dart';
import 'login_screen.dart';
import 'scanner_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SafetyService>();
    final user = context.watch<UserService>();
    final sosBridge = context.watch<SOSBackgroundServiceBridge>();

    void showBlockchainQR() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        builder: (context) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Blockchain ID',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                Text('Your cryptographically secure safety hash',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                      ),
                    ],
                    border:
                        Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  ),
                  child: QrImageView(
                    data: user.profile?.kycHash ?? 'No Hash Available',
                    version: QrVersions.auto,
                    size: 160.0,
                    foregroundColor: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.profile?.kycHash != null
                        ? 'Hash ID: ${user.profile!.kycHash!.substring(0, 8)}...${user.profile!.kycHash!.substring(user.profile!.kycHash!.length - 8)}'
                        : 'Hash ID: NOT VERIFIED',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Verified Proof',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Premium Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border:
                      Border.all(color: Colors.black.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryPurple,
                                AppTheme.primaryPink
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryPurple
                                    .withValues(alpha: 0.2),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              (user.profile?.name ?? 'S')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.safeGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.verified_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.profile?.name ?? 'Guest User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.profile?.email ?? 'No email',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ProfileStat(
                            value: '${service.emergencyContacts.length}',
                            label: 'Contacts'),
                        _divider(),
                        const _ProfileStat(value: '12', label: 'Trips'),
                        _divider(),
                        const _ProfileStat(value: '3', label: 'Reports'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Glossy Blockchain ID Card
              _buildGlossyBlockchainCard(context, showBlockchainQR),

              const SizedBox(height: 20),

              // Settings sections
              _buildSettingsSection('Safety Settings', [
                _SettingItem(
                  icon: Icons.shield_moon_rounded,
                  title: 'Always-On SOS Guardian',
                  subtitle: sosBridge.serviceRunning
                      ? 'Active — press power 2× for SOS'
                      : 'Tap to enable background monitoring',
                  color: sosBridge.serviceRunning ? AppTheme.safeGreen : AppTheme.textMuted,
                  onTap: () {},
                  trailing: Switch(
                    value: sosBridge.serviceRunning,
                    onChanged: (v) async {
                      if (v) {
                        await sosBridge.startService();
                        if (!context.mounted) return;
                        final safetyService = context.read<SafetyService>();
                        sosBridge.onSOSTriggered = () => safetyService.activateSOS();
                      } else {
                        await sosBridge.stopService();
                      }
                    },
                  activeThumbColor: AppTheme.safeGreen,
                  activeTrackColor: AppTheme.safeGreen.withValues(alpha: 0.2),
                ),
              ),
                _SettingItem(
                  icon: Icons.contacts_rounded,
                  title: 'Emergency Contacts',
                  subtitle: '${service.emergencyContacts.length} contacts configured',
                  color: AppTheme.primaryPink,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen())),
                ),
                _SettingItem(
                  icon: Icons.notifications_active_rounded,
                  title: 'Alert Preferences',
                  subtitle: 'Configure SOS triggers',
                  color: AppTheme.dangerRed,
                  onTap: () {},
                ),
                _SettingItem(
                  icon: Icons.gps_fixed_rounded,
                  title: 'Location Sharing',
                  subtitle: 'Manage live tracking',
                  color: AppTheme.safeGreen,
                  onTap: () {},
                ),
                _SettingItem(
                  icon: Icons.timer_rounded,
                  title: 'Auto Check-In',
                  subtitle: 'Set safety timers',
                  color: AppTheme.cautionYellow,
                  onTap: () {},
                ),
                _SettingItem(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Scan & Verify',
                  subtitle: 'Verify another user on the blockchain',
                  color: AppTheme.accentCyan,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                    );
                  },
                ),
                _SettingItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacy Center',
                  subtitle: 'Control your safety data sharing',
                  color: AppTheme.accentCyan,
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 20),

              _buildSettingsSection('AI & Privacy', [
                _SettingItem(
                  icon: Icons.psychology_rounded,
                  title: 'AI Detection Sensitivity',
                  subtitle: 'Anomaly detection level',
                  color: AppTheme.accentViolet,
                  onTap: () {},
                ),
                _SettingItem(
                  icon: Icons.mic_rounded,
                  title: 'Voice Triggers',
                  subtitle: 'Custom distress phrases',
                  color: AppTheme.accentBlue,
                  onTap: () {},
                ),
                _SettingItem(
                  icon: Icons.lock_rounded,
                  title: 'Privacy Controls',
                  subtitle: 'Data & encryption settings',
                  color: AppTheme.primaryPurple,
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 20),

              _buildSettingsSection('App Settings', [
                _SettingItem(
                  icon: Icons.dark_mode_rounded,
                  title: 'Night Safety Mode',
                  subtitle: 'Enhanced features after dark',
                  color: AppTheme.accentCyan,
                  onTap: () {
                    final service = context.read<ThemeService>();
                    service.toggleTheme(!service.isDarkMode);
                  },
                  trailing: Switch(
                    value: context.watch<ThemeService>().isDarkMode,
                    onChanged: (v) {
                      context.read<ThemeService>().toggleTheme(v);
                    },
                    activeThumbColor: AppTheme.accentCyan,
                    activeTrackColor: AppTheme.accentCyan.withValues(alpha: 0.2),
                  ),
                ),
                _SettingItem(
                  icon: Icons.battery_saver_rounded,
                  title: 'Battery Saver',
                  subtitle: 'Optimize for low battery',
                  color: AppTheme.safeGreen,
                  onTap: () {},
                ),
                _SettingItem(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  subtitle: 'Safely sign out of your profile',
                  color: AppTheme.dangerRed,
                  onTap: () async {
                    await context.read<AuthService>().logout();
                    if (!context.mounted) return;
                    context.read<UserService>().logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ]),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlossyBlockchainCard(BuildContext context, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative glass shine
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Blockchain ID',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verified Identity Hash',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'VIEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 28, color: const Color(0xFFF1F5F9));

  Widget _buildSettingsSection(String title, List<_SettingItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final item = entry.value;
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  ListTile(
                    onTap: item.onTap,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, color: item.color, size: 22),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12, 
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: item.trailing ??
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFFCBD5E1), size: 20),
                  ),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.only(left: 72),
                      child: Divider(
                        height: 1,
                        color: Color(0xFFF1F5F9),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.trailing,
  });
}
