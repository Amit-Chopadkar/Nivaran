import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

class BuddyTrackWidget extends StatelessWidget {
  final bool isTracking;
  final String? contactName;
  final String? contactPhone;
  final LatLng? userLocation;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const BuddyTrackWidget({
    super.key,
    required this.isTracking,
    this.contactName,
    this.contactPhone,
    this.userLocation,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    if (isTracking) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassDecoration(),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.red, size: 8),
                      const SizedBox(width: 8),
                      const Text(
                        'LIVE TRACKING',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text(
                  'Sharing for 2h 14m',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
                  child: Text(
                    contactName?[0].toUpperCase() ?? 'Buddy',
                    style: const TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        contactName ?? 'Buddy',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                        contactPhone ?? 'No Phone',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 25),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                height: 120,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: userLocation ?? const LatLng(19.9975, 73.7898),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                    ),
                    if (userLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: userLocation!,
                            width: 80,
                            height: 80,
                            child: const _PulsingUserMarker(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onStop,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.criticalRed.withValues(alpha: 0.1),
                foregroundColor: AppTheme.criticalRed,
                side: const BorderSide(color: AppTheme.criticalRed),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text('Stop Sharing', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Share your live location with a trusted contact throughout the night',
                  style: TextStyle(color: Colors.white, height: 1.5, fontSize: 14),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Buddy Track Details',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 15),
                // This would normally be a dropdown or dynamic list
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: AppTheme.primaryPurple, size: 20),
                      const SizedBox(width: 12),
                      const Text('Select Trusted Contact', style: TextStyle(color: Colors.white)),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.white54),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your contact receives a link showing your live location on a map. They are notified if you trigger SOS or miss a check-in.',
                        style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text('Start Buddy Track', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}

class _PulsingUserMarker extends StatefulWidget {
  const _PulsingUserMarker();

  @override
  State<_PulsingUserMarker> createState() => _PulsingUserMarkerState();
}

class _PulsingUserMarkerState extends State<_PulsingUserMarker> with SingleTickerProviderStateMixin {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 15 * (1 + _controller.value),
              height: 15 * (1 + _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryPurple.withValues(alpha: 0.5 * (1 - _controller.value)),
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryPurple,
                boxShadow: [BoxShadow(color: AppTheme.primaryPurple, blurRadius: 4)],
              ),
            ),
          ],
        );
      },
    );
  }
}
