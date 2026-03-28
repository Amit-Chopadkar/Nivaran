import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CheckInTimerWidget extends StatefulWidget {
  final DateTime? nextCheckInDue;
  final bool isOverdue;
  final VoidCallback onCheckIn;
  final int intervalMinutes;

  const CheckInTimerWidget({
    super.key,
    required this.nextCheckInDue,
    required this.isOverdue,
    required this.onCheckIn,
    required this.intervalMinutes,
  });

  @override
  State<CheckInTimerWidget> createState() => _CheckInTimerWidgetState();
}

class _CheckInTimerWidgetState extends State<CheckInTimerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(CheckInTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOverdue && !oldWidget.isOverdue) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isOverdue && oldWidget.isOverdue) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String twoDigitMinutes = twoDigits(duration.inMinutes.abs().remainder(60));
    final String twoDigitSeconds = twoDigits(duration.inSeconds.abs().remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remaining = widget.nextCheckInDue?.difference(now) ?? Duration.zero;
    final totalSeconds = widget.intervalMinutes * 60;
    final remainingSeconds = remaining.inSeconds.clamp(0, totalSeconds);
    final percent = (remainingSeconds / totalSeconds).clamp(0.0, 1.0);

    Color timerColor = AppTheme.primaryPurple;
    if (widget.isOverdue) {
      timerColor = AppTheme.criticalRed;
    } else if (percent < 0.2) {
      timerColor = AppTheme.dangerRed;
    } else if (percent < 0.5) {
      timerColor = AppTheme.cautionYellow;
    }

    return ScaleTransition(
      scale: widget.isOverdue ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: TimerPainter(
                      percent: percent,
                      color: timerColor,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.isOverdue ? "OVERDUE" : "NEXT DUE",
                        style: TextStyle(
                          color: timerColor.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(remaining),
                        style: TextStyle(
                          color: timerColor,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: widget.onCheckIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isOverdue ? AppTheme.criticalRed : AppTheme.safeGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
            ),
            child: Text(
              widget.isOverdue ? "I'M SAFE!" : "CHECK IN NOW",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimerPainter extends CustomPainter {
  final double percent;
  final Color color;

  TimerPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    const strokeWidth = 12.0;

    // Background track
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth);
    canvas.drawArc(
      rect, 
      -pi / 2, 
      2 * pi * percent, 
      false, 
      progressPaint
    );
    
    // Gradient Glow (Subtle)
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(
      rect, 
      -pi / 2, 
      2 * pi * percent, 
      false, 
      glowPaint
    );
  }

  @override
  bool shouldRepaint(covariant TimerPainter oldDelegate) {
    return oldDelegate.percent != percent || oldDelegate.color != color;
  }
}
