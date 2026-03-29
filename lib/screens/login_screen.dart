import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/blockchain_service.dart';
import '../services/safety_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'register_contacts_screen.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;
  String _selectedGender = 'female';

  // Animation controllers
  late AnimationController _bgController;
  late AnimationController _cardController;
  late AnimationController _fieldController;

  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _fieldFade;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fieldController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _fieldFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fieldController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _cardController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fieldController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    _fieldController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode() {
    _fieldController.reset();
    setState(() => _isLogin = !_isLogin);
    _fieldController.forward();
  }

  Future<void> _handleAuth() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final userService = context.read<UserService>();
      final blockchainService = context.read<BlockchainService>();
      final authService = context.read<AuthService>();
      final safetyService = context.read<SafetyService>();

      if (_isLogin) {
        final supabaseSuccess = await userService.loginWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );

        if (supabaseSuccess) {
          String? email = await authService.login();

          if (email == null) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(content: Text('Re-verifying Identity on this device...')),
            );

            final profile = userService.profile!;
            final signupData = {
              'name': profile.name,
              'email': profile.email,
              'phone': profile.phone,
              'idNumber': profile.idNumber,
            };

            final error = await authService.signup(signupData);
            if (error == null) {
              email = await authService.login();
            } else {
              debugPrint('Re-registration failed: $error');
            }
          }

          if (email != null) {
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          } else {
            userService.logout();
            scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(
                  content: Text(
                      'Blockchain verification failed. Wallet not found or network error.')),
            );
          }
        } else {
          scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Invalid email or password.')),
          );
        }
      } else {
        final userData = {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'idNumber': _idController.text,
        };

        final errorMessage = await authService.signup(userData);

        if (errorMessage == null) {
          final profile = UserProfile(
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            idNumber: _idController.text,
            gender: _selectedGender,
          );

          final dbError =
              await userService.register(profile, _passwordController.text);
          if (dbError != null) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text('Account creation failed: $dbError'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
            if (mounted) setState(() => _isLoading = false);
            return;
          }

          safetyService.updateUserContext(profile.name, profile.email);

          await blockchainService.storeKYCOnBlockchain({
            'name': profile.name,
            'email': profile.email,
            'phone': profile.phone,
            'id_number': profile.idNumber,
            'wallet_address': authService.address,
            'timestamp': DateTime.now().toIso8601String(),
          });

          if (mounted) {
            if (blockchainService.isUserVerified) {
              userService.updateVerificationStatus(
                true,
                blockchainService.lastTxHash!,
                blockchainService.lastKYCHash!,
              );
            } else {
              scaffoldMessengerKey.currentState?.showSnackBar(
                const SnackBar(
                  content: Text(
                      'Verification delayed. Identity will be synced in background.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }

            navigatorKey.currentState?.push(
              MaterialPageRoute(
                  builder: (_) => const RegisterContactsScreen()),
            );
          }
        } else {
          if (mounted) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text('Signup failed: $errorMessage')),
            );
          }
        }
      }

      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Animated background ──────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) {
                final t = _bgController.value * 2 * math.pi;
                return Stack(
                  children: [
                    // White base
                    Container(color: Colors.white),
                    // Top-right soft lavender orb
                    Positioned(
                      right: -60 + math.sin(t) * 20,
                      top: size.height * 0.05 + math.cos(t * 0.7) * 15,
                      child: _buildOrb(300, const Color(0xFF7C3AED), 0.07),
                    ),
                    // Mid-left soft orb
                    Positioned(
                      left: -80 + math.cos(t * 0.8) * 18,
                      top: size.height * 0.40 + math.sin(t * 0.5) * 20,
                      child: _buildOrb(220, const Color(0xFF8B5CF6), 0.06),
                    ),
                    // Bottom accent
                    Positioned(
                      right: size.width * 0.1,
                      bottom: -40 + math.sin(t * 0.6) * 15,
                      child: _buildOrb(180, const Color(0xFFA78BFA), 0.08),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Decorative top arc ───────────────────────────────────────────
          Positioned(
            top: -size.width * 0.35,
            left: -size.width * 0.15,
            right: -size.width * 0.15,
            child: Container(
              height: size.width * 1.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C3AED).withValues(alpha: 0.12),
                    const Color(0xFF7C3AED).withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ── Main scrollable content ──────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // ── Logo + Header ──
                      AnimatedBuilder(
                        animation: _cardController,
                        builder: (_, __) => FadeTransition(
                          opacity: _cardFade,
                          child: SlideTransition(
                            position: _cardSlide,
                            child: _buildHeader(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Glass card with fields ──
                      AnimatedBuilder(
                        animation: _fieldController,
                        builder: (_, __) => FadeTransition(
                          opacity: _fieldFade,
                          child: _buildGlassCard(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Gender selector (signup only) ──
                      if (!_isLogin)
                        AnimatedBuilder(
                          animation: _fieldController,
                          builder: (_, __) => FadeTransition(
                            opacity: _fieldFade,
                            child: _buildGenderSection(),
                          ),
                        ),

                      if (!_isLogin) const SizedBox(height: 24),

                      // ── CTA Button ──
                      AnimatedBuilder(
                        animation: _fieldController,
                        builder: (_, __) => FadeTransition(
                          opacity: _fieldFade,
                          child: _buildCTAButton(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Switch mode ──
                      Center(
                        child: TextButton(
                          onPressed: _switchMode,
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF94A3B8).withValues(alpha: 0.8),
                              ),
                              children: [
                                TextSpan(
                                  text: _isLogin
                                      ? "Don't have an account? "
                                      : 'Already have an account? ',
                                  style: const TextStyle(color: Color(0xFF64748B)),
                                ),
                                const TextSpan(
                                  text: 'Sign Up',
                                  style: TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Terms ──
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 11,
                              color: const Color(0xFF22C55E).withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'By proceeding, you agree to our Security Terms.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.50),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 24),

        // Title
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF1E1035), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            _isLogin ? 'Welcome\nBack' : 'Create Your\nSecure Profile',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Subtitle
        Row(
          children: [
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isLogin
                    ? 'Secure access to your personal safety dashboard'
                    : 'Your identity will be verified and secured on the blockchain',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Glass card ───────────────────────────────────────────────────────────

  Widget _buildGlassCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!_isLogin) ...[
              _buildField(
                label: 'Full Name',
                hint: 'Enter your name',
                controller: _nameController,
                icon: Icons.person_rounded,
                validator: (v) => !_isLogin && v!.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 14),
            ],
            _buildField(
              label: 'Email Address',
              hint: 'you@example.com',
              controller: _emailController,
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.contains('@') ? null : 'Enter valid email',
            ),
            const SizedBox(height: 14),
            _buildField(
              label: 'Password',
              hint: '••••••••',
              controller: _passwordController,
              icon: Icons.lock_rounded,
              isPassword: true,
              obscureText: _obscurePassword,
              onToggleVisibility: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
            ),
            if (!_isLogin) ...[
              const SizedBox(height: 14),
              _buildField(
                label: 'Phone Number',
                hint: '+91 XXXXX XXXXX',
                controller: _phoneController,
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    !_isLogin && v!.length < 10 ? 'Enter valid phone' : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                label: 'Govt ID / Aadhar Number',
                hint: 'XXXX XXXX XXXX',
                controller: _idController,
                icon: Icons.badge_rounded,
                validator: (v) => !_isLogin && v!.isEmpty ? 'Enter ID' : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Single text field ────────────────────────────────────────────────────

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7C3AED),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Color(0xFF1E1035),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFAA99CC),
                fontSize: 14,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF7C3AED), size: 18),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: const Color(0xFFAA99CC),
                        size: 20,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  // ── Gender section ───────────────────────────────────────────────────────

  Widget _buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(Icons.people_rounded,
                    color: Color(0xFFA78BFA), size: 12),
              ),
              const SizedBox(width: 8),
              Text(
                'Select Gender',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7C3AED),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildGenderChip(
                label: 'Female',
                icon: Icons.female_rounded,
                emoji: '♀',
                isSelected: _selectedGender == 'female',
                onTap: () => setState(() => _selectedGender = 'female'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderChip(
                label: 'Male',
                icon: Icons.male_rounded,
                emoji: '♂',
                isSelected: _selectedGender == 'male',
                onTap: () => setState(() => _selectedGender = 'male'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderChip({
    required String label,
    required IconData icon,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFFF5F3FF),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : const Color(0xFF7C3AED).withValues(alpha: 0.20),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.40),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF8B5CF6),
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CTA Button ───────────────────────────────────────────────────────────

  Widget _buildCTAButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.55),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleAuth,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? 'Log In' : 'Create Account',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Helper ───────────────────────────────────────────────────────────────

  Widget _buildOrb(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: size * 0.6,
            spreadRadius: size * 0.1,
          ),
        ],
        color: color.withValues(alpha: opacity * 0.35),
      ),
    );
  }
}
