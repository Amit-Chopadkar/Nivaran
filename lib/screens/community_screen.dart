import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../services/safety_service.dart';
import '../models/safety_models.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedReportType = 'Harassment';
  final _descriptionController = TextEditingController();

  // Geo-cam state
  File? _capturedPhoto;
  bool _isCapturing = false;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  IconData _getTypeIconLocal(String type) {
    switch (type) {
      case 'Harassment': return Icons.report_rounded;
      case 'Poor Lighting': return Icons.lightbulb_outline_rounded;
      case 'Suspicious Activity': return Icons.visibility_rounded;
      case 'Road Safety': return Icons.directions_car_rounded;
      case 'Theft': return Icons.back_hand_rounded;
      case 'Stalking': return Icons.person_search_rounded;
      case 'Safe Zone': return Icons.shield_rounded;
      default: return Icons.flag_rounded;
    }
  }

  /// Opens the device camera, captures a photo, then overlays GPS coordinates
  /// and timestamp on it — producing a geo-stamped evidence image.
  Future<void> _captureGeoCamPhoto(SafetyService service) async {
    setState(() => _isCapturing = true);
    try {
      final picker = ImagePicker();
      final XFile? picked =
          await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (picked == null) {
        setState(() => _isCapturing = false);
        return;
      }

      // Render the geo-stamp overlay widget onto a temporary canvas
      // We wait one frame so the RepaintBoundary has the image ready
      final stampedBytes =
          await _stampGeoData(File(picked.path), service);

      final dir = await getApplicationDocumentsDirectory();
      final stampedPath =
          '${dir.path}/geo_report_${DateTime.now().millisecondsSinceEpoch}.png';
      final stampedFile = File(stampedPath);
      await stampedFile.writeAsBytes(stampedBytes);

      setState(() {
        _capturedPhoto = stampedFile;
        _isCapturing = false;
      });
    } catch (e) {
      debugPrint('GeoCam error: $e');
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Composites GPS + time text onto the captured image and returns PNG bytes.
  Future<Uint8List> _stampGeoData(File photo, SafetyService service) async {
    // Decode the image
    final rawBytes = await photo.readAsBytes();
    final codec = await ui.instantiateImageCodec(rawBytes);
    final frame = await codec.getNextFrame();
    final srcImage = frame.image;

    final width = srcImage.width.toDouble();
    final height = srcImage.height.toDouble();

    // Create a picture recorder to draw on
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // Draw the original photo
    canvas.drawImage(srcImage, Offset.zero, Paint());

    // --- Geo-stamp badge ---
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final coordStr =
        'Lat: ${service.currentLat.toStringAsFixed(6)}  Lng: ${service.currentLng.toStringAsFixed(6)}';

    // Badge background
    final badgePaint = Paint()..color = const Color(0xCC000000);
    final badgeRect = Rect.fromLTWH(0, height - 80, width, 80);
    canvas.drawRect(badgeRect, badgePaint);

    // Purple left accent bar
    final accentPaint = Paint()..color = const Color(0xFF7C3AED);
    canvas.drawRect(Rect.fromLTWH(0, height - 80, 6, 80), accentPaint);

    // Text
    void drawText(String text, double y, double fontSize,
        {Color color = Colors.white}) {
      final paragraphStyle = ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: fontSize,
      );
      final builder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(ui.TextStyle(color: color, fontSize: fontSize))
        ..addText(text);
      final paragraph = builder.build();
      paragraph.layout(ui.ParagraphConstraints(width: width - 24));
      canvas.drawParagraph(paragraph, Offset(16, y));
    }

    drawText('📍 $coordStr', height - 68, 18,
        color: const Color(0xFF86EFAC)); // green
    drawText('🕐 $dateStr', height - 42, 18,
        color: const Color(0xFFE2E8F0)); // light gray
    drawText('SafeHer Verified Report', height - 18, 13,
        color: const Color(0xFF7C3AED)); // purple

    final picture = recorder.endRecording();
    final stampedImage =
        await picture.toImage(width.toInt(), height.toInt());
    final byteData =
        await stampedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _submitReport(SafetyService service) {
    if (_capturedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.camera_alt_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Photo evidence is required'),
            ],
          ),
          backgroundColor: AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add a description'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    service.addReport(SafetyReport(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user',
      lat: service.currentLat,
      lng: service.currentLng,
      type: _selectedReportType,
      description: _descriptionController.text.trim(),
      timestamp: DateTime.now(),
      upvotes: 0,
      isVerified: false,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('Incident reported successfully!'),
          ],
        ),
        backgroundColor: AppTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // Reset form
    setState(() {
      _capturedPhoto = null;
      _selectedReportType = 'Harassment';
    });
    _descriptionController.clear();
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SafetyService>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.people_rounded,
                          color: AppTheme.primaryPurple,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Community Safety',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Crowd-Sourced Intelligence',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.wifi_tethering,
                              color: AppTheme.safeGreen, size: 24),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const mesh_view.MeshNetworkScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _StatCard(
                        value: '${service.communityReports.length}',
                        label: 'Total Reports',
                        color: AppTheme.primaryPurple,
                        icon: Icons.assignment_rounded,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        value: '${service.communityReports.where((r) => r.isVerified).length}',
                        label: 'Verified',
                        color: AppTheme.safeGreen,
                        icon: Icons.verified_user_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primaryPurple,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Live Feed'),
                  Tab(text: 'Report New'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReportsFeed(service),
                  _buildReportIncident(service),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsFeed(SafetyService service) {
    if (service.communityReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined,
                size: 64, color: AppTheme.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No incidents reported yet',
                style:
                    TextStyle(fontSize: 16, color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            Text('Be the first to keep the community safe',
                style: TextStyle(
                    fontSize: 13,
                    color:
                        AppTheme.textMuted.withValues(alpha: 0.6))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: service.communityReports.length,
      itemBuilder: (context, index) {
        final report = service.communityReports[index];
        return _ReportCard(report: report);
      },
    );
  }

  Widget _buildReportIncident(SafetyService service) {
    final types = [
      'Harassment',
      'Poor Lighting',
      'Suspicious Activity',
      'Road Safety',
      'Theft',
      'Stalking',
      'Safe Zone'
    ];
    final bool hasPhoto = _capturedPhoto != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── GEO-CAM SECTION ─────────────────────────────────────────
          _SectionLabel(label: 'Photo Evidence', required: true),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _isCapturing
                ? null
                : () => _captureGeoCamPhoto(service),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: hasPhoto ? 240 : 160,
              decoration: BoxDecoration(
                color: hasPhoto
                    ? Colors.transparent
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: hasPhoto
                      ? AppTheme.safeGreen.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.05),
                  width: hasPhoto ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasPhoto
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        // Geo-stamped photo
                        Image.file(
                          _capturedPhoto!,
                          fit: BoxFit.cover,
                        ),
                        // Re-take overlay
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _captureGeoCamPhoto(service),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text('Retake',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _isCapturing
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                  color: AppTheme.primaryPurple, strokeWidth: 3),
                              const SizedBox(height: 16),
                              Text('STAMPING LOCATION...',
                                  style:
                                      TextStyle(
                                        color: AppTheme.primaryPurple,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                        letterSpacing: 1,
                                      )),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryPurple
                                    .withValues(alpha: 0.08),
                              ),
                              child: const Icon(
                                Icons.add_a_photo_rounded,
                                color: AppTheme.primaryPurple,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Capture Evidence',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Auto-stamped with GPS & Time',
                              style: TextStyle(
                                  fontSize: 12, 
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
            ),
          ),

          if (!hasPhoto) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: AppTheme.dangerRed),
                const SizedBox(width: 6),
                Text(
                  'Photo is required to submit an incident report',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.dangerRed.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),

          // ── GPS INFO ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: AppTheme.accentBlue, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location (Auto-detected)',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lat: ${service.currentLat.toStringAsFixed(5)}, Lng: ${service.currentLng.toStringAsFixed(5)}',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.gps_fixed_rounded,
                    color: AppTheme.safeGreen, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── INCIDENT TYPE ─────────────────────────────────────────────
          const _SectionLabel(label: 'Incident Type'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: types.map((type) {
              final isSelected = type == _selectedReportType;
              final icon = _getTypeIconLocal(type);
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedReportType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryPurple
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected 
                          ? AppTheme.primaryPurple.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryPurple
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── DESCRIPTION ───────────────────────────────────────────────
          const _SectionLabel(label: 'Description'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Describe the incident clearly...',
                hintStyle: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── ANONYMITY ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentViolet.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.visibility_off_rounded,
                      color: AppTheme.accentViolet, size: 20),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Post Anonymously',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B)),
                      ),
                      Text(
                        'Your identity will be hidden',
                        style: TextStyle(
                            fontSize: 11, 
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: true,
                  onChanged: (v) {},
                  activeThumbColor: AppTheme.primaryPurple,
                  activeTrackColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── SUBMIT ────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: hasPhoto
                  ? () => _submitReport(service)
                  : null,
              icon: Icon(
                hasPhoto
                    ? Icons.send_rounded
                    : Icons.camera_alt_rounded,
                size: 20,
              ),
              label: Text(
                hasPhoto
                    ? 'Submit Incident Report'
                    : 'Photo Required',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasPhoto
                    ? AppTheme.primaryPurple
                    : const Color(0xFFF1F5F9),
                foregroundColor:
                    hasPhoto ? Colors.white : const Color(0xFF94A3B8),
                elevation: hasPhoto ? 8 : 0,
                shadowColor: AppTheme.primaryPurple.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ── Helper Widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _SectionLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B)),
        ),
        if (required) ...[
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.dangerRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Required',
              style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.dangerRed,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final dynamic report;

  const _ReportCard({required this.report});

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Harassment':
        return AppTheme.dangerRed;
      case 'Poor Lighting':
        return AppTheme.cautionYellow;
      case 'Suspicious Activity':
        return AppTheme.dangerOrange;
      case 'Road Safety':
        return AppTheme.accentBlue;
      case 'Safe Zone':
        return AppTheme.safeGreen;
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Harassment':
        return Icons.report_rounded;
      case 'Poor Lighting':
        return Icons.lightbulb_outline_rounded;
      case 'Suspicious Activity':
        return Icons.visibility_rounded;
      case 'Road Safety':
        return Icons.directions_car_rounded;
      case 'Safe Zone':
        return Icons.shield_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor(report.type);
    final icon = _getTypeIcon(report.type);
    final timeAgo = _timeAgo(report.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          report.type,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        if (report.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              size: 16, color: AppTheme.safeGreen),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.keyboard_arrow_up_rounded,
                        size: 18, color: Color(0xFF64748B)),
                    Text(
                      '${report.upvotes}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            report.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'At ${report.lat.toStringAsFixed(4)}, ${report.lng.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.gps_fixed_rounded,
                        size: 10, color: AppTheme.accentBlue),
                    SizedBox(width: 4),
                    Text(
                      'STAMPED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
