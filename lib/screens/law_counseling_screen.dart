import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_legal_service.dart';

class LawCounselingScreen extends StatefulWidget {
  const LawCounselingScreen({super.key});

  @override
  State<LawCounselingScreen> createState() => _LawCounselingScreenState();
}

class _LawCounselingScreenState extends State<LawCounselingScreen> {
  final _situationController = TextEditingController();
  String _selectedNationality = 'Indian';
  String _selectedGoal = 'Know my rights';
  bool _isLoading = false;
  String? _aiResponse;

  final _nationalities = ['Indian', 'Foreign Tourist', 'NRI', 'Other'];
  final _goals = ['Know my rights', 'Know the penalty', 'Find legal help', 'File a complaint', 'Understand a law'];

  final _nationalityFlags = {'Indian': '🇮🇳', 'Foreign Tourist': '🌍', 'NRI': '✈️', 'Other': '🏳️'};
  final _goalIcons = {
    'Know my rights': Icons.shield_outlined,
    'Know the penalty': Icons.gavel_outlined,
    'Find legal help': Icons.search_rounded,
    'File a complaint': Icons.description_outlined,
    'Understand a law': Icons.menu_book_rounded,
  };

  Future<void> _getAdvice() async {
    if (_situationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please describe your situation', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() { _isLoading = true; _aiResponse = null; });

    final result = await AILegalService.getLawCounseling(
      situation: _situationController.text.trim(),
      nationality: _selectedNationality,
      goal: _selectedGoal,
    );

    if (mounted) setState(() { _isLoading = false; _aiResponse = result; });
  }

  @override
  void dispose() {
    _situationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // ── Gradient App Bar ──
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF15803D),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF15803D), Color(0xFF16A34A), Color(0xFF22C55E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(top: -40, right: -30, child: _glowCircle(140, 0.08)),
                    Positioned(bottom: -20, left: -20, child: _glowCircle(100, 0.06)),
                    Positioned(top: 50, right: 50, child: _glowCircle(40, 0.06)),
                    Positioned(
                      bottom: 30,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(height: 12),
                          Text('Law Counseling', style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 4),
                          Text('AI-powered legal rights navigator', style: GoogleFonts.nunito(fontSize: 13, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ──
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Info card
                _buildGlassCard(
                  icon: Icons.balance_rounded,
                  iconColor: const Color(0xFF15803D),
                  title: 'Legal Navigator',
                  subtitle: 'Understand your rights under IPC/BNS. Get relevant legal sections explained in simple language.',
                  gradientColors: [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0).withValues(alpha: 0.5)],
                ),
                const SizedBox(height: 28),

                // Situation
                _buildSectionHeader('📝', 'What Happened? *'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: TextField(
                    controller: _situationController,
                    maxLines: 5,
                    style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF1E293B)),
                    decoration: InputDecoration(
                      hintText: 'Describe your situation or legal question in detail...',
                      hintStyle: GoogleFonts.nunito(color: const Color(0xFF94A3B8), fontSize: 13),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: const Color(0xFFE2E8F0).withValues(alpha: 0.6))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF15803D), width: 1.5)),
                      contentPadding: const EdgeInsets.all(18),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Nationality
                _buildSectionHeader('🌐', 'Nationality'),
                const SizedBox(height: 10),
                _buildNationalitySelector(),
                const SizedBox(height: 28),

                // Goal
                _buildSectionHeader('🎯', 'What do you need?'),
                const SizedBox(height: 10),
                _buildGoalSelector(),
                const SizedBox(height: 32),

                // Submit
                _buildGradientButton(),
                const SizedBox(height: 28),

                if (_aiResponse != null) _buildResponseCard(_aiResponse!),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
  );

  Widget _buildGlassCard({required IconData icon, required Color iconColor, required String title, required String subtitle, required List<Color> gradientColors}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: iconColor.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.15), blurRadius: 10)]),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF64748B), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildNationalitySelector() {
    return Row(
      children: _nationalities.map((nationality) {
        final isActive = nationality == _selectedNationality;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedNationality = nationality),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(right: nationality != _nationalities.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF15803D) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isActive ? const Color(0xFF15803D) : const Color(0xFFE2E8F0)),
                boxShadow: isActive
                    ? [BoxShadow(color: const Color(0xFF15803D).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Text(_nationalityFlags[nationality] ?? '🏳️', style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(
                    nationality,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? Colors.white : const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalSelector() {
    return Column(
      children: _goals.map((goal) {
        final isActive = goal == _selectedGoal;
        return GestureDetector(
          onTap: () => setState(() => _selectedGoal = goal),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF15803D) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isActive ? const Color(0xFF15803D) : const Color(0xFFE2E8F0)),
              boxShadow: isActive
                  ? [BoxShadow(color: const Color(0xFF15803D).withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Icon(_goalIcons[goal] ?? Icons.help_outline, size: 20, color: isActive ? Colors.white : const Color(0xFF64748B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(goal, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: isActive ? Colors.white : const Color(0xFF334155))),
                ),
                if (isActive) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGradientButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _getAdvice,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF16A34A), Color(0xFF22C55E)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF15803D).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gavel_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text('Get Legal Guidance', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildResponseCard(String response) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF15803D).withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: const Color(0xFF15803D).withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF22C55E)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Legal Guidance', style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF15803D))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                child: Text('IPC/BNS', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF15803D))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Text(response, style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF334155), height: 1.7)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF15803D), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'I am an AI, not a lawyer. This information is for educational purposes only.',
                    style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF15803D), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
