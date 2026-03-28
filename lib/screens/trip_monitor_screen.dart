import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../services/safety_service.dart';

class TripMonitorScreen extends StatefulWidget {
  final String? initialDestination;
  const TripMonitorScreen({super.key, this.initialDestination});

  @override
  State<TripMonitorScreen> createState() => _TripMonitorScreenState();
}

class _TripMonitorScreenState extends State<TripMonitorScreen> with TickerProviderStateMixin {
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();
  late AnimationController _pulseController;
  int _tripDuration = 0;
  Timer? _durationTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    Future.microtask(() {
      if (mounted) {
        final service = context.read<SafetyService>();
        _sourceController.text = '${service.currentLat.toStringAsFixed(5)}, ${service.currentLng.toStringAsFixed(5)}';
        
        if (widget.initialDestination != null && widget.initialDestination!.isNotEmpty) {
          _destinationController.text = widget.initialDestination!;
        }
      }
    });
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    _pulseController.dispose();
    _durationTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _tripDuration++;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SafetyService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Monitor'),
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
            // Header - Premium Light Glassmorphism
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.safeGreen.withValues(alpha: 0.4),
                      AppTheme.primaryPurple.withValues(alpha: 0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFFFFF),
                        const Color(0xFFF8FAFC),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.safeGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.safeGreen.withValues(alpha: 0.2), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.safeGreen.withValues(alpha: 0.05),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.navigation_rounded, color: AppTheme.safeGreen, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Auto Trip Monitor',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track your journey and alert trusted contacts if something goes wrong.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (!service.isTripActive) ...[
              // Destination input
              Text('Where are you going?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.15), width: 1.5),
                ),
                child: TextField(
                  controller: _destinationController,
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Enter destination...',
                    hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.6)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(18),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRed.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_rounded, color: AppTheme.dangerRed, size: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text('Starting Point', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.safeGreen.withValues(alpha: 0.15), width: 1.5),
                ),
                child: TextField(
                  controller: _sourceController,
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Current location (or type a place)',
                    hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.6)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(18),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.safeGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location_rounded, color: AppTheme.safeGreen, size: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Night mode feature banner - Light
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.safeGreen.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.safeGreen.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.safeGreen.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Text('🌙', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Night mode routing',
                            style: TextStyle(
                              color: Color(0xFF166534),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Time-aware risk scoring',
                            style: TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.verified_rounded, color: AppTheme.safeGreen, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Start button - Premium Gradient
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.safeGreen.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    if (_destinationController.text.isNotEmpty) {
                      setState(() => _isLoading = true);
                      final error = await service.startTrip(
                        _destinationController.text,
                        origin: _sourceController.text.isNotEmpty ? _sourceController.text : null,
                      );
                      if (!context.mounted) return;
                      setState(() => _isLoading = false);
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('⚠️ Route Error: $error'),
                            backgroundColor: AppTheme.dangerRed,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      } else {
                        _tripDuration = 0;
                        _startTimer();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        _isLoading ? 'Calculating Safest Route...' : 'Start Trip',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Active trip view
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Column(
                    children: [
                      if (service.dangerZoneAlert) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerRed,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.dangerRed.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('DANGER ZONE ALERT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1)),
                                    Text('Entering ${service.dangerZoneName}. Avoid if possible!', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (service.currentTrip?.isOffRoute ?? false) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerOrange,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.dangerOrange.withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.alt_route_rounded, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'OFF-ROUTE DETECTED: Please return to the suggested safe path.',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (service.currentInstruction != null) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: (service.currentInstruction!.isSafeZone ? AppTheme.safeGreen : AppTheme.dangerOrange).withValues(alpha: 0.15), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (service.currentInstruction!.isSafeZone ? AppTheme.safeGreen : AppTheme.dangerOrange).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(service.currentInstruction!.icon, color: service.currentInstruction!.isSafeZone ? AppTheme.safeGreen : AppTheme.dangerOrange, size: 32),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.currentInstruction!.instruction,
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Distance: ${service.currentInstruction!.distance}',
                                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Map Widget above Timer
                      if (service.currentTrip != null && service.currentTrip!.path.isNotEmpty)
                        Container(
                          height: 250,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: service.currentTrip!.path.first,
                              initialZoom: 14,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                                subdomains: const ['a', 'b', 'c', 'd'],
                              ),
                              if (service.currentTrip!.path.isNotEmpty)
                                PolylineLayer(
                                  polylines: [
                                    // White border polyline (Google Maps style)
                                    Polyline(
                                      points: service.currentTrip!.path,
                                      color: Colors.white,
                                      strokeWidth: 8,
                                    ),
                                    // Main green safe route polyline
                                    Polyline(
                                      points: service.currentTrip!.path,
                                      color: AppTheme.safeGreen,
                                      strokeWidth: 6,
                                    ),
                                  ],
                                ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(service.currentLat, service.currentLng),
                                    width: 40,
                                    height: 40,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppTheme.primaryPurple, width: 2),
                                      ),
                                      child: const Icon(Icons.person_pin_circle_rounded, color: AppTheme.primaryPurple, size: 20),
                                    ),
                                  ),
                                  Marker(
                                    point: service.currentTrip!.path.last,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on_rounded, color: AppTheme.dangerRed, size: 30),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.safeGreen.withValues(alpha: 0.05 + _pulseController.value * 0.03),
                              const Color(0xFFF8FAFC),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.safeGreen.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Pulsing dot
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.safeGreen,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.safeGreen.withValues(alpha: 0.4 + _pulseController.value * 0.4),
                                        blurRadius: 4 + _pulseController.value * 6,
                                        spreadRadius: 1 + _pulseController.value * 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'TRIP IN PROGRESS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.safeGreen,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const Spacer(),
                                // ETA badge
                                if (service.etaMinutes > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'ETA ${service.etaMinutes}min',
                                      style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 11, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _formatDuration(_tripDuration),
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'To: ${service.currentTrip?.destination ?? "Unknown"} • ${service.distanceRemainingKm.toStringAsFixed(1)}km remaining',
                              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Real-time navigation stats
              Row(
                children: [
                  _TripStat(
                    icon: Icons.speed_rounded,
                    value: service.currentSpeedKmh.toStringAsFixed(0),
                    unit: 'km/h',
                    label: 'Speed',
                  ),
                  const SizedBox(width: 12),
                  _TripStat(
                    icon: Icons.straighten_rounded,
                    value: service.distanceRemainingKm.toStringAsFixed(1),
                    unit: 'km',
                    label: 'Remaining',
                  ),
                  const SizedBox(width: 12),
                  _TripStat(
                    icon: Icons.shield_rounded,
                    value: '${service.riskScore}',
                    unit: '/100',
                    label: 'Risk',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Next turn card
              if (service.currentInstruction != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(service.currentInstruction!.icon, color: AppTheme.primaryPurple, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.currentInstruction!.instruction,
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            service.distanceToNextTurnM >= 1000
                              ? '${(service.distanceToNextTurnM / 1000).toStringAsFixed(1)}km'
                              : '${service.distanceToNextTurnM.round()}m',
                            style: const TextStyle(color: AppTheme.safeGreen, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const Text('to turn', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Status updates
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassDecoration(opacity: 0.05, borderRadius: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Updates', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    _UpdateItem(time: 'Now', text: 'On expected route', color: AppTheme.safeGreen, icon: Icons.check_circle_rounded),
                    _UpdateItem(time: '2m ago', text: 'Location shared with Mom', color: AppTheme.primaryPurple, icon: Icons.share_location_rounded),
                    _UpdateItem(time: '5m ago', text: 'Trip started', color: AppTheme.primaryPurple, icon: Icons.play_circle_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // End trip button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    service.endTrip();
                    _durationTimer?.cancel();
                    setState(() => _tripDuration = 0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dangerRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('End Trip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}



class _TripStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;

  const _TripStat({required this.icon, required this.value, required this.unit, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration(opacity: 0.05, borderRadius: 14),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text(unit, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _UpdateItem extends StatelessWidget {
  final String time;
  final String text;
  final Color color;
  final IconData icon;

  const _UpdateItem({required this.time, required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Text(time, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
