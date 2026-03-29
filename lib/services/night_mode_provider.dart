import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio;
import 'dart:io' show Platform;
import 'night_mode_service.dart';
import 'api_config.dart';

class NightModeState {
  final bool isActive;                    // is it currently night mode hours
  final bool isManuallyEnabled;           // user forced it on manually
  final bool buddyTrackEnabled;           // tracking shared with contact
  final String? buddyContactName;
  final String? buddyContactPhone;
  final bool checkInEnabled;              // periodic check-ins active
  final int checkInIntervalMinutes;       // current check-in interval
  final DateTime? lastCheckIn;
  final DateTime? nextCheckInDue;
  final bool checkInOverdue;              // true if missed check-in
  final double nightRiskScore;            // current night-adjusted risk
  final String nightRiskLevel;
  final bool sosBroadcastEnabled;         // auto-SOS if check-in missed
  final List<String> nightAlerts;         // list of active night warnings
  final bool showNightOverlay;            // map overlay visible
  final int minutesUntilModeChange;       // time until day/night switches

  const NightModeState({
    this.isActive = false,
    this.isManuallyEnabled = false,
    this.buddyTrackEnabled = false,
    this.buddyContactName,
    this.buddyContactPhone,
    this.checkInEnabled = false,
    this.checkInIntervalMinutes = 15,
    this.lastCheckIn,
    this.nextCheckInDue,
    this.checkInOverdue = false,
    this.nightRiskScore = 0,
    this.nightRiskLevel = 'low',
    this.sosBroadcastEnabled = false,
    this.nightAlerts = const [],
    this.showNightOverlay = true,
    this.minutesUntilModeChange = 0,
  });

  bool get isEffectivelyActive => isActive || isManuallyEnabled;

  NightModeState copyWith({
    bool? isActive,
    bool? isManuallyEnabled,
    bool? buddyTrackEnabled,
    String? buddyContactName,
    String? buddyContactPhone,
    bool? checkInEnabled,
    int? checkInIntervalMinutes,
    DateTime? lastCheckIn,
    DateTime? nextCheckInDue,
    bool? checkInOverdue,
    double? nightRiskScore,
    String? nightRiskLevel,
    bool? sosBroadcastEnabled,
    List<String>? nightAlerts,
    bool? showNightOverlay,
    int? minutesUntilModeChange,
  }) {
    return NightModeState(
      isActive: isActive ?? this.isActive,
      isManuallyEnabled: isManuallyEnabled ?? this.isManuallyEnabled,
      buddyTrackEnabled: buddyTrackEnabled ?? this.buddyTrackEnabled,
      buddyContactName: buddyContactName ?? this.buddyContactName,
      buddyContactPhone: buddyContactPhone ?? this.buddyContactPhone,
      checkInEnabled: checkInEnabled ?? this.checkInEnabled,
      checkInIntervalMinutes: checkInIntervalMinutes ?? this.checkInIntervalMinutes,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      nextCheckInDue: nextCheckInDue ?? this.nextCheckInDue,
      checkInOverdue: checkInOverdue ?? this.checkInOverdue,
      nightRiskScore: nightRiskScore ?? this.nightRiskScore,
      nightRiskLevel: nightRiskLevel ?? this.nightRiskLevel,
      sosBroadcastEnabled: sosBroadcastEnabled ?? this.sosBroadcastEnabled,
      nightAlerts: nightAlerts ?? this.nightAlerts,
      showNightOverlay: showNightOverlay ?? this.showNightOverlay,
      minutesUntilModeChange: minutesUntilModeChange ?? this.minutesUntilModeChange,
    );
  }
}

class NightModeProvider with ChangeNotifier {
  final _nightService = NightModeService();
  NightModeState _state = const NightModeState();
  
  Timer? _checkInTimer;
  Timer? _modeCheckTimer;
  Timer? _riskRefreshTimer;
  
  final dio.Dio _dio = dio.Dio(dio.BaseOptions(
    connectTimeout: const Duration(seconds: 180),
    receiveTimeout: const Duration(seconds: 180),
  ));

  static String get _backendUrl => ApiConfig.baseUrl;

  NightModeState get state => _state;

  NightModeProvider() {
    _initialize();
  }

