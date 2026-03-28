import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../models/evidence.dart';
import 'local_storage_service.dart';

class EvidenceService extends ChangeNotifier {
  final _picker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  final _uuid = const Uuid();

  List<Evidence> _evidenceList = [];
  List<Evidence> get evidenceList => _evidenceList;

  bool _isRecordingAudio = false;
  bool get isRecordingAudio => _isRecordingAudio;

  EvidenceService() {
    _loadEvidence();
  }

  void _loadEvidence() {
    final box = Hive.box<Evidence>(LocalStorageService.evidenceBoxName);
    _evidenceList = box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        await _saveEvidence(type: 'Photo', filePath: photo.path);
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    }
  }

  Future<void> captureVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        await _saveEvidence(type: 'Video', filePath: video.path);
      }
    } catch (e) {
      debugPrint('Error capturing video: $e');
    }
  }

  Future<void> startAudioRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'evidence_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final path = '${dir.path}/$fileName';
        
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
        _isRecordingAudio = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error starting audio recording: $e');
    }
  }

  Future<void> stopAudioRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecordingAudio = false;
      if (path != null) {
        // Calculate duration simple way
        await _saveEvidence(type: 'Audio', filePath: path);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping audio recording: $e');
      _isRecordingAudio = false;
      notifyListeners();
    }
  }

  Future<void> _saveEvidence({
    required String type,
    required String filePath,
    String? duration,
    bool isSOS = false,
  }) async {
    final evidence = Evidence(
      id: _uuid.v4(),
      type: type,
      filePath: filePath,
      timestamp: DateTime.now(),
      duration: duration ?? (type == 'Photo' ? '—' : '0:00'),
      isSOS: isSOS,
    );

    final box = Hive.box<Evidence>(LocalStorageService.evidenceBoxName);
    await box.put(evidence.id, evidence);
    _evidenceList.insert(0, evidence);
    notifyListeners();
  }
}
