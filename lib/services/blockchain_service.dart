import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class BlockchainService extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  ));
  
  // Use 127.0.0.1 in combination with `adb reverse tcp:3000 tcp:3000`
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/blockchain';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/blockchain';
    return 'http://127.0.0.1:3000/api/blockchain';
  }
  
  bool _isVerifying = false;
  String? _lastTxHash;
  String? _lastKYCHash;
  bool _isUserVerified = false;
  List<String> _sosLogs = [];

  bool get isVerifying => _isVerifying;
  String? get lastTxHash => _lastTxHash;
  String? get lastKYCHash => _lastKYCHash;
  bool get isUserVerified => _isUserVerified;
  List<String> get sosLogs => _sosLogs;

  BlockchainService() {
    // Initial fetch of SOS logs if needed
    fetchSOSLogs();
  }

  Future<void> storeKYCOnBlockchain(Map<String, dynamic> userData) async {
    _isVerifying = true;
    notifyListeners();
    
    try {
      final response = await _dio.post('$_baseUrl/kyc', data: userData);
      if (response.statusCode == 200 && response.data['success']) {
        _lastTxHash = response.data['txHash'];
        _lastKYCHash = response.data['hash'];
        _isUserVerified = true;
      }
    } catch (e) {
      debugPrint('Blockchain KYC Error: $e');
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  Future<String?> storeSOSOnBlockchain(Map<String, dynamic> sosData) async {
    try {
      final response = await _dio.post('$_baseUrl/sos', data: sosData);
      if (response.statusCode == 200 && response.data['success']) {
        final txHash = response.data['txHash'];
        _sosLogs.insert(0, response.data['hash']);
        notifyListeners();
        return txHash;
      }
    } catch (e) {
      debugPrint('Blockchain SOS Error: $e');
    }
    return null;
  }

  Future<void> fetchSOSLogs() async {
    try {
      final response = await _dio.get('$_baseUrl/sos-logs');
      if (response.statusCode == 200 && response.data['success']) {
        _sosLogs = List<String>.from(response.data['logs']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Blockchain SOS Logs Fetch Error: $e');
    }
  }
}
