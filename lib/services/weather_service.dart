import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class WeatherData {
  final double temp;
  final String condition;
  final String icon;
  final String city;
  final DateTime? dateTime;

  WeatherData({
    required this.temp,
    required this.condition,
    required this.icon,
    required this.city,
    this.dateTime,
  });
}

class WeatherService extends ChangeNotifier {
  final Dio _dio = Dio();

  WeatherData? _currentWeather;
  List<WeatherData> _forecast = [];
  bool _isLoading = false;
  String? _error;

  WeatherData? get currentWeather => _currentWeather;
  List<WeatherData> get forecast => _forecast;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Maps WMO weather codes to human-readable condition + icon id.
  static MapEntry<String, String> _wmoToCondition(int code) {
    // WMO Weather interpretation codes (WW)
    // https://open-meteo.com/en/docs#weathervariables
    if (code == 0) return const MapEntry('Clear', '01d');
    if (code == 1) return const MapEntry('Mostly Clear', '02d');
    if (code == 2) return const MapEntry('Partly Cloudy', '03d');
    if (code == 3) return const MapEntry('Overcast', '04d');
    if (code == 45 || code == 48) return const MapEntry('Foggy', '50d');
    if (code >= 51 && code <= 55) return const MapEntry('Drizzle', '09d');
    if (code >= 56 && code <= 57) return const MapEntry('Freezing Drizzle', '09d');
    if (code >= 61 && code <= 65) return const MapEntry('Rain', '10d');
    if (code >= 66 && code <= 67) return const MapEntry('Freezing Rain', '13d');
    if (code >= 71 && code <= 77) return const MapEntry('Snow', '13d');
    if (code >= 80 && code <= 82) return const MapEntry('Rain Showers', '09d');
    if (code >= 85 && code <= 86) return const MapEntry('Snow Showers', '13d');
    if (code == 95) return const MapEntry('Thunderstorm', '11d');
    if (code >= 96 && code <= 99) return const MapEntry('Thunderstorm', '11d');
    return const MapEntry('Unknown', '01d');
  }

  Future<void> fetchWeather(double lat, double lon) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Open-Meteo: free, no API key required
      final response = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'current': 'temperature_2m,weather_code',
          'daily': 'temperature_2m_max,weather_code',
          'timezone': 'auto',
          'forecast_days': 5,
        },
      );

      // --- Reverse Geocoding for City Name ---
      String cityName = '';
      try {
        final geoResponse = await _dio.get(
          'https://nominatim.openstreetmap.org/reverse',
          queryParameters: {
            'lat': lat,
            'lon': lon,
            'format': 'json',
            'addressdetails': 1,
            'accept-language': 'en',
          },
          options: Options(
            headers: {'User-Agent': 'NivaranApp/1.0'},
          )
        );
        if (geoResponse.statusCode == 200) {
          final address = geoResponse.data['address'];
          if (address != null) {
            cityName = address['suburb'] ??
                       address['neighbourhood'] ??
                       address['city_district'] ??
                       address['city'] ?? 
                       address['town'] ?? 
                       address['municipality'] ?? 
                       address['village'] ?? 
                       address['county'] ?? 
                       address['state_district'] ?? 
                       '';
          }
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Use detected city name, fallback to timezone if geocoding fails
        final String detectedCity = cityName.isNotEmpty 
            ? cityName 
            : (data['timezone']?.toString().split('/').last.replaceAll('_', ' ') ?? 'Location');

        // --- Current Weather ---
        final current = data['current'];
        final int currentCode = (current['weather_code'] as num).toInt();
        final currentCondition = _wmoToCondition(currentCode);

        _currentWeather = WeatherData(
          temp: (current['temperature_2m'] as num).toDouble(),
          condition: currentCondition.key,
          icon: currentCondition.value,
          city: detectedCity,
          dateTime: DateTime.tryParse(current['time'] ?? ''),
        );

        // --- 5-Day Forecast ---
        final daily = data['daily'];
        final List<String> times = List<String>.from(daily['time']);
        final List<num> temps = List<num>.from(daily['temperature_2m_max']);
        final List<num> codes = List<num>.from(daily['weather_code']);

        _forecast = [];
        for (int i = 0; i < times.length && i < 5; i++) {
          final cond = _wmoToCondition(codes[i].toInt());
          _forecast.add(WeatherData(
            temp: temps[i].toDouble(),
            condition: cond.key,
            icon: cond.value,
            city: _currentWeather!.city,
            dateTime: DateTime.tryParse(times[i]),
          ));
        }
      }
    } catch (e) {
      _error = 'Weather unavailable';
      debugPrint('Weather Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
