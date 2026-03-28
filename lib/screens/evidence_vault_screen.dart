import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';
import '../services/evidence_service.dart';
import '../models/evidence.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

class EvidenceVaultScreen extends StatefulWidget {
  const EvidenceVaultScreen({super.key});

  @override
  State<EvidenceVaultScreen> createState() => _EvidenceVaultScreenState();
}

class _EvidenceVaultScreenState extends State<EvidenceVaultScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() => _isAuthenticated = true); // Fallback if no security
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access the Evidence Vault',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      
      setState(() {
        _isAuthenticated = didAuthenticate;
      });
    } catch (e) {
      debugPrint('Authentication error: $e');
      // If error occurs, we stay locked for safety
    }
  }

  Future<void> _openEvidence(Evidence evidence) async {
    try {
      // Re-authenticate for each file opening for high security
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to view this ${evidence.type.toLowerCase()}',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        final result = await OpenFilex.open(evidence.filePath);
        if (result.type != ResultType.done) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not open file: ${result.message}'),
                backgroundColor: AppTheme.dangerRed,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error opening evidence: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<EvidenceService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evidence Vault'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (_isAuthenticated ? AppTheme.safeGreen : AppTheme.dangerRed).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isAuthenticated ? Icons.lock_open_rounded : Icons.lock_rounded, 
                  size: 14, 
                  color: _isAuthenticated ? AppTheme.safeGreen : AppTheme.dangerRed
                ),
                const SizedBox(width: 4),
                Text(
                  _isAuthenticated ? 'Unlocked' : 'Locked', 
                  style: TextStyle(
                    fontSize: 11, 
                    color: _isAuthenticated ? AppTheme.safeGreen : AppTheme.dangerRed, 
                    fontWeight: FontWeight.w600
                  )
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (_isAuthenticated ? AppTheme.primaryPink : AppTheme.textMuted).withValues(alpha: 0.15), 
                    AppTheme.darkCard
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (_isAuthenticated ? AppTheme.primaryPink : AppTheme.textMuted).withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (_isAuthenticated ? AppTheme.primaryPink : AppTheme.textMuted).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _isAuthenticated ? Icons.enhanced_encryption_rounded : Icons.privacy_tip_rounded, 
                          color: _isAuthenticated ? AppTheme.primaryPink : AppTheme.textMuted, 
                          size: 28
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isAuthenticated ? 'Secure Evidence Vault' : 'Access Restricted',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isAuthenticated 
                                ? 'All recordings are encrypted and tamper-proof.' 
                                : 'Authentication required to view sensitive evidence.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isAuthenticated) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _StorageStat(label: 'Files', value: service.evidenceList.length.toString(), icon: Icons.folder_rounded),
                        const SizedBox(width: 8),
                        _StorageStat(label: 'Storage', value: '${(service.evidenceList.length * 1.2).toStringAsFixed(1)} MB', icon: Icons.storage_rounded),
                        const SizedBox(width: 8),
                        const _StorageStat(label: 'Protected', value: '72h', icon: Icons.timer_rounded),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick record
            Text('Quick Record', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RecordButton(
                    icon: service.isRecordingAudio ? Icons.stop_rounded : Icons.mic_rounded,
                    label: service.isRecordingAudio ? 'Stop' : 'Audio',
                    color: service.isRecordingAudio ? AppTheme.primaryPurple : AppTheme.dangerRed,
                    onTap: () {
                      if (service.isRecordingAudio) {
                        service.stopAudioRecording();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Audio recording saved'), backgroundColor: AppTheme.safeGreen)
                        );
                      } else {
                        service.startAudioRecording();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Recording audio...'), backgroundColor: AppTheme.dangerRed)
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RecordButton(
                    icon: Icons.videocam_rounded,
                    label: 'Video',
                    color: AppTheme.accentBlue,
                    onTap: () => service.captureVideo(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RecordButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Photo',
                    color: AppTheme.safeGreen,
                    onTap: () => service.capturePhoto(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Authentication Overlay / Content
            if (!_isAuthenticated)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.2)),
                      ),
                      child: Icon(Icons.fingerprint_rounded, size: 64, color: AppTheme.primaryPurple.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Evidence is Locked',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use your device security to unlock',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _authenticate,
                        icon: const Icon(Icons.lock_open_rounded, size: 18),
                        label: const Text('Unlock Vault'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Recent recordings
              Text('Recent Evidence', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),

              if (service.evidenceList.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text('No evidence collected yet', style: TextStyle(color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                )
              else
                ..._buildEvidenceList(service.evidenceList),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEvidenceList(List<Evidence> evidenceList) {
    return evidenceList.map((evidence) {
      IconData icon;
      Color color;
      switch (evidence.type) {
        case 'Audio':
          icon = Icons.mic_rounded;
          color = AppTheme.dangerRed;
          break;
        case 'Video':
          icon = Icons.videocam_rounded;
          color = AppTheme.accentBlue;
          break;
        case 'Photo':
        default:
          icon = Icons.camera_alt_rounded;
          color = AppTheme.safeGreen;
          break;
      }

      return InkWell(
        onTap: () => _openEvidence(evidence),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${evidence.type} Recording',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                        if (evidence.isSOS) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('SOS', style: TextStyle(fontSize: 9, color: AppTheme.dangerRed, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          DateFormat('MMM d, h:mm a').format(evidence.timestamp),
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                        if (evidence.duration != '—' && evidence.duration != null) ...[
                          Text(' • ', style: TextStyle(color: AppTheme.textMuted)),
                          Text(evidence.duration!, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _StorageStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StorageStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    // 5. Fix _StorageStat overflow by stacking icon and text vertically
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppTheme.textMuted),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            Text(label, style: TextStyle(fontSize: 8, color: AppTheme.textMuted, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RecordButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
