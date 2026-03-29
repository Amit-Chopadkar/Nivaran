import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/safety_service.dart';
import '../services/sos_background_service.dart';
import '../theme/app_theme.dart';
import '../services/local_storage_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'language_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _bgOrbController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _loadingFade;
  late Animation<double> _shimmer;

  // Loading dots
  late List<AnimationController> _dotControllers;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
    _scheduleNavigation();
  }

  void _initAnimations() {
    // Orbiting background gradient
    _bgOrbController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Logo entrance
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    // Text stagger
    _textController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // Loading section
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Particle float
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    // Shimmer on logo
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Logo animations
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // App name
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Tagline delayed inside textController
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    // Loading fade
    _loadingFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeOut),
    );

    // Shimmer
    _shimmer = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Bouncing dots
    _dotControllers = List.generate(
      3,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      )..repeat(reverse: true),
    );
    _dotAnimations = _dotControllers.asMap().entries.map((e) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: e.value, curve: Curves.easeInOut),
      );
    }).toList();

    // Stagger dots
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _dotControllers[1].repeat(reverse: true);
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _dotControllers[2].repeat(reverse: true);
    });
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _loadingController.forward();
  }

  void _scheduleNavigation() {
    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;

      final sosBridge = context.read<SOSBackgroundServiceBridge>();
      final safetyService = context.read<SafetyService>();
      final authService = context.read<AuthService>();
      final userService = context.read<UserService>();

      await sosBridge.startService();
      sosBridge.onSOSTriggered = () {
        safetyService.activateSOS();
      };

      final savedEmail = await authService.getSavedEmail();

      if (savedEmail != null) {
        await userService.fetchProfileByEmail(savedEmail);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, __) => const HomeScreen(),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
        return;
      }

      final verifiedEmail = await authService.login();

      if (mounted) {
        if (verifiedEmail != null) {
          await userService.fetchProfileByEmail(verifiedEmail);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, __) => const HomeScreen(),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, __) => const LanguageSelectionScreen(),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _bgOrbController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    for (final c in _dotControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Stack(
        children: [
          // ── Layer 1: Deep multi-stop gradient background ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.3),
                  radius: 1.4,
                  colors: [
                    Color(0xFF1F1040),
                    Color(0xFF0F0F1A),
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 2: Animated rotating orbs ──
          AnimatedBuilder(
            animation: _bgOrbController,
            builder: (_, __) {
              final t = _bgOrbController.value * 2 * math.pi;
              return Stack(
                children: [
                  // Large violet orb — top-left orbit
                  Positioned(
                    left: size.width * 0.5 +
                        math.cos(t) * size.width * 0.38 -
                        110,
                    top: size.height * 0.3 +
                        math.sin(t) * size.height * 0.15 -
                        110,
                    child: _Orb(
                      size: 220,
                      color: const Color(0xFF7C3AED),
                      opacity: 0.18,
                      blurRadius: 80,
                    ),
                  ),
                  // Medium pink orb — bottom-right orbit
                  Positioned(
                    right: size.width * 0.1 +
                        math.cos(t + math.pi) * size.width * 0.2,
                    bottom: size.height * 0.2 +
                        math.sin(t + math.pi) * size.height * 0.1,
                    child: _Orb(
                      size: 160,
                      color: const Color(0xFF8B5CF6),
                      opacity: 0.14,
                      blurRadius: 60,
                    ),
                  ),
                  // Accent cyan orb — slow drift
                  Positioned(
                    left: size.width * 0.1 +
                        math.sin(t * 0.7) * size.width * 0.1,
                    top: size.height * 0.65 +
                        math.cos(t * 0.7) * size.height * 0.08,
                    child: _Orb(
                      size: 120,
                      color: const Color(0xFF06B6D4),
                      opacity: 0.10,
                      blurRadius: 50,
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Layer 3: Floating particles ──
          AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) {
              return CustomPaint(
                painter: _ParticlePainter(
                  progress: _particleController.value,
                  color: const Color(0xFF8B5CF6),
                ),
                size: Size(size.width, size.height),
              );
            },
          ),

          // ── Layer 4: Concentric ring pulse ──
          Center(
            child: AnimatedBuilder(
              animation: _bgOrbController,
              builder: (_, __) {
                final pulse =
                    0.92 + 0.08 * math.sin(_bgOrbController.value * 2 * math.pi * 2);
                return Stack(
                  alignment: Alignment.center,
                  children: List.generate(4, (i) {
                    final baseSize = 140.0 + i * 55;
                    return Container(
                      width: baseSize * pulse,
                      height: baseSize * pulse,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryPurple.withValues(
                              alpha: math.max(0, 0.12 - i * 0.025)),
                          width: 1.0,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          // ── Layer 5: Main content ──
          SafeArea(
            child: Column(
              children: [
                // Flexible spacer — pushes logo to ~35% height
                const Spacer(flex: 5),

                // ── Logo ──
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (_, __) => Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: _LogoWidget(shimmer: _shimmer),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── App Name ──
                AnimatedBuilder(
                  animation: _textController,
                  builder: (_, __) => Opacity(
                    opacity: _textFade.value,
                    child: SlideTransition(
                      position: _textSlide,
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            const LinearGradient(
                          colors: [
                            Color(0xFF7C3AED),
                            Color(0xFF8B5CF6),
                            Color(0xFFA78BFA),
                            Color(0xFF8B5CF6),
                          ],
                          stops: [0.0, 0.3, 0.7, 1.0],
                        ).createShader(bounds),
                        child: const Text(
                          'NIVARAN',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Tagline ──
                AnimatedBuilder(
                  animation: _textController,
                  builder: (_, __) => Opacity(
                    opacity: _taglineFade.value,
                    child: SlideTransition(
                      position: _taglineSlide,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 1,
                            width: 28,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Color(0xFF8B5CF6),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'AI-Powered Safety Companion',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF94A3B8).withValues(alpha: 0.9),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 1,
                            width: 28,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF8B5CF6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Feature Badges ──
                AnimatedBuilder(
                  animation: _textController,
                  builder: (_, __) => Opacity(
                    opacity: _taglineFade.value,
                    child: SlideTransition(
                      position: _taglineSlide,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: const [
                          _FeatureBadge(
                            icon: Icons.shield_rounded,
                            label: 'Blockchain',
                            color: Color(0xFF7C3AED),
                          ),
                          _FeatureBadge(
                            icon: Icons.psychology_rounded,
                            label: 'AI Safety',
                            color: Color(0xFF06B6D4),
                          ),
                          _FeatureBadge(
                            icon: Icons.location_on_rounded,
                            label: 'Live Zones',
                            color: Color(0xFF22C55E),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 6),

                // ── Loading dots ──
                AnimatedBuilder(
                  animation: _loadingController,
                  builder: (_, __) => Opacity(
                    opacity: _loadingFade.value,
                    child: _LoadingDots(
                      controllers: _dotControllers,
                      animations: _dotAnimations,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Status text ──
                AnimatedBuilder(
                  animation: _loadingController,
                  builder: (_, __) => Opacity(
                    opacity: _loadingFade.value * 0.7,
                    child: Text(
                      'Initializing safety systems...',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF64748B).withValues(alpha: 0.8),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Bottom branding ──
                AnimatedBuilder(
                  animation: _loadingController,
                  builder: (_, __) => Opacity(
                    opacity: _loadingFade.value * 0.6,
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 11,
                              color: const Color(0xFF22C55E).withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Privacy-First  •  End-to-End Encrypted',
                              style: TextStyle(
                                fontSize: 11,
                                color: const Color(0xFF64748B).withValues(alpha: 0.6),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'v1.0.0  •  Built on Blockchain',
                          style: TextStyle(
                            fontSize: 10,
                            color: const Color(0xFF64748B).withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo Widget ──────────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  final Animation<double> shimmer;
  const _LogoWidget({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmer,
      builder: (_, __) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C3AED).withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Glassmorphic container
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7C3AED),
                    Color(0xFF8B5CF6),
                    Color(0xFFA78BFA),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    blurRadius: 70,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Shimmer overlay
                  ClipOval(
                    child: Transform.translate(
                      offset: Offset(shimmer.value * 60, 0),
                      child: Container(
                        width: 40,
                        height: 118,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Shield icon
                  const Icon(
                    Icons.shield_rounded,
                    size: 58,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Feature Badge ────────────────────────────────────────────────────────────

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.12),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading Dots ─────────────────────────────────────────────────────────────

class _LoadingDots extends StatelessWidget {
  final List<AnimationController> controllers;
  final List<Animation<double>> animations;

  const _LoadingDots({required this.controllers, required this.animations});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: animations[i],
          builder: (_, __) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.translate(
                offset: Offset(0, -8 * animations[i].value),
                child: Container(
                  width: i == 1 ? 10 : 7,
                  height: i == 1 ? 10 : 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == 1
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                    boxShadow: i == 1
                        ? [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ── Glowing Orb ──────────────────────────────────────────────────────────────

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  final double blurRadius;

  const _Orb({
    required this.size,
    required this.color,
    required this.opacity,
    required this.blurRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: blurRadius,
            spreadRadius: blurRadius * 0.3,
          ),
        ],
        color: color.withValues(alpha: opacity * 0.4),
      ),
    );
  }
}

// ── Particle Painter ──────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  static final _random = math.Random(42);

  static final List<_Particle> _particles = List.generate(
    18,
    (i) => _Particle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: 1.5 + _random.nextDouble() * 2.5,
      speed: 0.3 + _random.nextDouble() * 0.7,
      phase: _random.nextDouble() * 2 * math.pi,
    ),
  );

  _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in _particles) {
      final dy = math.sin(progress * 2 * math.pi * p.speed + p.phase) * 0.04;
      final x = p.x * size.width;
      final y = (p.y + dy) * size.height;
      final opacity = 0.15 + 0.2 * math.sin(progress * 2 * math.pi + p.phase).abs();

      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, size, speed, phase;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });
}
