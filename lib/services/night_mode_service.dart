import 'package:flutter/material.dart';

class NightModeService {
  // Singleton
  static final NightModeService _instance = NightModeService._internal();
  factory NightModeService() => _instance;
  NightModeService._internal();

  // Night hours: 20:00 (8 PM) to 06:00 (6 AM)
  static const int nightStartHour = 20;
  static const int nightEndHour = 6;

  // Risk multipliers applied at night
  static const double riskMultiplierNight = 2.2;       // base incidents weigh 2.2x more
  static const double riskMultiplierIsolated = 1.8;    // low foot traffic areas
  static const double riskMultiplierUnlit = 1.5;       // areas without streetlights

  bool isNightModeActive() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= nightStartHour || hour < nightEndHour;
  }

  // Returns minutes until night mode activates (or 0 if already active)
  int minutesUntilNightMode() {
    final now = DateTime.now();
    if (isNightModeActive()) return 0;
    
    DateTime tonightStart = DateTime(now.year, now.month, now.day, nightStartHour);
    if (now.isAfter(tonightStart)) {
      tonightStart = tonightStart.add(const Duration(days: 1));
    }
    
    return tonightStart.difference(now).inMinutes;
  }

  // Returns minutes until night mode ends (or 0 if not active)
  int minutesUntilDayMode() {
    final now = DateTime.now();
    if (!isNightModeActive()) return 0;
    
    DateTime morningEnd;
    if (now.hour >= nightStartHour) {
      morningEnd = DateTime(now.year, now.month, now.day + 1, nightEndHour);
    } else {
      morningEnd = DateTime(now.year, now.month, now.day, nightEndHour);
    }
    
    return morningEnd.difference(now).inMinutes;
  }

  // Night-weighted risk score calculation
  // Takes base score (0-100) and returns night-adjusted score (0-100)
  double calculateNightRisk({
    required double baseRiskScore,
    required List<Map> nearbyIncidents,
    required bool isIsolatedArea,   // foot traffic < threshold
    required bool hasStreetLights,  // from OSM or manual flag
  }) {
    if (!isNightModeActive()) return baseRiskScore;

    double multiplier = riskMultiplierNight;

    // Count night-specific incident types
    final nightAssaults = nearbyIncidents.where((i) =>
      i['type'] == 'assault' || i['type'] == 'harassment' || i['type'] == 'robbery'
    ).length;

    if (nightAssaults > 0) multiplier *= (1 + nightAssaults * 0.3);
    if (isIsolatedArea) multiplier *= riskMultiplierIsolated;
    if (!hasStreetLights) multiplier *= riskMultiplierUnlit;

    // Cap at 100
    return (baseRiskScore * multiplier).clamp(0, 100);
  }

  // Night-safe route scoring
  // Prioritizes: lit streets > main roads > populated areas > short distance
  double calculateNightRouteSafety({
    required double daySafetyScore,   // base score from API
    required bool isMainRoad,         // true for NH/SH/major roads
    required bool isLit,              // has streetlights
    required bool isPopulated,        // estimated foot traffic
    required double distanceKm,       // longer routes penalized less at night if safer
  }) {
    if (!isNightModeActive()) return daySafetyScore;

    double nightScore = daySafetyScore;
    if (isMainRoad) nightScore += 15;    // reward main roads at night
    if (isLit) nightScore += 20;         // strong reward for lighting
    if (isPopulated) nightScore += 10;   // reward foot traffic
    nightScore -= distanceKm * 2;        // slight penalty per km (but safety wins)

    return nightScore.clamp(0, 100);
  }

  // Check-in schedule: intervals in minutes based on risk level
  int getCheckInIntervalMinutes(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'critical': return 5;
      case 'high':     return 10;
      case 'medium':   return 15;
      default:         return 30;
    }
  }

  // Night-specific safety tips by hour
  String getNightSafetyTip() {
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 2) {
      return "Late night: Stay on main lit roads. Avoid shortcuts through alleys or isolated paths.";
    } else if (hour >= 20) {
      return "Evening: Share your location with trusted contacts. Avoid poorly lit areas.";
    } else {
      return "Early morning: Stay alert. Reduce headphone use and stay aware of surroundings.";
    }
  }

  // Returns color for night risk visualization
  // Darker/more saturated than day colors
  Map<String, dynamic> getNightRiskVisual(double riskScore) {
    if (riskScore >= 75) {
      return {
      'color': const Color(0xFFDC2626),
      'glowColor': const Color(0xFFEF4444),
      'label': 'DANGER ZONE',
      'icon': Icons.dangerous,
    };
    }
    if (riskScore >= 50) {
      return {
      'color': const Color(0xFFD97706),
      'glowColor': const Color(0xFFF59E0B),
      'label': 'HIGH RISK AT NIGHT',
      'icon': Icons.warning_amber,
    };
    }
    if (riskScore >= 25) {
      return {
      'color': const Color(0xFF2563EB),
      'glowColor': const Color(0xFF3B82F6),
      'label': 'CAUTION AFTER DARK',
      'icon': Icons.nightlight,
    };
    }
    return {
      'color': const Color(0xFF059669),
      'glowColor': const Color(0xFF10B981),
      'label': 'RELATIVELY SAFE',
      'icon': Icons.check_circle_outline,
    };
  }
}
