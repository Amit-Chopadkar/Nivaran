import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/safety_service.dart';
import '../models/safety_models.dart';
import 'fake_call_screen.dart';
import 'trip_monitor_screen.dart';
import 'ai_companion_screen.dart';
import 'cyber_help_screen.dart';
import 'auto_fir_screen.dart';
import 'law_counseling_screen.dart';
import 'evidence_vault_screen.dart';
import 'contacts_screen.dart';
import 'mesh_network_screen.dart';
import '../services/blockchain_service.dart';
import '../services/user_service.dart';
import '../services/weather_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _riskAnimController;
  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _riskAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _riskAnimController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  Color _getRiskColor(int score) {
    if (score <= 25) return AppTheme.safeGreen;
    if (score <= 50) return AppTheme.cautionYellow;
    if (score <= 75) return AppTheme.dangerOrange;
    return AppTheme.dangerRed;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SafetyService>();
    final blockchain = context.watch<BlockchainService>();
    final user = context.watch<UserService>();
    final weather = context.watch<WeatherService>();
    final riskColor = _getRiskColor(service.riskScore);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Premium App Bar ──────────────────────────────────────────
          SliverAppBar(
            floating: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppTheme.darkBg.withValues(alpha: 0.97),
            expandedHeight: 125,
            toolbarHeight: 125,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Glowing Avatar ──
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryPurple, AppTheme.primaryPink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryPurple.withValues(alpha: 0.5),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: ClipOval(
                          child: Image.asset(
                            user.profile?.gender == 'male'
                                ? 'assets/images/avatar_male.png'
                                : 'assets/images/avatar_female.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [AppTheme.primaryPurple, AppTheme.primaryPink],
                                ),
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 26),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // ── Name + Tagline ──
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Greeting
                          Text(
                            _getGreeting(),
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 1),

                          // User Name — fancy italic serif
                          Text(
                            user.profile?.name ?? 'Nivaran',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),

                          // Tagline
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppTheme.primaryPurple, AppTheme.primaryPink],
                            ).createShader(bounds),
                            child: Text(
                              'Your safety, our concern ✦',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),

                          // Blockchain badge always visible
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.verified_rounded, size: 10, color: AppTheme.safeGreen),
                              const SizedBox(width: 3),
                              Text(
                                'Logged on Polygon Blockchain',
                                style: GoogleFonts.nunito(
                                  fontSize: 9,
                                  color: AppTheme.safeGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ),


          SliverPadding(
            padding: const EdgeInsets.only(top: 1, left: 20, right: 20, bottom: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Risk Score Card
                _buildRiskCard(service, weather, riskColor),
                const SizedBox(height: 20),

                // Quick Actions
                _buildSectionTitle('Quick Actions', Icons.flash_on_rounded),
                const SizedBox(height: 12),
                _buildQuickActions(service),
                const SizedBox(height: 24),

                // Safety Features
                _buildSectionTitle('Safety Features', Icons.security_rounded),
                const SizedBox(height: 12),
                _buildFeatureGrid(),
                const SizedBox(height: 24),

                // AI Insights
                if (service.currentRiskAssessment != null) ...[
                  _buildSectionTitle('AI Insights', Icons.psychology_rounded),
                  const SizedBox(height: 12),
                  _buildAIInsights(service.currentRiskAssessment!),
                  const SizedBox(height: 24),
                ],

                // Recent Activity
                _buildSectionTitle('Safety Network', Icons.hub_rounded),
                const SizedBox(height: 12),
                _buildSafetyNetwork(service),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCard(SafetyService service, WeatherService weather, Color riskColor) {
    final safetyScore = 100 - service.riskScore;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B5CF6), // Bright Violet
            Color(0xFF7C3AED), // Stronger Violet
            Color(0xFF6D28D9), // Richer Violet
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // ── Premium Glass Highlight ──
            Positioned(
              left: -50,
              top: -80,
              child: Transform.rotate(
                angle: -0.4,
                child: Container(
                  width: 300,
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),

            // ── Animated Shine (Glossy Sweep) ──
            AnimatedBuilder(
              animation: _shineController,
              builder: (context, child) {
                return Positioned.fill(
                  child: FractionallySizedBox(
                    widthFactor: 2.0,
                    heightFactor: 1.0,
                    child: Transform.translate(
                      offset: Offset(
                        MediaQuery.of(context).size.width * (-1.5 + _shineController.value * 3),
                        0,
                      ),
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.28),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Column 1: Safety Scoring
                  _buildStatColumn(
                    '$safetyScore',
                    'safety\nscoring',
                    isMainScore: true,
                  ),

                  // Column 2: Crowd Density (dynamic based on risk/location/time)
                  _buildStatColumn(
                    _getCrowdDensityLabel(service),
                    'crowd\ndensity',
                  ),

                  // Column 3: Weather
                  _buildStatColumn(
                    weather.isLoading && weather.currentWeather == null
                        ? '--' 
                        : (weather.currentWeather != null 
                            ? '${weather.currentWeather!.temp.round()} °C' 
                            : '--'),
                    weather.currentWeather != null 
                        ? weather.currentWeather!.city.toLowerCase()
                        : (service?.currentLat == 0.0 ? 'detecting...' : 'weather'),
                    isWeather: true,
                    weather: weather,
                    service: service,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a dynamic crowd density label based on current risk, time, and hotspot proximity
  String _getCrowdDensityLabel(SafetyService service) {
    final hour = DateTime.now().hour;
    final riskScore = service.riskScore;
    
    // Base density from time of day (peak hours = more crowded)
    double densityScore = 0;
    if (hour >= 8 && hour <= 10) {
      densityScore = 65; // Morning rush
    } else if (hour >= 17 && hour <= 20) {
      densityScore = 75; // Evening rush
    } else if (hour >= 11 && hour <= 16) {
      densityScore = 50; // Daytime moderate
    } else if (hour >= 21 || hour <= 5) {
      densityScore = 15; // Night - low
    } else {
      densityScore = 35; // Early morning/late evening
    }
    
    // Adjust based on hotspot proximity (high risk = likely crowded area)
    final hotspots = SafetyModels.getCrimeHotspots();
    int nearbyHotspots = 0;
    for (var hotspot in hotspots) {
      final dist = _haversineDistanceKm(
        service.currentLat, service.currentLng, 
        hotspot.lat, hotspot.lng,
      );
      if (dist < 1.0) nearbyHotspots++;
    }
    densityScore += (nearbyHotspots * 8).clamp(0, 25);
    
    // Weekend adjustment
    final weekday = DateTime.now().weekday;
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      densityScore += 10;
    }
    
    // Clamp and classify
    densityScore = densityScore.clamp(0, 100);
    
    if (densityScore <= 25) return 'Low';
    if (densityScore <= 50) return 'Medium';
    if (densityScore <= 75) return 'High';
    return 'V. High';
  }

  double _haversineDistanceKm(double lat1, double lng1, double lat2, double lng2) {
    const p = 0.017453292519943295;
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lng2 - lng1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  Widget _buildStatColumn(String value, String label, {bool isMainScore = false, bool isWeather = false, WeatherService? weather, SafetyService? service}) {
    // Show snackbar if error just occurred
    if (isWeather && weather?.error != null && !weather!.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only show if the current context is still mounted
        if (context.mounted) {
           ScaffoldMessenger.of(context).hideCurrentSnackBar();
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Weather update failed: ${weather.error}'),
               backgroundColor: AppTheme.dangerRed,
               behavior: SnackBarBehavior.floating,
             ),
           );
        }
      });
    }

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isMainScore ? 32 : 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.2,
              letterSpacing: 0.2,
            ),
          ),
          if (isWeather) ...[
            const SizedBox(height: 14),
            if (weather?.error != null)
              GestureDetector(
                onTap: () {
                   // Retry via SafetyService logic
                   if (service != null) {
                     service.fetchLiveLocation();
                   } else {
                     context.read<SafetyService>().fetchLiveLocation();
                   }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                ),
              )
            else
              Theme(
                data: Theme.of(context).copyWith(
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                ),
                child: PopupMenuButton<String>(
                  offset: const Offset(0, 35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: AppTheme.darkBg,
                  onSelected: (val) {
                    if (val == '5days') _showWeatherForecast(weather!);
                    if (val == 'today' && weather != null) {
                       // Reload current weather if user manually asks for "Today"
                       context.read<SafetyService>().fetchLiveLocation();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'today',
                      child: Row(
                        children: [
                          const Icon(Icons.today_rounded, size: 18, color: Colors.white70),
                          const SizedBox(width: 10),
                          Text('Today', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: '5days',
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 18, color: Colors.white70),
                          const SizedBox(width: 10),
                          Text('Next 5 Days', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Today',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showWeatherForecast(WeatherService weather) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '5-Day Forecast',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (weather.forecast.isEmpty)
              const Center(child: Text('Fetching forecast...', style: TextStyle(color: Colors.white70)))
            else
              ...weather.forecast.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        DateFormat('E').format(f.dateTime!),
                        style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    Image.network(
                      'https://openweathermap.org/img/wn/${f.icon}.png',
                      width: 32,
                      height: 32,
                      errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: Text(
                        f.condition,
                        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${f.temp.round()}°',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }


  Widget _buildQuickActions(SafetyService service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.darkCardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.12)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _QuickActionButton(
              icon: Icons.phone_in_talk_outlined,
              label: 'Fake Call',
              iconColor: AppTheme.primaryPurple,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FakeCallScreen()));
              },
            ),
            const SizedBox(width: 24),
            _QuickActionButton(
              icon: Icons.explore_outlined,
              label: 'Trip',
              iconColor: AppTheme.primaryPurple,
              onTap: () => _showTripSafetyWarning(service),
            ),
            const SizedBox(width: 24),
            _QuickActionButton(
              icon: Icons.smart_toy_outlined,
              label: 'AI Guard',
              iconColor: AppTheme.primaryPurple,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AICompanionScreen()));
              },
            ),
            const SizedBox(width: 24),
            _QuickActionButton(
              icon: Icons.shield_outlined,
              label: 'Cyber Help',
              iconColor: const Color(0xFF7C3AED),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CyberHelpScreen()));
              },
            ),
            const SizedBox(width: 24),
            _QuickActionButton(
              icon: Icons.description_outlined,
              label: 'Auto FIR',
              iconColor: const Color(0xFFD97706),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AutoFirScreen()));
              },
            ),
            const SizedBox(width: 24),
            _QuickActionButton(
              icon: Icons.gavel_outlined,
              label: 'Law Help',
              iconColor: const Color(0xFF15803D),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LawCounselingScreen()));
              },
            ),
            const SizedBox(width: 24),
            _QuickActionButton(
              icon: Icons.camera_alt_outlined,
              label: 'Cam Detect',
              iconColor: const Color(0xFFE11D48),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EvidenceVaultScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _FeatureCard(
          icon: Icons.videocam_rounded,
          title: 'Evidence Vault',
          subtitle: 'Secure recordings',
          color: AppTheme.primaryPink,
          shineAnimation: _shineController,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EvidenceVaultScreen())),
        ),
        _FeatureCard(
          icon: Icons.contacts_rounded,
          title: 'Trusted Contacts',
          subtitle: 'Emergency network',
          color: AppTheme.accentBlue,
          shineAnimation: _shineController,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen())),
        ),
        _FeatureCard(
          icon: Icons.wifi_off_rounded,
          title: 'Mesh Network',
          subtitle: 'Offline SOS',
          color: AppTheme.accentCyan,
          shineAnimation: _shineController,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MeshNetworkScreen())),
        ),
        _FeatureCard(
          icon: Icons.watch_rounded,
          title: 'Wearable',
          subtitle: 'Smart triggers',
          color: AppTheme.accentViolet,
          shineAnimation: _shineController,
          onTap: () => _showWearableInfo(),
        ),
      ],
    );
  }

  Widget _buildAIInsights(RiskAssessment assessment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF3E8FF),
            const Color(0xFFE9D5FF).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.primaryPurple, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Daily Safety Tip',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryPurple,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...assessment.recommendations.take(3).map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              rec,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF2D3748),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSafetyNetwork(SafetyService service) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...service.emergencyContacts.take(10).map((contact) {
                  final isPolice = contact.name.toLowerCase().contains('police');
                  return Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: contact.isPrimary 
                                ? AppTheme.primaryRose 
                                : const Color(0xFFF1F5F9),
                            border: contact.isPrimary 
                                ? Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.2), width: 2)
                                : null,
                          ),
                          child: ClipOval(
                            child: isPolice
                                ? Image.asset(
                                    'assets/images/officer_man.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildAvatarInitial(contact),
                                  )
                                : _buildAvatarInitial(contact),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          contact.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                
                // Add Contact Button
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen())),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF1F5F9),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                        ),
                        child: const Icon(Icons.add_rounded, color: Color(0xFF64748B), size: 24),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.safeGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on_rounded, size: 14, color: AppTheme.safeGreen),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Location actively shared with primary contact',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarInitial(EmergencyContact contact) {
    return Center(
      child: Text(
        contact.name[0].toUpperCase(),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: contact.isPrimary ? AppTheme.primaryPurple : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryPurple),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18, // Increased from 16
            fontWeight: FontWeight.w900, // Maximally bold
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }



  void _showWearableInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentViolet.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.watch_rounded, color: AppTheme.accentViolet, size: 40),
            ),
            const SizedBox(height: 16),
            Text('Wearable Integration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Connect your smartwatch or Bluetooth panic button for instant SOS activation without touching your phone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _InfoChip(icon: Icons.watch, label: 'Smartwatch'),
                const SizedBox(width: 12),
                _InfoChip(icon: Icons.radio_button_checked, label: 'Panic Button'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentViolet,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Scan for Devices', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTripSafetyWarning(SafetyService service) {
    final isHighRisk = service.riskScore > 40;
    final nearestPolice = service.getNearestSafePlaces(type: SafePlaceType.policeStation, limit: 1);
    final otherSafe = service.getNearestSafePlaces(limit: 5);
    final safePlaces = [...nearestPolice, ...otherSafe]
        .fold<List<SafePlace>>([], (list, p) {
          if (!list.any((existing) => existing.name == p.name)) {
            list.add(p);
          }
          return list;
        })
        .take(3)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header with Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isHighRisk ? AppTheme.dangerRed : AppTheme.safeGreen).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isHighRisk ? AppTheme.dangerRed : AppTheme.safeGreen).withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isHighRisk ? AppTheme.dangerRed : AppTheme.safeGreen).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isHighRisk ? AppTheme.dangerRed : AppTheme.safeGreen).withValues(alpha: 0.2),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        isHighRisk ? Icons.warning_amber_rounded : Icons.shield_outlined,
                        color: isHighRisk ? AppTheme.dangerRed : AppTheme.safeGreen,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHighRisk ? 'Caution: High Risk Zone' : 'Safe Trip Planning',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isHighRisk ? 'Unsafe factors detected in your path.' : 'Start your journey with confidence.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              if (service.currentRiskAssessment != null && isHighRisk) ...[
                Row(
                  children: [
                    const Icon(Icons.crisis_alert_rounded, color: AppTheme.dangerRed, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'ACTIVE RISK FACTORS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.dangerRed.withValues(alpha: 0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...service.currentRiskAssessment!.factors.map((f) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.15), width: 1),
                  ),
                  child: Row(
                    children: [
                      Text(f.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                        Text(
                          f.name,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+${f.impact.round()}',
                          style: const TextStyle(
                            color: AppTheme.dangerRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  const Icon(Icons.place_rounded, color: AppTheme.primaryPurple, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'SUGGESTED SAFE ALTERNATIVES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryPurple.withValues(alpha: 0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...safePlaces.map((place) => GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TripMonitorScreen(initialDestination: place.name)));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.12), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.2)),
                        ),
                        child: Center(child: Text(place.typeEmoji, style: const TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              place.typeLabel,
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_rounded, color: AppTheme.primaryPurple, size: 18),
                      ),
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isHighRisk 
                            ? [const Color(0xFFF97316), const Color(0xFFEA580C)]
                            : [const Color(0xFF22C55E), const Color(0xFF16A34A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isHighRisk ? AppTheme.dangerOrange : AppTheme.safeGreen).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TripMonitorScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Start Trip',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.2), // Increased from 0.15
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13, // Increased from 12
              fontWeight: FontWeight.w800, // Bolder
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// _AddNewButton removed — replaced with Camera Detection quick action

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashCount = 12;
    const gapAngle = 0.18;
    const sweepAngle = (3.14159 * 2 / dashCount) - gapAngle;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * (3.14159 * 2 / dashCount);
      canvas.drawArc(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) => oldDelegate.color != color;
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final Animation<double> shineAnimation;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.shineAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Subtle Top Highlight for Glassy look
              Positioned(
                top: 0,
                left: 10,
                right: 10,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Glossy Shine Effect
              AnimatedBuilder(
                animation: shineAnimation,
                builder: (context, child) {
                  return Positioned.fill(
                    child: FractionallySizedBox(
                      widthFactor: 2.0,
                      heightFactor: 1.0,
                      child: Transform.translate(
                        offset: Offset(
                          MediaQuery.of(context).size.width * (-1.5 + shineAnimation.value * 3),
                          0,
                        ),
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.28), // Increased intensity
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14, // Increased from 13
                          fontWeight: FontWeight.w800, // Increased from w700
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11, // Increased from 10
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary, // Clearer than textMuted
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

