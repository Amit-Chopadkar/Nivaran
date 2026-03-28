import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/night_mode_provider.dart';
import '../services/night_mode_service.dart';
import '../theme/app_theme.dart';
import '../widgets/buddy_track_widget.dart';
import '../widgets/check_in_timer_widget.dart';

class NightModeScreen extends StatelessWidget {
  const NightModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NightModeProvider>(
      builder: (context, provider, _) {
        final state = provider.state;
        final nightService = NightModeService();

        return Scaffold(
          backgroundColor: const Color(0xFF060613), // Deep dark background
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Night Mode Control'),
            actions: [
              IconButton(
                icon: Icon(
                  state.isManuallyEnabled ? Icons.toggle_on : Icons.toggle_off,
                  color: state.isManuallyEnabled ? AppTheme.accentBlue : Colors.white24,
                  size: 32,
                ),
                onPressed: provider.toggleManualMode,
              ),
              const SizedBox(width: 10),
            ],
          ),
          body: Stack(
            children: [
              // Stars Background (Custom Painter)
              Positioned.fill(
                child: CustomPaint(
                  painter: StarsPainter(),
                ),
              ),
              
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // SECTION 1: MODE STATUS CARD
                    _StatusCard(state: state, provider: provider, nightService: nightService),
                    
                    const SizedBox(height: 25),
                    
                    // SECTION 2: BUDDY TRACK
                    _SectionHeader(title: 'Buddy Track', icon: Icons.people_outline),
                    const SizedBox(height: 15),
                    BuddyTrackWidget(
                        isTracking: state.buddyTrackEnabled,
                        contactName: state.buddyContactName,
                        contactPhone: state.buddyContactPhone,
                        onStart: () => provider.enableBuddyTrack('Rahul Sharma', '+91 9876543210'),
                        onStop: provider.disableBuddyTrack,
                    ),
                    
                    const SizedBox(height: 35),
                    
                    // SECTION 3: CHECK-IN SYSTEM
                    _SectionHeader(title: 'Check-in System', icon: Icons.timer_outlined),
                    const SizedBox(height: 15),
                    _CheckInCard(state: state, provider: provider),
                    
                    const SizedBox(height: 35),
                    
                    // SECTION 4: NIGHT ROUTE PREFERENCES
                    _SectionHeader(title: 'Route Preferences', icon: Icons.alt_route_outlined),
                    const SizedBox(height: 15),
                    _PreferencesCard(),
                    
                    const SizedBox(height: 35),
                    
                    // SECTION 5: NIGHT ALERTS FEED
                    _SectionHeader(title: 'Night Alerts — LATEST', icon: Icons.notification_important_outlined),
                    const SizedBox(height: 15),
                    _AlertsCard(alerts: state.nightAlerts),
                    
                    const SizedBox(height: 100), // Bottom padding for content
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  final NightModeState state;
  final NightModeProvider provider;
  final NightModeService nightService;

  const _StatusCard({required this.state, required this.provider, required this.nightService});

  @override
  Widget build(BuildContext context) {
    final statusColor = state.isEffectivelyActive ? AppTheme.accentBlue : Colors.white24;
    final riskVisual = nightService.getNightRiskVisual(state.nightRiskScore);

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: [
          if (state.isEffectivelyActive)
            BoxShadow(
              color: AppTheme.accentBlue.withValues(alpha: 0.1),
              blurRadius: 30,
              spreadRadius: -10,
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.isEffectivelyActive ? 'NIGHT MODE ACTIVE' : 'NIGHT MODE INACTIVE',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    state.isActive ? 'Standard Hours (8 PM - 6 AM)' : 'Override Hours',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
              _MoonIcon(isActive: state.isEffectivelyActive),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn(
                  label: 'Risk Score',
                  value: state.nightRiskScore.round().toString(),
                  color: riskVisual['color'],
                  icon: riskVisual['icon'],
              ),
              _StatColumn(
                  label: state.isActive ? 'Ends in' : 'Starts in',
                  value: '${state.minutesUntilModeChange ~/ 60}h ${state.minutesUntilModeChange % 60}m',
                  color: Colors.white,
                  icon: Icons.access_time,
              ),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                 const Icon(Icons.lightbulb_outline, color: AppTheme.cautionYellow, size: 20),
                 const SizedBox(width: 15),
                 Expanded(
                   child: Text(
                     nightService.getNightSafetyTip(),
                     style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                   ),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatColumn({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentBlue, size: 20),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _CheckInCard extends StatelessWidget {
  final NightModeState state;
  final NightModeProvider provider;

  const _CheckInCard({required this.state, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (state.checkInEnabled) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: AppTheme.glassDecoration(),
        child: Center(
          child: CheckInTimerWidget(
              nextCheckInDue: state.nextCheckInDue,
              isOverdue: state.checkInOverdue,
              onCheckIn: provider.performCheckIn,
              intervalMinutes: state.checkInIntervalMinutes,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassDecoration(),
        child: Column(
          children: [
            const Text(
              'Set a recurring check-in. If you miss one, your emergency contacts are alerted.',
              style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _IntervalChip(label: '5m', isSelected: false),
                _IntervalChip(label: '10m', isSelected: false),
                _IntervalChip(label: '15m', isSelected: true),
                _IntervalChip(label: '30m', isSelected: false),
              ],
            ),
            const SizedBox(height: 25),
            SwitchListTile(
              value: true,
              onChanged: (_) {},
              title: const Text('Auto-SOS if missed', style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: const Text('Notify services automatically', style: TextStyle(color: Colors.white38, fontSize: 11)),
              activeThumbColor: AppTheme.accentBlue,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => provider.startCheckIn(intervalMinutes: 15, autoSOS: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Start Check-in', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }
  }
}

class _IntervalChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _IntervalChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.accentBlue : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppTheme.accentBlue : Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: AppTheme.glassDecoration(),
      child: Column(
        children: [
          _PreferenceTile(title: 'Prefer lit streets', value: true),
          _PreferenceTile(title: 'Avoid isolated paths', value: true),
          _PreferenceTile(title: 'Main roads only', value: false),
          _PreferenceTile(title: 'Populated zones priority', value: true),
          const Divider(color: Colors.white10, height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Max Extra Distance', style: TextStyle(color: Colors.white, fontSize: 13)),
                    Text('20%', style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                    value: 0.4, 
                    onChanged: (_) {},
                    activeColor: AppTheme.accentBlue,
                    inactiveColor: Colors.white.withValues(alpha: 0.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final String title;
  final bool value;

  const _PreferenceTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: (_) {},
      title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      activeThumbColor: AppTheme.accentBlue,
    );
  }
}

class _AlertsCard extends StatelessWidget {
  final List<String> alerts;

  const _AlertsCard({required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Container(
          padding: const EdgeInsets.all(30),
          width: double.infinity,
          decoration: AppTheme.glassDecoration(),
          child: Column(
            children: const [
              Icon(Icons.check_circle_outline, color: AppTheme.safeGreen, size: 30),
              SizedBox(height: 15),
              Text('No alerts in your area tonight', style: TextStyle(color: Colors.white38, fontSize: 13)),
            ],
          ),
      );
    }
    
    return Container(
      decoration: AppTheme.glassDecoration(),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: alerts.length,
        separatorBuilder: (context, _) => const Divider(color: Colors.white10, height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.info_outline, color: AppTheme.accentBlue, size: 20),
            title: Text(alerts[index], style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
            subtitle: Text('${index * 5 + 2}m ago', style: const TextStyle(color: Colors.white24, fontSize: 11)),
          );
        },
      ),
    );
  }
}

class _MoonIcon extends StatefulWidget {
  final bool isActive;
  const _MoonIcon({required this.isActive});

  @override
  State<_MoonIcon> createState() => _MoonIconState();
}

class _MoonIconState extends State<_MoonIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: widget.isActive ? _controller.value * 0.1 : 0,
          child: Icon(
            Icons.nightlight_round,
            color: widget.isActive ? AppTheme.accentBlue : Colors.white24,
            size: 40,
            shadows: [
              if (widget.isActive)
                const Shadow(color: AppTheme.accentBlue, blurRadius: 20),
            ],
          ),
        );
      },
    );
  }
}

class StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint()..color = Colors.white;
    for (int i = 0; i < 50; i++) {
      paint.color = Colors.white.withValues(alpha: random.nextDouble() * 0.4);
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
