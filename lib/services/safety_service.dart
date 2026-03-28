import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/safety_models.dart';
import 'blockchain_service.dart';
import 'supabase_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:telephony/telephony.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:screen_state/screen_state.dart';
import 'night_mode_service.dart';

class SafetyService extends ChangeNotifier {
  static late SafetyService instance;

  // Current user location (simulated for demo)
  double _currentLat = 19.9975;
  double _currentLng = 73.7898;
  bool _isSOSActive = false;
  bool _isTripActive = false;
  bool _isFakeCallActive = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isAICompanionActive = false;
  
  // SOS Trigger States
  bool _voiceTriggerEnabled = false; // Disabled by default to prevent automatic recording 
  bool _powerTriggerEnabled = true;
  
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final Screen _screen = Screen();

  DateTime? _lastScreenEvent;
  int _screenToggleCount = 0;
  
  bool get voiceTriggerEnabled => _voiceTriggerEnabled;
  bool get powerTriggerEnabled => _powerTriggerEnabled;

  int _riskScore = 32;
  String _riskLevel = 'Moderate';
  Timer? _locationTimer;
  Timer? _riskTimer;
  Timer? _anomalyTimer;
  
  final List<EmergencyContact> _emergencyContacts = [];

  // Community Reports
  final List<SafetyReport> _communityReports = [];


  final List<String> _sosLog = [];
  TripSession? _currentTrip;
  RiskAssessment? _currentRiskAssessment;
  
  // Anomaly detection state
  bool _anomalyDetected = false;
  String _anomalyType = '';
  int _currentInstructionIndex = 0;
  bool _dangerZoneAlert = false;
  String _dangerZoneName = '';
  double _currentSpeedKmh = 0;
  double _distanceRemainingKm = 0;
  int _etaMinutes = 0;
  double _distanceToNextTurnM = 0;
  
  // Getters
  double get currentLat => _currentLat;
  double get currentLng => _currentLng;
  bool get isSOSActive => _isSOSActive;
  bool get isTripActive => _isTripActive;
  bool get isFakeCallActive => _isFakeCallActive;
  bool get isAICompanionActive => _isAICompanionActive;
  int get riskScore => _riskScore;
  String get riskLevel => _riskLevel;
  List<EmergencyContact> get emergencyContacts => _emergencyContacts;
  List<SafetyReport> get communityReports => _communityReports;
  List<String> get sosLog => _sosLog;
  TripSession? get currentTrip => _currentTrip;
  RiskAssessment? get currentRiskAssessment => _currentRiskAssessment;
  bool get anomalyDetected => _anomalyDetected;
  String get anomalyType => _anomalyType;
  int get currentInstructionIndex => _currentInstructionIndex;
  bool get dangerZoneAlert => _dangerZoneAlert;
  String get dangerZoneName => _dangerZoneName;
  
  NavigationInstruction? get currentInstruction {
    if (_currentTrip == null || _currentTrip!.instructions.isEmpty) return null;
    if (_currentInstructionIndex >= _currentTrip!.instructions.length) return null;
    return _currentTrip!.instructions[_currentInstructionIndex];
  }

  double get currentSpeedKmh => _currentSpeedKmh;
  double get distanceRemainingKm => _distanceRemainingKm;
  int get etaMinutes => _etaMinutes;
  double get distanceToNextTurnM => _distanceToNextTurnM;

  BlockchainService? _blockchainService;
  void updateBlockchainService(BlockchainService service) {
    _blockchainService = service;
  }

  String? _userName;
  String? _userEmail;
  String? _currentSOSId; 
  DateTime? _lastDbLocationUpdate;
  void updateUserContext(String name, String email) {
    if (_userEmail == email && (_userName == name || name.isEmpty)) return;
    if (name.isNotEmpty) _userName = name;
    _userEmail = email;
    fetchContacts(); // Fetch contacts whenever user context changes
    
    // If name is still missing but we have email, try a quick fetch from Supabase
    if ((_userName == null || _userName!.isEmpty || _userName == 'Unknown User') && _userEmail != null) {
      Supabase.instance.client
          .from('users')
          .select('name')
          .eq('email', _userEmail!)
          .maybeSingle()
          .then((data) {
        if (data != null && data['name'] != null) {
          _userName = data['name'];
          notifyListeners();
        }
      });
    }
    
    // Initialize triggers
    _initVoiceTrigger();
    _initPowerButtonTrigger();
  }

