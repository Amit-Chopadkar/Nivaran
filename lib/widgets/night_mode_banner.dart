import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/night_mode_provider.dart';
import '../theme/app_theme.dart';

class NightModeBanner extends StatefulWidget {
  const NightModeBanner({super.key});

  @override
  State<NightModeBanner> createState() => _NightModeBannerState();
}

class _NightModeBannerState extends State<NightModeBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _floatAnim;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NightModeProvider>(
      builder: (context, nightMode, _) {
        if (!nightMode.state.isEffectivelyActive) return const SizedBox.shrink();

        final checkInCountdown = nightMode.state.checkInEnabled &&
                nightMode.state.nextCheckInDue != null
            ? nightMode.state.nextCheckInDue!.difference(DateTime.now())
            : null;

        return GestureDetector(
          // Swipe right to collapse
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! > 200 && !_isCollapsed) {
                setState(() => _isCollapsed = true);
              } else if (details.primaryVelocity! < -200 && _isCollapsed) {
                setState(() => _isCollapsed = false);
              }
            }
          },
          child: AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.centerLeft,
            child: _isCollapsed
                ? // Collapsed: small floating moon circle
                GestureDetector(
                    onTap: () => setState(() => _isCollapsed = false),
                    child: Container(
                      margin: const EdgeInsets.only(left: 300, top: 10, bottom: 10),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E1B4B),
                        border: Border.all(
                            color: AppTheme.accentBlue.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: AnimatedBuilder(
                        animation: _floatAnim,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnim.value * 0.5),
                            child: const Icon(Icons.nightlight_round,
                                color: AppTheme.accentBlue, size: 22),
                          );
                        },
                      ),
                    ),
                  )
                : // Expanded: full banner
                GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/night-mode'),
                    child: Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B4B),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: AppTheme.accentBlue.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.2),
                            blurRadius: 15,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _floatAnim,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _floatAnim.value),
                                child: const Icon(Icons.nightlight_round,
                                    color: AppTheme.accentBlue, size: 20),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Night Mode Active',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Risk Multiplier × 2.2 applied to area',
                                  style: TextStyle(
                                    color: AppTheme.accentBlue
                                        .withValues(alpha: 0.8),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (checkInCountdown != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Next Check-in: ${checkInCountdown.inMinutes.abs()}:${(checkInCountdown.inSeconds.abs() % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: nightMode.state.checkInOverdue
                                      ? AppTheme.criticalRed
                                      : Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          const Icon(Icons.arrow_forward_ios,
                              color: Colors.white38, size: 12),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
