import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_legal_service.dart';

class AutoFirScreen extends StatefulWidget {
  const AutoFirScreen({super.key});

  @override
  State<AutoFirScreen> createState() => _AutoFirScreenState();
}

class _AutoFirScreenState extends State<AutoFirScreen> {
  final _incidentController = TextEditingController();
  final _accusedController = TextEditingController();
  final _witnessController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateTimeController = TextEditingController();
  String _selectedCrime = 'Harassment';
  bool _isLoading = false;
  String? _aiResponse;

  final _crimeTypes = ['Harassment', 'Assault', 'Theft', 'Stalking', 'Molestation', 'Domestic Violence', 'Cybercrime', 'Other'];
  final _crimeIcons = {
    'Harassment': Icons.report_gmailerrorred_rounded,
    'Assault': Icons.front_hand_rounded,
    'Theft': Icons.money_off_rounded,
    'Stalking': Icons.visibility_rounded,
    'Molestation': Icons.warning_amber_rounded,
    'Domestic Violence': Icons.home_rounded,
    'Cybercrime': Icons.computer_rounded,
    'Other': Icons.more_horiz_rounded,
  };

  Future<void> _generateFIR() async {
    if (_incidentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please describe the incident', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() { _isLoading = true; _aiResponse = null; });

    final result = await AILegalService.generateFIR(
      crimeType: _selectedCrime,
      dateTime: _dateTimeController.text.trim().isEmpty ? 'Not specified' : _dateTimeController.text.trim(),
      location: _locationController.text.trim().isEmpty ? 'Not specified' : _locationController.text.trim(),
      incidentDescription: _incidentController.text.trim(),
      accusedDescription: _accusedController.text.trim().isEmpty ? 'Unknown' : _accusedController.text.trim(),
      witnesses: _witnessController.text.trim().isEmpty ? 'None' : _witnessController.text.trim(),
    );

    if (mounted) setState(() { _isLoading = false; _aiResponse = result; });
  }

  @override
  void dispose() {
    _incidentController.dispose();
    _accusedController.dispose();
    _witnessController.dispose();
    _locationController.dispose();
    _dateTimeController.dispose();
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
            backgroundColor: const Color(0xFFD97706),
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
                    colors: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFEAB308)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(top: -40, right: -30, child: _glowCircle(140, 0.1)),
                    Positioned(bottom: -20, left: -20, child: _glowCircle(100, 0.07)),
                    Positioned(top: 40, right: 40, child: _glowCircle(50, 0.06)),
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
                            child: const Icon(Icons.description_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(height: 12),
                          Text('Auto FIR Generator', style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 4),
                          Text('AI-powered legal document drafting', style: GoogleFonts.nunito(fontSize: 13, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w500)),
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
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFFD97706),
                  title: 'How it works',
                  subtitle: 'Describe the incident in your own words. AI will format it into a structured, professional FIR draft ready for the police.',
                  gradientColors: [const Color(0xFFFEF3C7), const Color(0xFFFDE68A).withValues(alpha: 0.5)],
                ),
                const SizedBox(height: 28),

                // Crime Type
                _buildSectionHeader('⚖️', 'Nature of Crime'),
                const SizedBox(height: 10),
                _buildCrimeTypeGrid(),
                const SizedBox(height: 28),

                // Date & Time
                _buildSectionHeader('📅', 'Date & Time'),
                const SizedBox(height: 10),
                _buildInputField(_dateTimeController, 'e.g., 25th March 2026, 10:30 PM', Icons.calendar_today_rounded, maxLines: 1),
                const SizedBox(height: 20),

                // Location
                _buildSectionHeader('📍', 'Location'),
                const SizedBox(height: 10),
                _buildInputField(_locationController, 'Where did the incident occur?', Icons.location_on_outlined, maxLines: 1),
                const SizedBox(height: 20),

                // Incident
                _buildSectionHeader('📋', 'What Happened? *'),
                const SizedBox(height: 10),
                _buildInputField(_incidentController, 'Describe the incident in your own words — include all details you remember...', Icons.edit_note_rounded, maxLines: 5),
                const SizedBox(height: 20),

                // Accused
                _buildSectionHeader('👤', 'Description of Accused'),
                const SizedBox(height: 10),
                _buildInputField(_accusedController, 'Any details — name, appearance, vehicle, etc.', Icons.person_search_rounded, maxLines: 2),
                const SizedBox(height: 20),

                // Witnesses
                _buildSectionHeader('👥', 'Witnesses'),
                const SizedBox(height: 10),
                _buildInputField(_witnessController, 'Names or details of any witnesses', Icons.group_outlined, maxLines: 1),
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

  Widget _buildInputField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.nunito(color: const Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: maxLines == 1 ? Padding(padding: const EdgeInsets.only(left: 14, right: 10), child: Icon(icon, size: 20, color: const Color(0xFFD97706))) : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: const Color(0xFFE2E8F0).withValues(alpha: 0.6))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5)),
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }

  Widget _buildCrimeTypeGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _crimeTypes.map((crime) {
        final isActive = crime == _selectedCrime;
        return GestureDetector(
          onTap: () => setState(() => _selectedCrime = crime),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFD97706) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isActive ? const Color(0xFFD97706) : const Color(0xFFE2E8F0)),
              boxShadow: isActive
                  ? [BoxShadow(color: const Color(0xFFD97706).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_crimeIcons[crime] ?? Icons.help_outline, size: 16, color: isActive ? Colors.white : const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(crime, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: isActive ? Colors.white : const Color(0xFF64748B))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGradientButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _generateFIR,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFEAB308)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFFD97706).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.description_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text('Generate FIR Draft', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
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
        border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: const Color(0xFFD97706).withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 15)),
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
                  gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text('FIR Draft', style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFFD97706))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                child: Text('DRAFT', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFD97706))),
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
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFF92400E), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This is a draft. It must be verified and filed by an authorized police officer to become a legal document.',
                    style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF92400E), height: 1.4),
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
