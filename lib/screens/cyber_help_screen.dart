import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/ai_legal_service.dart';

class CyberHelpScreen extends StatefulWidget {
  const CyberHelpScreen({super.key});

  @override
  State<CyberHelpScreen> createState() => _CyberHelpScreenState();
}

class _CyberHelpScreenState extends State<CyberHelpScreen> with SingleTickerProviderStateMixin {
  final _descriptionController = TextEditingController();
  String _selectedPlatform = 'Instagram';
  String _selectedFrequency = 'Once';
  String _selectedEmotionalState = 'Anxious';
  bool _isLoading = false;
  String? _aiResponse;
  late AnimationController _shimmerController;

  final _platforms = ['Instagram', 'WhatsApp', 'Facebook', 'Twitter/X', 'Snapchat', 'Telegram', 'Other'];
  final _frequencies = ['Once', 'Few times', 'Regularly', 'Daily', 'Constant'];
  final _emotionalStates = ['Calm', 'Anxious', 'Scared', 'Angry', 'Depressed', 'In Distress'];

  final _platformIcons = {
    'Instagram': Icons.camera_alt_outlined,
    'WhatsApp': Icons.chat_outlined,
    'Facebook': Icons.facebook_outlined,
    'Twitter/X': Icons.tag,
    'Snapchat': Icons.photo_camera_front_outlined,
    'Telegram': Icons.send_outlined,
    'Other': Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty) {
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

    final result = await AILegalService.getCyberHelp(
      description: _descriptionController.text.trim(),
      platform: _selectedPlatform,
      frequency: _selectedFrequency,
      emotionalState: _selectedEmotionalState,
    );

    if (mounted) setState(() { _isLoading = false; _aiResponse = result; });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _shimmerController.dispose();
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
            backgroundColor: const Color(0xFF7C3AED),
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
                    colors: [Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFFC026D3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(top: -40, right: -30, child: _glowCircle(140, 0.08)),
                    Positioned(bottom: -20, left: -20, child: _glowCircle(100, 0.06)),
                    Positioned(top: 30, left: 60, child: _glowCircle(60, 0.05)),
                    // Content
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
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(height: 12),
                          Text('Cyberbullying Help', style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 4),
                          Text('AI-powered digital safety analysis', style: GoogleFonts.nunito(fontSize: 13, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
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
                // Reassurance card
                _buildGlassCard(
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFEC4899),
                  title: 'You are not alone',
                  subtitle: 'Our AI will analyze the situation and provide immediate safety steps and emotional support.',
                  gradientColors: [const Color(0xFFFDF2F8), const Color(0xFFFCE7F3)],
                ),
                const SizedBox(height: 28),

                // ── Section: Description ──
                _buildSectionHeader('📝', 'Describe the Harassment'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF1E293B)),
                    decoration: _inputDecoration('What happened? Include screenshots text, messages, or a detailed description...'),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Section: Platform ──
                _buildSectionHeader('📱', 'Platform'),
                const SizedBox(height: 10),
                _buildPlatformGrid(),
                const SizedBox(height: 28),

                // ── Section: Frequency ──
                _buildSectionHeader('🔄', 'Frequency'),
                const SizedBox(height: 10),
                _buildPillSelector(_frequencies, _selectedFrequency, (v) => setState(() => _selectedFrequency = v), const Color(0xFF7C3AED)),
                const SizedBox(height: 28),

                // ── Section: Emotional State ──
                _buildSectionHeader('💭', 'How are you feeling?'),
                const SizedBox(height: 10),
                _buildEmotionSelector(),
                const SizedBox(height: 32),

                // ── Submit Button ──
                _buildGradientButton(),
                const SizedBox(height: 28),

                // ── Response ──
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

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.nunito(color: const Color(0xFF94A3B8), fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: const Color(0xFFE2E8F0).withValues(alpha: 0.6))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
    contentPadding: const EdgeInsets.all(18),
  );

  Widget _buildPlatformGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _platforms.map((platform) {
        final isActive = platform == _selectedPlatform;
        return GestureDetector(
          onTap: () => setState(() => _selectedPlatform = platform),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF7C3AED) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isActive ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
              boxShadow: isActive
                  ? [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_platformIcons[platform] ?? Icons.device_unknown, size: 16, color: isActive ? Colors.white : const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(platform, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: isActive ? Colors.white : const Color(0xFF64748B))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPillSelector(List<String> options, String selected, ValueChanged<String> onSelected, Color activeColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isActive = opt == selected;
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: isActive ? activeColor : const Color(0xFFE2E8F0)),
              boxShadow: isActive ? [BoxShadow(color: activeColor.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))] : [],
            ),
            child: Text(opt, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: isActive ? Colors.white : const Color(0xFF64748B))),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmotionSelector() {
    final emotionEmojis = {'Calm': '😌', 'Anxious': '😰', 'Scared': '😨', 'Angry': '😡', 'Depressed': '😞', 'In Distress': '🆘'};
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _emotionalStates.map((state) {
        final isActive = state == _selectedEmotionalState;
        return GestureDetector(
          onTap: () => setState(() => _selectedEmotionalState = state),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF7C3AED) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isActive ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
              boxShadow: isActive ? [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))] : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emotionEmojis[state] ?? '😐', style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(state, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: isActive ? Colors.white : const Color(0xFF64748B))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGradientButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _submitReport,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFFC026D3)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text('Get AI Safety Analysis', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
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
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 15)),
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
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFC026D3)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI Analysis & Safety Recommendations',
                  style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF7C3AED)),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Color(0xFF7C3AED), size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: response));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Response copied to clipboard', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                      backgroundColor: const Color(0xFF7C3AED),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                tooltip: 'Copy to Clipboard',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
                child: Text('AI', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF7C3AED))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          MarkdownBody(
            data: response,
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF334155), height: 1.7),
              h3: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B), height: 2.0),
              listBullet: TextStyle(color: const Color(0xFF7C3AED), fontSize: 16),
              strong: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }
}
