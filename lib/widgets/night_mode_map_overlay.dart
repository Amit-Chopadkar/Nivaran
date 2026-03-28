import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/night_mode_provider.dart';
import '../theme/app_theme.dart';

class NightModeMapOverlay extends StatelessWidget {
  const NightModeMapOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NightModeProvider>(
      builder: (context, nightMode, _) {
        if (!nightMode.state.showNightOverlay || !nightMode.state.isEffectivelyActive) {
          return const SizedBox.shrink();
        }

        return IgnorePointer(
          child: Stack(
            children: [
              // Vignette Effect
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black45,
                      Colors.black87,
                    ],
                    stops: [0.0, 0.7, 1.0],
                  ),
                ),
              ),

              // Danger Zone Clusters (Mocked Pulsing Effect)
              if (nightMode.state.nightRiskScore > 60)
                const _PulsingDangerZone(
                    offset: Offset(200, 300), // Mock position
                    label: 'DANGER ZONE',
                ),

            ],
          ),
        );
      },
    );
  }
}


class _PulsingDangerZone extends StatefulWidget {
  final Offset offset;
  final String label;

  const _PulsingDangerZone({required this.offset, required this.label});

  @override
  State<_PulsingDangerZone> createState() => _PulsingDangerZoneState();
}

class _PulsingDangerZoneState extends State<_PulsingDangerZone> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.offset.dx,
      top: widget.offset.dy,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer Pulsing Circle
              Container(
                width: 100 * (1 + _controller.value),
                height: 100 * (1 + _controller.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.criticalRed.withValues(alpha: 0.3 * (1 - _controller.value)),
                ),
              ),
              // Label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.criticalRed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