  void _initialize() {
    // Check current time and set initial state
    _updateModeFromTime();

    // Check every minute if mode should change
    _modeCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateModeFromTime();
      _updateMinutesUntilChange();
    });

    // Refresh risk every 5 minutes when active
    _riskRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_state.isEffectivelyActive) _refreshNightRisk();
    });
  }

  void _updateModeFromTime() {
    final active = _nightService.isNightModeActive();
    if (active != _state.isActive) {
      _state = _state.copyWith(isActive: active);
      if (active) {
        _onNightModeStart();
      } else {
        _onDayModeStart();
      }
      notifyListeners();
    }
  }

  void _onNightModeStart() {
    // Auto-add tip to alerts
    _state = _state.copyWith(
      nightAlerts: [_nightService.getNightSafetyTip(), ..._state.nightAlerts],
    );
    notifyListeners();
  }

  void _onDayModeStart() {
    // Clear night alerts, stop check-in timer
    _state = _state.copyWith(nightAlerts: []);
    _stopCheckIn();
    notifyListeners();
  }

  void toggleManualMode() {
    _state = _state.copyWith(isManuallyEnabled: !_state.isManuallyEnabled);
    notifyListeners();
  }

  // BUDDY TRACK: share live location with trusted contact
  void enableBuddyTrack(String contactName, String contactPhone) {
    _state = _state.copyWith(
      buddyTrackEnabled: true,
      buddyContactName: contactName,
      buddyContactPhone: contactPhone,
    );
    _startBuddyLocationSharing();
    notifyListeners();
  }

  void disableBuddyTrack() {
    _state = _state.copyWith(
      buddyTrackEnabled: false, 
      buddyContactName: null, 
      buddyContactPhone: null
    );
    notifyListeners();
  }

  void _startBuddyLocationSharing() async {
    // In production: share location link via SMS (MSG91)
    debugPrint('[NightMode] Buddy track started for ${_state.buddyContactName}');
    
    try {
      await _dio.post('$_backendUrl/api/night-mode/buddy-track', data: {
        'userId': 'user_123', // Mock ID
        'contactName': _state.buddyContactName,
        'contactPhone': _state.buddyContactPhone,
        'status': 'started',
      });
    } catch (e) {
      debugPrint('[NightMode] Backend Buddy Track Error: $e');
    }
  }


  // CHECK-IN SYSTEM
  void startCheckIn({required int intervalMinutes, required bool autoSOS}) {
    _stopCheckIn();
    final nextDue = DateTime.now().add(Duration(minutes: intervalMinutes));
    _state = _state.copyWith(
      checkInEnabled: true,
      checkInIntervalMinutes: intervalMinutes,
      lastCheckIn: DateTime.now(),
      nextCheckInDue: nextDue,
      sosBroadcastEnabled: autoSOS,
      checkInOverdue: false,
    );

    _checkInTimer = Timer.periodic(Duration(minutes: intervalMinutes), (_) {
      _onCheckInDue();
    });
    notifyListeners();
  }

  void performCheckIn() async {
    final nextDue = DateTime.now().add(Duration(minutes: _state.checkInIntervalMinutes));
    _state = _state.copyWith(
      lastCheckIn: DateTime.now(),
      nextCheckInDue: nextDue,
      checkInOverdue: false,
    );
    debugPrint('[NightMode] Check-in confirmed at ${DateTime.now()}');
    notifyListeners();

    try {
      await _dio.post('$_backendUrl/api/night-mode/check-in', data: {
        'userId': 'user_123',
        'lat': 19.9975, // These should come from location service ideally
        'lng': 73.7898,
        'type': 'routine',
      });
    } catch (e) {
      debugPrint('[NightMode] Backend Check-in Error: $e');
    }
  }

  void _onCheckInDue() {
    _state = _state.copyWith(checkInOverdue: true);
    notifyListeners();
    
    // Notify trusted contacts via SMS (Mocked)
    if (_state.sosBroadcastEnabled) {
      // Auto-trigger SOS after 2-minute grace period
      Future.delayed(const Duration(minutes: 2), () {
        if (_state.checkInOverdue) {
          debugPrint('[NightMode] AUTO-SOS triggered due to missed check-in');
          // Trigger SOS logic would go here
        }
      });
    }
  }

  void _stopCheckIn() {
    _checkInTimer?.cancel();
    _state = _state.copyWith(checkInEnabled: false, checkInOverdue: false);
    notifyListeners();
  }

  void updateNightRisk(double score, String level) {
    _state = _state.copyWith(nightRiskScore: score, nightRiskLevel: level);
    notifyListeners();
  }

  void addNightAlert(String alert) {
    _state = _state.copyWith(
      nightAlerts: [alert, ..._state.nightAlerts].take(5).toList(),
    );
    notifyListeners();
  }

  void toggleOverlay() {
    _state = _state.copyWith(showNightOverlay: !_state.showNightOverlay);
    notifyListeners();
  }

  void _updateMinutesUntilChange() {
    final mins = _state.isActive
      ? _nightService.minutesUntilDayMode()
      : _nightService.minutesUntilNightMode();
    _state = _state.copyWith(minutesUntilModeChange: mins);
    notifyListeners();
  }

  void _refreshNightRisk() async {
    // Mock risk refresh logic
    debugPrint('[NightMode] Risk refreshed');
  }

  @override
  void dispose() {
    _checkInTimer?.cancel();
    _modeCheckTimer?.cancel();
    _riskRefreshTimer?.cancel();
    super.dispose();
  }
}
