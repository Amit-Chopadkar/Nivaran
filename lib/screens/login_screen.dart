import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLogin = true; 
  bool _obscurePassword = true;
  String _selectedGender = 'female'; // Default to female

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final userService = context.read<UserService>();
      final blockchainService = context.read<BlockchainService>();
      final authService = context.read<AuthService>();
      final safetyService = context.read<SafetyService>();

      if (_isLogin) {
        // --- LOGIN LOGIC (Supabase + Wallet Signature Based) ---
        // 1. Verify Password against Cloud DB
        final supabaseSuccess = await userService.loginWithEmailAndPassword(
          _emailController.text, 
          _passwordController.text
        );

        if (supabaseSuccess) {
          // 2. Verify hardware wallet signature dynamically 
          String? email = await authService.login();
          
          if (email == null && !authService.hasLocalWallet) {
            // Case where password is correct, but local wallet is missing (e.g. multi-device or logout)
            scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(content: Text('Re-verifying Identity on this device...')),
            );
            
            // Re-create wallet & register mapping for existing email
            final profile = userService.profile!;
            final signupData = {
              'name': profile.name,
              'email': profile.email,
              'phone': profile.phone,
              'idNumber': profile.idNumber,
            };
            
            final error = await authService.signup(signupData);
            if (error == null) {
              email = await authService.login(); // Try login again
            } else {
              debugPrint('Re-registration failed: $error');
            }
          }

          if (email != null) {
            // Success! Identity matched both password & (new/existing) hardware wallet
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          } else {
            userService.logout(); // Reset local state
            scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(content: Text('Blockchain verification failed. Wallet not found or network error.')),
            );
          }
        } else {
          scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Invalid email or password.')),
          );
        }
      } else {
        // --- SIGNUP LOGIC (Wallet Generation Based) ---
        final userData = {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'idNumber': _idController.text,
        };

        // 1. Authenticate & Auto-generate Ethereum Wallet Address
        final errorMessage = await authService.signup(userData);

        if (errorMessage == null) {
          // 2. Create local User Profile for UI
          final profile = UserProfile(
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            idNumber: _idController.text,
            gender: _selectedGender,
          );
          
          // 3. Save profile to Supabase (returns error string if it fails)
          final dbError = await userService.register(profile, _passwordController.text);
          if (dbError != null) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text('Account created but profile not saved to cloud: $dbError'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }

          // 4. Ensure SafetyService knows the user email BEFORE navigating to
          //    RegisterContactsScreen, so any contacts saved there get the right email.
          safetyService.updateUserContext(profile.name, profile.email);

          // 5. Store KYC on Blockchain (Event Hash logger)
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
                blockchainService.lastKYCHash!
              );
            } else {
              scaffoldMessengerKey.currentState?.showSnackBar(
                const SnackBar(
                  content: Text('Verification delayed. Identity will be synced in background.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }

            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => const RegisterContactsScreen()),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F1A),
              Color(0xFF1A0A2E),
              Color(0xFF0F0F1A),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _isLogin ? 'Welcome Back' : 'Create Your Secure Profile',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isLogin 
                      ? 'Secure access to your personal safety dashboard.' 
                      : 'Your identity will be verified and secured on the blockchain.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  if (!_isLogin) 
                    _buildTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      validator: (v) => !_isLogin && v!.isEmpty ? 'Enter your name' : null,
                    ),
                  if (!_isLogin) const SizedBox(height: 16),
                  
                  _buildTextField(
                    label: 'Email Address',
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.contains('@') ? null : 'Enter valid email',
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    label: 'Password',
                    controller: _passwordController,
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                    validator: (v) => v!.length < 6 ? 'Password too short (min 6)' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  if (!_isLogin)
                    _buildTextField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (v) => !_isLogin && v!.length < 10 ? 'Enter valid phone' : null,
                    ),
                  if (!_isLogin) const SizedBox(height: 16),
                  
                  if (!_isLogin)
                    _buildTextField(
                      label: 'Govt ID / Aadhar Number',
                      controller: _idController,
                      icon: Icons.badge_outlined,
                      validator: (v) => !_isLogin && v!.isEmpty ? 'Enter ID' : null,
                    ),
                  if (!_isLogin) const SizedBox(height: 24),
                  if (!_isLogin) ...[
                    Text(
                      'Select Gender',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGenderButton(
                            label: 'Female',
                            icon: Icons.female_rounded,
                            isSelected: _selectedGender == 'female',
                            onTap: () => setState(() => _selectedGender = 'female'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildGenderButton(
                            label: 'Male',
                            icon: Icons.male_rounded,
                            isSelected: _selectedGender == 'male',
                            onTap: () => setState(() => _selectedGender = 'male'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!_isLogin) const SizedBox(height: 40),
                  if (_isLogin) const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isLogin ? 'Log In' : 'Sign Up & Next',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In",
                        style: TextStyle(color: AppTheme.primaryPurple),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'By proceeding, you agree to our Security Terms.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryPurple.withValues(alpha: 0.1) 
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryPurple : AppTheme.textMuted,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 22),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: AppTheme.textMuted, size: 20),
            onPressed: onToggleVisibility,
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: validator,
      ),
    );
  }
}
