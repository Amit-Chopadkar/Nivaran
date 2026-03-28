import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class FIRHistoryScreen extends StatefulWidget {
  const FIRHistoryScreen({super.key});

  @override
  State<FIRHistoryScreen> createState() => _FIRHistoryScreenState();
}

class _FIRHistoryScreenState extends State<FIRHistoryScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _firs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFIRHistory();
  }

  Future<void> _fetchFIRHistory() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userEmail = authService.currentUserEmail;

    if (userEmail == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _supabase
          .from('firs')
          .select()
          .eq('user_email', userEmail)
          .order('created_at', ascending: false);

      setState(() {
        _firs = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching FIR history: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('My FIR Submissions', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD97706)))
          : _firs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_edu_rounded, size: 60, color: const Color(0xFF94A3B8).withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('No FIRs filed yet.', style: GoogleFonts.nunito(fontSize: 16, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _firs.length,
                  itemBuilder: (context, index) {
                    final fir = _firs[index];
                    final dateStr = fir['created_at'];
                    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  fir['crime_type'] ?? 'Unknown',
                                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFFD97706)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (fir['status'] == 'pending' ? const Color(0xFFFDE68A) : const Color(0xFFD1FAE5)),
                                    borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: Text(
                                    (fir['status'] ?? 'pending').toString().toUpperCase(),
                                    style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: fir['status'] == 'pending' ? const Color(0xFFB45309) : const Color(0xFF059669),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('MMM dd, yyyy • hh:mm a').format(date.toLocal()),
                              style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              fir['incident_description'] ?? 'No description provided.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF475569)),
                            ),
                            if (fir['evidence_ids'] != null && (fir['evidence_ids'] as List).isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(fir['evidence_ids'] as List).length} attachments',
                                    style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                                  ),
                                ],
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
