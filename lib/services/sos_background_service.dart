import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Flutter interface for the native Android SOS background service.
///
/// Responsibilities:
///  - Start / stop the [SOSBackgroundService] Foreground Service
///  - Receive `onSOSTriggered` callbacks from native code (power button)
///    and forward them to [SafetyService.activateSOS()]
class SOSBackgroundServiceBridge extends ChangeNotifier {
  static const _channel = MethodChannel('com.safeher.safeher/sos_background');

  bool _serviceRunning = false;
  bool get serviceRunning => _serviceRunning;

  /// Callback executed when native code fires SOS
  VoidCallback? onSOSTriggered;

  SOSBackgroundServiceBridge() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onSOSTriggered':
        debugPrint('[SOSBridge] SOS triggered from native (background service)');
        onSOSTriggered?.call();
        break;
    }
  }

  /// Start the Android foreground service. Safe to call multiple times.
  Future<void> startService() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('startSOSService');
      _serviceRunning = true;
      notifyListeners();
      debugPrint('[SOSBridge] Background service started');
    } catch (e) {
      debugPrint('[SOSBridge] startSOSService error: $e');
    }
  }

  /// Stop the service (called from app settings if user opts out).
  Future<void> stopService() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('stopSOSService');
      _serviceRunning = false;
      notifyListeners();
      debugPrint('[SOSBridge] Background service stopped');
    } catch (e) {
      debugPrint('[SOSBridge] stopSOSService error: $e');
    }
  }

  /// Check whether the native service is currently running.
  Future<bool> checkRunning() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isServiceRunning');
      _serviceRunning = result ?? false;
      notifyListeners();
      return _serviceRunning;
    } catch (e) {
      return false;
    }
  }
}