  void toggleVoiceTrigger(bool enabled) {
    _voiceTriggerEnabled = enabled;
    if (enabled) {
      _startVoiceListening();
    } else {
      _speechToText.stop();
    }
    notifyListeners();
  }

  void togglePowerTrigger(bool enabled) {
    _powerTriggerEnabled = enabled;
    notifyListeners();
  }

  Future<void> _initVoiceTrigger() async {
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_voiceTriggerEnabled && !_isSOSActive) {
            _startVoiceListening(); // Keep listening
          }
        }
      },
      onError: (error) => debugPrint('Speech Error: $error'),
    );
    if (available && _voiceTriggerEnabled) {
      _startVoiceListening();
    }
  }

  void _startVoiceListening() {
    if (!_voiceTriggerEnabled || _isSOSActive) return;
    _speechToText.listen(
      onResult: (result) {
        String spoke = result.recognizedWords.toLowerCase();
        if (spoke.contains('help') || spoke.contains('emergency') || spoke.contains('danger')) {
          debugPrint('Voice trigger detected: $spoke. Activating SOS...');
          activateSOS();
        }
      },
    );
  }

  void _initPowerButtonTrigger() {
    _screen.screenStateStream.listen((event) {
      if (!_powerTriggerEnabled || _isSOSActive) return;
      
      final now = DateTime.now();
      if (_lastScreenEvent == null || now.difference(_lastScreenEvent!).inSeconds > 5) {
        _screenToggleCount = 1;
      } else {
        _screenToggleCount++;
      }
      _lastScreenEvent = now;

      debugPrint('Screen toggle count: $_screenToggleCount');
      if (_screenToggleCount >= 5) { // 5 toggles roughly equals 3 power presses (on-off-on-off-on)
        debugPrint('Power button sequence detected! Activating SOS...');
        activateSOS();
        _screenToggleCount = 0;
      }
    });
  }

  Future<void> fetchContacts() async {
    if (_userEmail == null) {
      debugPrint('Skipping fetchContacts: No userEmail set');
      return;
    }
    
    debugPrint('Fetching emergency contacts for: $_userEmail');
    try {
      final List<dynamic> data = await Supabase.instance.client
          .from('contacts')
          .select()
          .eq('user_email', _userEmail!);

      debugPrint('Supabase: Found ${data.length} emergency contacts');
      _emergencyContacts.clear();
      for (var item in data) {
        _emergencyContacts.add(EmergencyContact(
          id: item['id'].toString(),
          name: item['name'] ?? 'Unknown',
          phone: item['phone'] ?? '',
          relationship: item['relation'] ?? 'Family',
          isPrimary: _emergencyContacts.isEmpty,
        ));
      }
      
      if (_emergencyContacts.isNotEmpty) {
        _sosLog.insert(0, '📋 Loaded ${_emergencyContacts.length} trusted contacts');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Supabase Error (fetchContacts): $e');
    }
  }

  SafetyService() {
    instance = this;
    _initializeService();
    fetchCommunityReports();
  }

  void _initializeService() {
    // Start real GPS location stream
    _startRealGPS();

    // Subscribe to real-time incidents
    _subscribeToIncidents();

    // Update risk assessment periodically
    _riskTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateRiskAssessment();
    });

    // Initial risk assessment
    _updateRiskAssessment();
  }

  StreamSubscription<Position>? _positionStream;

  Future<void> _startRealGPS() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services disabled, using default coords');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied forever');
        return;
      }

      // Get initial position immediately
      final pos = await Geolocator.getCurrentPosition();
      _currentLat = pos.latitude;
      _currentLng = pos.longitude;
      _checkDangerZones();
      _checkPathDivergence();
      notifyListeners();

      // Then stream continuous updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 2,
        ),
      ).listen((Position position) {
        // Use updateLocation to trigger all side effects (risk, divergence, live tracking)
        updateLocation(position.latitude, position.longitude);
        
        // Update speed and nav stats which are trip-specific
        _currentSpeedKmh = (position.speed >= 0) ? position.speed * 3.6 : 0;
        _updateNavStats();
        
        if (_isTripActive && _currentTrip != null && _currentTrip!.instructions.isNotEmpty) {
          final nextIdx = _currentInstructionIndex + 1;
          if (nextIdx < _currentTrip!.path.length) {
            final nextPt = _currentTrip!.path[nextIdx];
            final dist = _calculateDistance(_currentLat, _currentLng, nextPt.latitude, nextPt.longitude);
            if (dist < 0.03) { // within 30m
              _currentInstructionIndex = nextIdx;
            }
          }
        }
      });
    } catch (e) {
      debugPrint('GPS stream error: $e');
    }
  }

  Future<void> fetchCommunityReports() async {
    try {
      final data = await Supabase.instance.client
          .from('incidents')
          .select()
          .order('created_at', ascending: false);

      _communityReports.clear();
      for (var item in data) {
        _communityReports.add(_mapToSafetyReport(item));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Supabase Error (fetchCommunityReports): $e');
    }
  }

  SafetyReport _mapToSafetyReport(Map<String, dynamic> item) {
    return SafetyReport(
      id: item['id'].toString(),
      userId: item['source'] ?? 'system',
      lat: (item['lat'] as num).toDouble(),
      lng: (item['lng'] as num).toDouble(),
      type: item['type'] != null ? _capitalize(item['type']) : 'Unknown',
      description: item['description'] ?? '',
      timestamp: DateTime.parse(item['created_at']),
      upvotes: item['risk_score'] ?? 0,
      isVerified: item['verified'] ?? false,
    );
  }

  void _subscribeToIncidents() {
    Supabase.instance.client
        .channel('public:incidents')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'incidents',
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              final newReport = _mapToSafetyReport(payload.newRecord);
              
              // Handle Insert
              if (payload.eventType == PostgresChangeEvent.insert) {
                // To avoid duplication with optimistic updates, check if ID exists
                if (!_communityReports.any((r) => r.id == newReport.id)) {
                  _communityReports.insert(0, newReport);
                }
              } 
              // Handle Update (verification)
              else if (payload.eventType == PostgresChangeEvent.update) {
                final idx = _communityReports.indexWhere((r) => r.id == newReport.id);
                if (idx != -1) {
                  _communityReports[idx] = newReport;
                }
              }
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();


  void _checkDangerZones() {
    final hotspots = SafetyModels.getCrimeHotspots();
    bool foundDanger = false;
    for (var hotspot in hotspots) {
      double dist = _calculateDistance(_currentLat, _currentLng, hotspot.lat, hotspot.lng);
      if (dist < 0.5 && hotspot.intensity > 0.75) { // Within 500m of high risk
        _dangerZoneAlert = true;
        _dangerZoneName = hotspot.area;
        foundDanger = true;
        break;
      }
    }
    if (!foundDanger) {
      _dangerZoneAlert = false;
      _dangerZoneName = '';
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const p = 0.017453292519943295;
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lng2 - lng1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  void _updateNavStats() {
    if (!_isTripActive || _currentTrip == null || _currentTrip!.path.isEmpty) {
      _distanceRemainingKm = 0;
      _etaMinutes = 0;
      _distanceToNextTurnM = 0;
      return;
    }

    final path = _currentTrip!.path;
    // Find the closest waypoint index on the route
    int closestIdx = 0;
    double closestDist = double.infinity;
    for (int i = 0; i < path.length; i++) {
      final d = _calculateDistance(_currentLat, _currentLng, path[i].latitude, path[i].longitude);
      if (d < closestDist) {
        closestDist = d;
        closestIdx = i;
      }
    }

    // Sum remaining path distance from closest waypoint to destination
    double remaining = 0;
    for (int i = closestIdx; i < path.length - 1; i++) {
      remaining += _calculateDistance(
        path[i].latitude, path[i].longitude,
        path[i + 1].latitude, path[i + 1].longitude,
      );
    }
    _distanceRemainingKm = remaining;

    // ETA: remaining_km / speed_km_h * 60, fallback 50 km/h average
    final speed = _currentSpeedKmh > 3 ? _currentSpeedKmh : 50.0;
    _etaMinutes = remaining > 0 ? (remaining / speed * 60).round() : 0;

    // Distance to next turn: use the instruction index waypoint in path
    final nextTurnIdx = _currentInstructionIndex + 1;
    if (nextTurnIdx < path.length) {
      _distanceToNextTurnM = _calculateDistance(
        _currentLat, _currentLng,
        path[nextTurnIdx].latitude, path[nextTurnIdx].longitude,
      ) * 1000; // km -> m
    } else {
      _distanceToNextTurnM = 0;
    }
  }

  void _checkPathDivergence() {
    if (!_isTripActive || _currentTrip == null || _currentTrip!.path.isEmpty) return;
    
    double minDistance = double.infinity;
    for (var point in _currentTrip!.path) {
      double dist = _calculateDistance(_currentLat, _currentLng, point.latitude, point.longitude);
      if (dist < minDistance) minDistance = dist;
    }
    
    // If user is more than 150m away from the path, trigger alert
    bool isDiverged = minDistance > 0.15; 
    if (isDiverged != _currentTrip!.isOffRoute) {
      _currentTrip!.isOffRoute = isDiverged;
      if (isDiverged) {
        simulateAnomaly('Route Deviation');
      }
      notifyListeners();
    }
  }

  Future<void> fetchLiveLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      updateLocation(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error fetching location: $e');
    }
  }

  void _updateRiskAssessment() {
    _currentRiskAssessment = RiskAssessment.calculate(
      lat: _currentLat,
      lng: _currentLng,
      time: DateTime.now(),
    );
    
    double baseScore = _currentRiskAssessment!.overallScore;
    
    // Apply Night Mode Multiplier
    final nightService = NightModeService();
    if (nightService.isNightModeActive()) {
      baseScore = nightService.calculateNightRisk(
        baseRiskScore: baseScore,
        nearbyIncidents: _communityReports.map((r) => {'type': r.type.toLowerCase()}).toList(),
        isIsolatedArea: _currentSpeedKmh < 2.0,
        hasStreetLights: true,
      );
    }
    
    _riskScore = baseScore.round().clamp(0, 100);
    _riskLevel = _getNightRiskLevelLabel(_riskScore);
    notifyListeners();

    // Async ML zone prediction — blends result when available
    _fetchMLZonePrediction(baseScore);
  }

  /// Fetches ML-powered zone risk prediction from the backend and blends it
  /// with the local risk score. Falls back silently if the service is unavailable.
  Future<void> _fetchMLZonePrediction(double localScore) async {
    try {
      final baseUrl = (kIsWeb)
          ? 'http://localhost:3000'
          : (Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://127.0.0.1:3000');

      final dioClient = dio.Dio(dio.BaseOptions(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ));

      final response = await dioClient.post(
        '$baseUrl/api/zones/predict',
        data: {
          'locations': [
            {'latitude': _currentLat, 'longitude': _currentLng}
          ],
          'time_of_day_hour': DateTime.now().hour,
          'day_of_week': DateTime.now().weekday % 7,
          'is_weekend': (DateTime.now().weekday >= 6) ? 1 : 0,
        },
      );

      if (response.data != null &&
          response.data['predictions'] != null &&
          (response.data['predictions'] as List).isNotEmpty) {
        final pred = response.data['predictions'][0];
        final mlScore = ((pred['risk_score'] ?? 0.0) as num).toDouble() * 100;

        // Blend: 60% local + 40% ML
        final blended = (localScore * 0.6 + mlScore * 0.4).round().clamp(0, 100);
        _riskScore = blended;
        _riskLevel = _getNightRiskLevelLabel(_riskScore);
        notifyListeners();
      }
    } catch (e) {
      // ML service unavailable — keep local score, no crash
      debugPrint('[ML] Zone prediction unavailable: $e');
    }
  }


  String _getNightRiskLevelLabel(int score) {
    if (score >= 75) return 'Critical';
    if (score >= 50) return 'High';
    if (score >= 25) return 'Moderate';
    return 'Low';
  }

  // SOS Functions
  void activateSOS() {
    _isSOSActive = true;
    _sosLog.insert(0, '🆘 SOS Activated at ${DateTime.now().toString().substring(0, 19)}');
    _sosLog.insert(0, '📍 Location shared with emergency contacts');
    _sosLog.insert(0, '📱 SMS alerts sent to all contacts');
    
    // Trigger Native Automated SMS
    sendNativeSMSAlerts();
    
    // Trigger Backend Cloud SOS (Twilio Call + Admin Notification)
    _triggerCloudSOSRelay();
    
    // Start Audio Recording asynchronously
    _startSOSRecording();

    // 1. Log to Supabase IMMEDIATELY (Don't wait for blockchain)
    _performSupabaseLog(null);

    // 2. Log to Blockchain in background
    if (_blockchainService != null) {
      _blockchainService!.storeSOSOnBlockchain({
        'type': 'SOS_ACTIVATED',
        'timestamp': DateTime.now().toIso8601String(),
        'lat': _currentLat,
        'lng': _currentLng,
        'user_name': _userName ?? 'Unknown User',
      }).then((txHash) {
        if (txHash != null && _currentSOSId != null) {
          // Update the Supabase record with the blockchain hash if it arrives later
          Supabase.instance.client
              .from('sos_logs')
              .update({'blockchain_hash': txHash})
              .eq('id', _currentSOSId!)
              .then((_) => debugPrint('Supabase: Updated with blockchain hash'))
              .catchError((e) => debugPrint('Supabase Update Error: $e'));
        }
      });
    }
    
    notifyListeners();
  }

  Future<void> sendNativeSMSAlerts() async {
    final Telephony telephony = Telephony.instance;
    
    // Request permission explicitly before sending
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted == null || !permissionsGranted) {
      debugPrint('SMS permissions denied.');
      _sosLog.insert(0, '⚠️ SMS Permission denied. Contacts not alerted.');
      notifyListeners();
      return;
    }

    final locationUrl = 'https://maps.google.com/?q=$_currentLat,$_currentLng';
    final message = '🚨 SOS EMERGENCY 🚨 ${_userName ?? "A user"} needs help! Live location: $locationUrl';
    
    if (_emergencyContacts.isEmpty) {
      debugPrint('No emergency contacts to alert via SMS.');
      _sosLog.insert(0, '⚠️ No emergency contacts found.');
      notifyListeners();
    } else {
      // 1. Background SMS (Silent - using telephony)
      for (var contact in _emergencyContacts) {
        if (contact.phone.isEmpty) continue;
        try {
          await telephony.sendSms(
            to: contact.phone,
            message: message,
          );
          debugPrint('Background SMS hit for ${contact.name}');
        } catch (e) {
          debugPrint('Background SMS Error for ${contact.name}: $e');
        }
      }

      // 2. Open Native SMS Application with ALL recipients pre-filled as a chat group
      // Multi-recipient SMS URIs use a comma separator on most devices
      final String recipients = _emergencyContacts.map((c) => c.phone.trim()).join(',');
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: recipients,
        queryParameters: {'body': message},
      );

      try {
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri, mode: LaunchMode.externalApplication);
          debugPrint('Native SMS app opened with recipients: $recipients');
        } else {
          debugPrint('Cannot launch SMS app.');
        }
      } catch (e) {
        debugPrint('Error launching native SMS: $e');
      }
      
      _sosLog.insert(0, '✅ SMS alerts sent and messenger opened.');
      notifyListeners();
    }
  }

  Future<void> _triggerCloudSOSRelay() async {
    try {
      if (_emergencyContacts.isEmpty) return;
      
      final data = {
        'userName': _userName ?? 'Unknown User',
        'phone': 'N/A', // Could fetch from user profile if needed
        'emergencyContacts': _emergencyContacts.map((c) => {
          'name': c.name,
          'phone': c.phone,
        }).toList(),
      };

      await _dio.post(
        '$_backendUrl/api/sos/trigger',
        data: data,
      );
      debugPrint('Cloud SOS Relay Triggered');
    } catch (e) {
      debugPrint('Cloud SOS Relay Error: $e');
    }
  }

  void _performSupabaseLog(String? txHash) {
    if (_userEmail != null) {
      _sosLog.insert(0, '☁️ Syncing with Safety Cloud...');
      notifyListeners();
      
      SupabaseService.logSOSEvent(
        userEmail: _userEmail!,
        userName: _userName ?? 'Unknown User',
        type: 'Crime',
        latitude: _currentLat,
        longitude: _currentLng,
        meshPath: ['Device_A', 'Gateway_Main'],
        blockchainHash: txHash,
      ).then((result) {
        if (result['success'] == true) {
          _currentSOSId = result['id'];
          _sosLog.insert(0, '✅ Cloud Sync Active (Live Tracking On)');
        } else {
          final error = result['error'] ?? 'Unknown Error';
          _sosLog.insert(0, '❌ Sync Failed: $error');
          debugPrint('Supabase Error: $error');
        }
        notifyListeners();
      });
    } else {
      _sosLog.insert(0, '⚠️ User session not found. Cloud sync disabled.');
      notifyListeners();
    }
  }

  void deactivateSOS() {
    _isSOSActive = false;
    _sosLog.insert(0, '✅ SOS Deactivated at ${DateTime.now().toString().substring(0, 19)}');
    notifyListeners();
    // Stop recording and upload
    _stopSOSRecordingAndUpload().then((_) {
      _currentSOSId = null;
    });
  }

  Future<void> _startSOSRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/sos_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
        _sosLog.insert(0, '🎙️ Audio recording started');
        notifyListeners();
      } else {
        _sosLog.insert(0, '⚠️ Audio recording permission denied');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Audio recording error: $e');
    }
  }

  Future<void> _stopSOSRecordingAndUpload() async {
    try {
      if (await _audioRecorder.isRecording()) {
        final path = await _audioRecorder.stop();
        if (path != null) {
          int retries = 0;
          while (_currentSOSId == null && retries < 10) {
            await Future.delayed(const Duration(milliseconds: 500));
            retries++;
          }
          if (_currentSOSId != null) {
            _sosLog.insert(0, '🎙️ Audio stopped, uploading securely...');
            notifyListeners();
            final formData = dio.FormData.fromMap({
              'logId': _currentSOSId,
              'audio': await dio.MultipartFile.fromFile(
                path, 
                filename: 'sos_audio.m4a',
              ),
            });
            await _dio.post(
              '$_backendUrl/api/blockchain/sos/audio',
              data: formData,
            );
            _sosLog.insert(0, '✅ Audio evidence uploaded to dashboard');
            notifyListeners();
          } else {
            _sosLog.insert(0, '⚠️ Could not upload audio (No SOS ID from DB)');
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Audio upload error: $e');
      _sosLog.insert(0, '❌ Audio upload failed: ${e.toString().split('\n').first}');
      notifyListeners();
    }
  }

  // Trip Monitoring
  final dio.Dio _dio = dio.Dio(dio.BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  
  static String get _backendUrl {
    if (kIsWeb) return 'http://localhost:3000';
    // Using localhost with 'adb reverse tcp:3000 tcp:3000' for physical devices.
    return 'http://localhost:3000';
  }


  Future<String?> startTrip(String destination, {String? origin}) async {
    try {
      final response = await _dio.post(
        '$_backendUrl/api/routes/safest',
        data: {
          'origin': origin != null && origin.isNotEmpty ? origin : '$_currentLat,$_currentLng',
          'destination': destination,
        },
        options: dio.Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.data['success'] == true) {
        final data = response.data['safestRoute'];

        final List<LatLng> path = (data['path'] as List).map((p) =>
          LatLng((p['latitude'] as num).toDouble(), (p['longitude'] as num).toDouble())
        ).toList();

        final List<NavigationInstruction> instructions = (data['instructions'] as List).map((i) =>
          NavigationInstruction(
            instruction: i['instruction'] ?? '',
            distance: i['distance'] ?? '',
            icon: _getIconForInstruction(i['instruction'] ?? ''),
            isSafeZone: i['isSafeZone'] ?? true,
          )
        ).toList();

        _currentTrip = TripSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          startTime: DateTime.now(),
          startLat: _currentLat,
          startLng: _currentLng,
          destination: destination,
          instructions: instructions,
          path: path,
          distanceKm: data['distanceKm']?.toString() ?? '',
          durationMin: (data['durationMin'] as num?)?.toInt() ?? 0,
        );
        _isTripActive = true;
        _currentInstructionIndex = 0;
        
        // Initialize stats immediately
        _updateNavStats();
        notifyListeners();

        if (response.data['status'] == 'Risky') {
          simulateAnomaly('Risky Route');
        }

        notifyListeners();
        return null; // success
      }
      return 'Route not found. Please try again.';
    } on dio.DioException catch (e) {
      debugPrint('GraphHopper trip error: $e');
      final msg = e.response?.data?['error'] ?? e.message ?? 'Network error';
      return msg.toString();
    } catch (e) {
      debugPrint('Unexpected trip error: $e');
      return e.toString();
    }
  }

  IconData _getIconForInstruction(String instruction) {
    final lower = instruction.toLowerCase();
    if (lower.contains('turn right')) return Icons.turn_right_rounded;
    if (lower.contains('turn left')) return Icons.turn_left_rounded;
    if (lower.contains('arrive')) return Icons.location_on_rounded;
    if (lower.contains('straight')) return Icons.straight_rounded;
    if (lower.contains('caution')) return Icons.warning_amber_rounded;
    return Icons.navigation_rounded;
  }




  void endTrip() {
    if (_currentTrip != null) {
      _currentTrip!.endTime = DateTime.now();
      _currentTrip!.isActive = false;
    }
    _isTripActive = false;
    _currentInstructionIndex = 0;
    _dangerZoneAlert = false;
    notifyListeners();
  }

  // Fake Call
  void triggerFakeCall() {
    _isFakeCallActive = true;
    notifyListeners();
  }

  void endFakeCall() {
    _isFakeCallActive = false;
    notifyListeners();
  }

  // AI Companion
  void toggleAICompanion() {
    _isAICompanionActive = !_isAICompanionActive;
    notifyListeners();
  }

  // Community Reports
  void addReport(SafetyReport report) async {
    // Optimistic UI update
    if (!_communityReports.any((r) => r.id == report.id)) {
      _communityReports.insert(0, report);
      notifyListeners();
    }
    
    // Sync to Supabase
    await SupabaseService.logIncident(
      title: report.type.toUpperCase(), // Using type as title for default
      type: report.type,
      severity: 'Medium',
      lat: report.lat,
      lng: report.lng,
      address: 'Reported Location',
      description: report.description,
      riskScore: 50,
      source: _userName ?? 'Mobile App',
    );
    
    // Refresh to get any server-side data
    fetchCommunityReports();
  }

  void upvoteReport(String reportId) {
    // In a real app, this would update the report's upvotes
    notifyListeners();
  }

  // Emergency Contacts
  Future<void> addEmergencyContact(EmergencyContact contact) async {
    _emergencyContacts.add(contact);
    notifyListeners();

    if (_userEmail != null) {
      await SupabaseService.syncContact(
        userEmail: _userEmail!,
        name: contact.name,
        phone: contact.phone,
        relation: contact.relationship,
      );
      // Re-fetch to get the real DB IDs and ensure consistency
      await fetchContacts();
    }
  }

  void removeEmergencyContact(String id) {
    _emergencyContacts.removeWhere((c) => c.id == id);
    notifyListeners();
    SupabaseService.deleteContact(id);
  }

  // Anomaly Detection
  void simulateAnomaly(String type) {
    _anomalyDetected = true;
    _anomalyType = type;
    notifyListeners();
    
    // Auto-clear after 10 seconds if not handled
    Future.delayed(const Duration(seconds: 10), () {
      if (_anomalyDetected) {
        _anomalyDetected = false;
        _anomalyType = '';
        notifyListeners();
      }
    });
  }

  void dismissAnomaly() {
    _anomalyDetected = false;
    _anomalyType = '';
    notifyListeners();
  }

  // Update location manually
  void updateLocation(double lat, double lng) {
    if (_currentLat == lat && _currentLng == lng) return;
    _currentLat = lat;
    _currentLng = lng;
    
    _updateRiskAssessment();
    _checkPathDivergence();
    
    // Push live tracking update if SOS is active
    if (_isSOSActive && _currentSOSId != null) {
      SupabaseService.updateSOSLocation(
        logId: _currentSOSId!,
        latitude: lat,
        longitude: lng,
      );
    }

    // Generic periodic location sync for Admin "Click-to-Track"
    if (_userEmail != null) {
      final now = DateTime.now();
      if (_lastDbLocationUpdate == null || now.difference(_lastDbLocationUpdate!).inSeconds > 60) {
        _lastDbLocationUpdate = now;
        SupabaseService.updateUserLocation(
          email: _userEmail!,
          lat: lat,
          lng: lng,
        );
      }
    }
    
    notifyListeners();
  }

  /// Searches for a place by name within the predefined SafePlaces.
  /// Returns the SafePlace if found, or null otherwise.
  SafePlace? searchPlace(String query) {
    if (query.isEmpty) return null;
    
    final normalizedQuery = query.toLowerCase().trim();
    final safePlaces = SafetyModels.getSafePlaces();
    
    try {
      return safePlaces.firstWhere(
        (place) => place.name.toLowerCase().contains(normalizedQuery) || 
                   place.typeLabel.toLowerCase().contains(normalizedQuery)
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _riskTimer?.cancel();
    _anomalyTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }
}
