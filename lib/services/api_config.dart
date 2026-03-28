import 'package:flutter/foundation.dart';

class ApiConfig {
  /// TODO: Replace this with your actual Render URL from the dashboard
  /// Example: 'https://nivaran-backend.onrender.com'
  static const String _renderUrl = 'https://nivaran-backend-1cun.onrender.com';
  
  static const String _localUrl = 'http://127.0.0.1:3000';

  /// Toggle this to false if you want to test with a local server
  static const bool useDeployedBackend = true;

  static String get baseUrl {
    if (useDeployedBackend) {
      return _renderUrl;
    }
    // For local development
    if (kIsWeb) return 'http://localhost:3000';
    return _localUrl;
  }

  // Helper getters for specific API paths
  static String get authUrl => '$baseUrl/api/auth';
  static String get blockchainUrl => '$baseUrl/api/blockchain';
  static String get routesUrl => '$baseUrl/api/routes';
  static String get sosUrl => '$baseUrl/api/sos';
  static String get nightModeUrl => '$baseUrl/api/night-mode';
  static String get zonesUrl => '$baseUrl/api/zones';
}
