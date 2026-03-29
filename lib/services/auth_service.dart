import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'wallet_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io' show Platform;

class AuthService extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 180),
    receiveTimeout: const Duration(seconds: 180),
  ));
  
  static String get _baseUrl => ApiConfig.authUrl;
  final WalletService _walletService = WalletService();
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  String? _jwtToken;
  String? _currentUserEmail;
  bool get isAuthenticated => _jwtToken != null;
  String? get currentUserEmail => _currentUserEmail;
  String? get address => _walletService.address;
  bool get hasLocalWallet => _walletService.hasWallet;

  // Constructor handles auto-login if token & wallet exists
  AuthService() {
    _autoLogin();
  }

  Future<String?> _autoLogin() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      _jwtToken = token;
      final email = await _storage.read(key: 'user_email');
      _currentUserEmail = email;
      await _walletService.initWallet();
      // Even if wallet init fails, we have the token for now
      notifyListeners();
      return _currentUserEmail;
    }
    return null;
  }

  Future<String?> getSavedEmail() async {
    return await _storage.read(key: 'user_email');
  }

  Future<String?> signup(Map<String, dynamic> userData) async {
    try {
      // 1. Create a permanent wallet address for the user
      final address = await _walletService.createWallet();
      
      // 2. Register user mapping wallet to identity
      final data = {
        'wallet_address': address,
        ...userData,
      };

      final url = '$_baseUrl/signup';
      debugPrint('AuthService: POST to $url');
      final response = await _dio.post(url, data: data);
      
      if (response.statusCode == 200 && response.data['success']) {
        // Auto sign-in right after signup
        final email = await login();
        return email != null ? null : 'Failed to login after signup';
      }
      return response.data['error'] ?? 'Unknown backend error';
    } catch (e) {
      debugPrint('Signup error: $e');
      return e.toString();
    }
  }

  Future<String?> login() async {
    try {
      // 1. Check if wallet exists locally
      final hasWallet = await _walletService.initWallet();
      if (!hasWallet || _walletService.address == null) {
        debugPrint("No wallet found on device. Cannot login.");
        return null;
      }

      final address = _walletService.address!;

      // 2. Request Nonce
      final nonceUrl = '$_baseUrl/nonce';
      debugPrint('AuthService: POST to $nonceUrl');
      final nonceResponse = await _dio.post(nonceUrl, data: {'wallet_address': address});
      
      if (nonceResponse.statusCode != 200) return null;
      final nonce = nonceResponse.data['nonce'];

      // 3. Sign Nonce
      final signature = await _walletService.signMessage(nonce);
      if (signature == null) return null;

      // 4. Verify Signature & Get JWT
      final verifyUrl = '$_baseUrl/verify';
      debugPrint('AuthService: POST to $verifyUrl');
      final verifyResponse = await _dio.post(verifyUrl, data: {
        'wallet_address': address,
        'signature': signature,
      });

      if (verifyResponse.statusCode == 200 && verifyResponse.data['success']) {
        _jwtToken = verifyResponse.data['token'];
        final String userEmail = verifyResponse.data['user']['email'];
        _currentUserEmail = userEmail;
        await _storage.write(key: 'jwt_token', value: _jwtToken);
        await _storage.write(key: 'user_email', value: userEmail);
        notifyListeners();
        return userEmail;
      }
    } catch (e) {
      debugPrint('Login Verification error: $e');
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_email');
    _jwtToken = null;
    _currentUserEmail = null;
    notifyListeners();
  }
}
