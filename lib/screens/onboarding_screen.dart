import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/local_storage_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      title: 'Welcome to NIVARAN',
      subtitle: 'Your personal safety companion powered by AI and community intelligence.',
      imagePath: 'assets/images/onboarding_welcome.png',
      color: const Color(0xFFFF8B8B), // Soft red/pink
    ),
    OnboardingData(
      title: 'Quick Actions',
      subtitle: 'Activate Fake Calls, AI Guard, or Cyber Help instantly with a single tap.',
      imagePath: 'assets/images/onboarding_quick_actions.png',
      color: const Color(0xFFFB923C), // Soft orange
    ),
    OnboardingData(
      title: 'Safety Network',
      subtitle: 'Share incidents with the community, trigger SOS, and store secure evidence.',
      imagePath: 'assets/images/onboarding_safety_features.png',
      color: const Color(0xFF8B5CF6), // Soft purple/violet
    ),
    OnboardingData(
      title: 'Smart Monitoring',
      subtitle: 'Real-time risk assessment on the map and a dedicated AI companion for your trips.',
      imagePath: 'assets/images/onboarding_map_ai.png',
      color: const Color(0xFF2DD4BF), // Soft teal/cyan
    ),
  ];

  void _onNext() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    await LocalStorageService.setOnboardingCompleted(true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                    )
                  else
                    const SizedBox(width: 48),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.nunito(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final data = _onboardingData[index];
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            data.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ).animate().fadeIn(duration: 600.ms).moveY(begin: 20, end: 0),
                          const SizedBox(height: 20), // Reduced from 48
                          
                          // Image Container with rounded background
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 320, // Reduced from 380
                                margin: const EdgeInsets.only(top: 60), // Reduced from 80
                                decoration: BoxDecoration(
                                  color: data.color.withValues(alpha: 0.9),
                                  borderRadius: const BorderRadius.all(Radius.circular(64)),
                                ),
                              ).animate(target: 1).fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.elasticOut),
                              
                              Positioned(
                                top: 0,
                                child: Image.asset(
                                  data.imagePath,
                                  height: 240, // Reduced from 300
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.image_outlined,
                                    size: 100,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ).animate().fadeIn(delay: 400.ms, duration: 600.ms).moveY(begin: 30, end: 0),
                              ),
                          
                              // Subtitle inside the card area
                              Positioned(
                                bottom: 30, // Reduced from 40
                                left: 32,
                                right: 32,
                                child: Text(
                                  data.subtitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    fontSize: 15, // Reduced from 16
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.4, // Reduced from 1.5
                                  ),
                                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Bar
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTheme.primaryPurple
                              : AppTheme.primaryPurple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 8,
                        shadowColor: AppTheme.primaryPurple.withValues(alpha: 0.4),
                      ),
                      child: Text(
                        _currentPage == _onboardingData.length - 1 ? "Let's Start" : 'Next',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String imagePath;
  final Color color;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.color,
  });
}
