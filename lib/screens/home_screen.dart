import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../models/mesh_message.dart';
import '../services/mesh_service.dart';
import '../services/safety_service.dart';
import 'dashboard_screen.dart';
import 'map_screen.dart';
import 'sos_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';
import '../services/mesh_call_service.dart';
import 'mesh_call_screen.dart';
import 'mesh_chat_screen.dart';
import '../widgets/night_mode_banner.dart';
import '../widgets/night_mode_map_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _screens = const [
    DashboardScreen(),
    MapScreen(),
    SizedBox(), // SOS placeholder
    CommunityScreen(),
    ProfileScreen(),
  ];

  StreamSubscription? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MeshCallService>().addListener(_onCallStateChange);
        context.read<SafetyService>().addListener(_onSafetyServiceChange);
        final mesh = context.read<MeshService>();
        _chatSubscription = mesh.chatMessageStream.listen(_onNewChatMessage);
        _initMeshBackground(mesh);
      }
    });
  }

  bool _lastTripState = false;
  void _onSafetyServiceChange() {
    if (!mounted) return;
    final safety = context.read<SafetyService>();
    if (safety.isTripActive && !_lastTripState) {
      // Trip started, switch to Map tab
      _onTabTapped(1);
    }
    _lastTripState = safety.isTripActive;
  }

  Future<void> _initMeshBackground(MeshService mesh) async {
    await [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();

    if (await Permission.location.serviceStatus.isEnabled) {
      // Initialize in the background so it starts scanning instantly
      await mesh.init();
    }
  }

  void _onNewChatMessage(MeshMessage msg) {
    if (!mounted) return;
    
    final mesh = context.read<MeshService>();
    final endpointId = mesh.userIdToEndpoint[msg.senderId];
    final senderNameResolved = endpointId != null 
        ? mesh.connectedPeers[endpointId] ?? 'Someone'
        : 'Someone';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New offline message from $senderNameResolved'),
        backgroundColor: AppTheme.primaryPurple,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Dismiss snackbar
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => MeshChatScreen(peerId: msg.senderId, peerName: senderNameResolved)
            ));
          },
        ),
      ),
    );
  }

  bool _isCallScreenOpen = false;

  void _onCallStateChange() {
    if (!mounted) return;
    final callService = context.read<MeshCallService>();
    if (callService.isIncoming && !_isCallScreenOpen) {
      _isCallScreenOpen = true;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MeshCallScreen()),
      ).then((_) => _isCallScreenOpen = false);
    }
  }

  @override
  void dispose() {
    context.read<MeshCallService>().removeListener(_onCallStateChange);
    context.read<SafetyService>().removeListener(_onSafetyServiceChange);
    _chatSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // 'SOS' tab tapped (opens SOS screen)
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SOSScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
      return;
    }
    setState(() {
      _currentIndex = index;
      _pageController.animateToPage(
        index > 2 ? index - 1 : index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final safetyService = context.watch<SafetyService>();
    
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _screens[0],
              _screens[3],
              _screens[1],
              _screens[4],
            ],
          ),
          
          // Night Mode Map Overlay (Only on Map Tab)
          if (_currentIndex == 3) const NightModeMapOverlay(),

          // Night Mode Banner (Global Top)
          const SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: NightModeBanner(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: SizedBox(
          height: 85 + MediaQuery.of(context).padding.bottom,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: (_currentIndex * 2 + 1) / 10.0,
              end: (_currentIndex * 2 + 1) / 10.0,
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(
                    size: Size(double.infinity, 65 + MediaQuery.of(context).padding.bottom),
                    painter: CurvedNavPainter(loc: value, color: AppTheme.primaryPink), 
                  ),
                  child!,
                ],
              );
            },
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home'),
                  _buildNavItem(1, Icons.people_alt_rounded, 'Community'),
                  _buildNavItem(2, Icons.emergency_rounded, 'SOS'),
                  _buildNavItem(3, Icons.location_on_rounded, 'Map'),
                  _buildNavItem(4, Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 85,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Unselected icon + text
              AnimatedOpacity(
                opacity: isSelected ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.black, size: 28),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Selected floating circle
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                bottom: isSelected ? 32 : -30,
                child: AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF907CBE), // Vibrant purple matching image
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF896BD8).withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(icon, color: Colors.black, size: 30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  }


class CurvedNavPainter extends CustomPainter {
  final double loc;
  final Color color;

  CurvedNavPainter({required this.loc, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const cornerRadius = 30.0;
    
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    const notchWidth = 106.0;
    const notchDepth = 39.0;
    final notchCenter = loc * size.width;

    path.lineTo(notchCenter - notchWidth / 2, 0);

    // Deep smooth curve for notch
    path.cubicTo(
      notchCenter - notchWidth / 4, 0,
      notchCenter - notchWidth / 2.5, notchDepth,
      notchCenter, notchDepth,
    );

    path.cubicTo(
      notchCenter + notchWidth / 2.5, notchDepth,
      notchCenter + notchWidth / 4, 0,
      notchCenter + notchWidth / 2, 0,
    );

    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black, 15, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CurvedNavPainter oldDelegate) =>
      oldDelegate.loc != loc || oldDelegate.color != color;
}

