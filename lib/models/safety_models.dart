import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class SafetyModels {
  static List<CrimeHotspot> getCrimeHotspots() {
    return [
      CrimeHotspot(lat: 19.9975, lng: 73.7898, intensity: 0.8, type: 'Theft', area: 'College Road'),
      CrimeHotspot(lat: 20.0059, lng: 73.7654, intensity: 0.7, type: 'Harassment', area: 'Gangapur Road'),
      CrimeHotspot(lat: 19.9950, lng: 73.7860, intensity: 0.9, type: 'Assault', area: 'CBS'),
      CrimeHotspot(lat: 20.0110, lng: 73.7900, intensity: 0.6, type: 'Stalking', area: 'Panchavati'),
      CrimeHotspot(lat: 19.9600, lng: 73.8300, intensity: 0.85, type: 'Robbery', area: 'Nashik Road'),
      CrimeHotspot(lat: 19.9900, lng: 73.8000, intensity: 0.75, type: 'Chain Snatching', area: 'Dwarka'),
      CrimeHotspot(lat: 19.9700, lng: 73.7700, intensity: 0.7, type: 'Theft', area: 'Indira Nagar'),
      CrimeHotspot(lat: 19.9905, lng: 73.7300, intensity: 0.8, type: 'Assault', area: 'Satpur MIDC'),
      CrimeHotspot(lat: 19.9500, lng: 73.7500, intensity: 0.75, type: 'Harassment', area: 'Ambad MIDC'),
      CrimeHotspot(lat: 20.0200, lng: 73.7800, intensity: 0.65, type: 'Suspicious Activity', area: 'Makhmalabad Road'),
      CrimeHotspot(lat: 19.9500, lng: 73.7800, intensity: 0.7, type: 'Theft', area: 'Pathardi Phata'),
      CrimeHotspot(lat: 20.0300, lng: 73.8000, intensity: 0.6, type: 'Harassment', area: 'Adgaon'),
      CrimeHotspot(lat: 19.9800, lng: 73.7700, intensity: 0.7, type: 'Robbery', area: 'Trimurti Chowk'),
      CrimeHotspot(lat: 19.9955, lng: 73.7805, intensity: 0.85, type: 'Theft', area: 'Canada Corner'),
      CrimeHotspot(lat: 19.9980, lng: 73.7850, intensity: 0.75, type: 'Assault', area: 'Shalimar'),
      CrimeHotspot(lat: 19.9400, lng: 73.8500, intensity: 0.6, type: 'Stalking', area: 'Deolali Camp'),
      CrimeHotspot(lat: 20.1000, lng: 73.9000, intensity: 0.55, type: 'Theft', area: 'Ojhar'),
      CrimeHotspot(lat: 19.7000, lng: 73.5500, intensity: 0.5, type: 'Harassment', area: 'Igatpuri'),
      
      // Nagpur Hotspots
      CrimeHotspot(lat: 21.1458, lng: 79.0882, intensity: 0.85, type: 'Mobbing', area: 'Sitabuldi', boundary: [
        LatLng(21.1408, 79.0822), LatLng(21.1508, 79.0822), LatLng(21.1508, 79.0942), LatLng(21.1408, 79.0942)
      ]),
      CrimeHotspot(lat: 21.1550, lng: 79.1050, intensity: 0.9, type: 'Theft', area: 'Itwari', boundary: [
        LatLng(21.1500, 79.0980), LatLng(21.1600, 79.0980), LatLng(21.1600, 79.1120), LatLng(21.1500, 79.1120)
      ]),
      CrimeHotspot(lat: 21.1520, lng: 79.0880, intensity: 0.9, type: 'Harassment', area: 'Nagpur Railway Station', boundary: [
        LatLng(21.1480, 79.0840), LatLng(21.1560, 79.0840), LatLng(21.1560, 79.0920), LatLng(21.1480, 79.0920)
      ]),
      CrimeHotspot(lat: 21.1600, lng: 79.0800, intensity: 0.75, type: 'Assault', area: 'Sadar', boundary: [
        LatLng(21.1550, 79.0750), LatLng(21.1650, 79.0750), LatLng(21.1650, 79.0850), LatLng(21.1550, 79.0850)
      ]),
      CrimeHotspot(lat: 21.0800, lng: 78.9900, intensity: 0.75, type: 'Robbery', area: 'Hingna MIDC', boundary: [
        LatLng(21.0700, 78.9800), LatLng(21.0900, 78.9800), LatLng(21.0900, 79.0000), LatLng(21.0700, 79.0000)
      ]),
    ];
  }

  static List<SafePlace> getSafePlaces() {
    return [
      // Nashik Safe Places
      SafePlace(lat: 19.9975, lng: 73.7898, name: 'Sarkarwada PS', type: SafePlaceType.policeStation, rating: 4.5),
      SafePlace(lat: 20.0059, lng: 73.7654, name: 'Gangapur PS', type: SafePlaceType.policeStation, rating: 4.2),
      SafePlace(lat: 19.9950, lng: 73.7860, name: 'Civil Hospital Nashik', type: SafePlaceType.hospital, rating: 4.8),
      SafePlace(lat: 19.9900, lng: 73.8000, name: 'Six Sigma Hospital', type: SafePlaceType.hospital, rating: 4.3),
      SafePlace(lat: 19.9600, lng: 73.8300, name: 'Nashik Road PS', type: SafePlaceType.policeStation, rating: 4.6),
      SafePlace(lat: 19.9955, lng: 73.7805, name: 'City Centre Mall', type: SafePlaceType.safeZone, rating: 4.7),
      SafePlace(lat: 19.9980, lng: 73.7850, name: 'Nashik Central Bus Stand', type: SafePlaceType.safeZone, rating: 4.1),
      SafePlace(lat: 19.9800, lng: 73.7700, name: 'Trimurti Chowk Safe Zone', type: SafePlaceType.safeZone, rating: 4.0),
      
      // Nagpur Safe Places
      SafePlace(lat: 21.1463, lng: 79.0849, name: 'Sitabuldi Police Station', type: SafePlaceType.policeStation, rating: 4.3),
      SafePlace(lat: 21.1610, lng: 79.0830, name: 'Sadar Police Station', type: SafePlaceType.policeStation, rating: 4.1),
      SafePlace(lat: 21.1350, lng: 79.0950, name: 'Government Medical College Hospital (GMCH)', type: SafePlaceType.hospital, rating: 4.6),
      SafePlace(lat: 21.1500, lng: 79.0800, name: 'Mayo Hospital (IGGMCH)', type: SafePlaceType.hospital, rating: 4.4),
      SafePlace(lat: 21.1250, lng: 79.0550, name: 'Wockhardt Hospital', type: SafePlaceType.hospital, rating: 4.8),
      SafePlace(lat: 21.1550, lng: 79.0850, name: 'Nagpur Railway Station Safe Zone', type: SafePlaceType.safeZone, rating: 4.2),
      SafePlace(lat: 21.1300, lng: 79.0600, name: 'Dharampeth Safe Zone', type: SafePlaceType.safeZone, rating: 4.5),
    ];
  }
}

class CrimeHotspot {
  final double lat;
  final double lng;
  final double intensity;
  final String type;
  final String area;
  final List<LatLng>? boundary;

  CrimeHotspot({
    required this.lat,
    required this.lng,
    required this.intensity,
    required this.type,
    required this.area,
    this.boundary,
  });
}

enum SafePlaceType { policeStation, hospital, safeZone }

class SafePlace {
  final double lat;
  final double lng;
  final String name;
  final SafePlaceType type;
  final double rating;

  SafePlace({
    required this.lat,
    required this.lng,
    required this.name,
    required this.type,
    required this.rating,
  });

  String get typeLabel {
    switch (type) {
      case SafePlaceType.policeStation:
        return 'Police Station';
      case SafePlaceType.hospital:
        return 'Hospital';
      case SafePlaceType.safeZone:
        return 'Safe Zone';
    }
  }

  String get typeEmoji {
    switch (type) {
      case SafePlaceType.policeStation:
        return '🚔';
      case SafePlaceType.hospital:
        return '🏥';
      case SafePlaceType.safeZone:
        return '🛡️';
    }
  }
}

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final bool isPrimary;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'relationship': relationship,
    'isPrimary': isPrimary,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
    id: json['id'],
    name: json['name'],
    phone: json['phone'],
    relationship: json['relationship'],
    isPrimary: json['isPrimary'] ?? false,
  );
}

class TripSession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final double startLat;
  final double startLng;
  double? endLat;
  double? endLng;
  final String destination;
  bool isActive;
  List<LocationPoint> route;
  List<TripAlert> alerts;
  List<NavigationInstruction> instructions;
  List<LatLng> path;
  bool isOffRoute;
  String distanceKm;
  int durationMin;

  TripSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.startLat,
    required this.startLng,
    this.endLat,
    this.endLng,
    required this.destination,
    this.isActive = true,
    List<LocationPoint>? route,
    List<TripAlert>? alerts,
    List<NavigationInstruction>? instructions,
    List<LatLng>? path,
    this.isOffRoute = false,
    this.distanceKm = '',
    this.durationMin = 0,
  }) : route = route ?? [],
       alerts = alerts ?? [],
       instructions = instructions ?? [],
       path = path ?? [];
}

class NavigationInstruction {
  final String instruction;
  final String distance;
  final IconData icon;
  final bool isSafeZone;

  NavigationInstruction({
    required this.instruction,
    required this.distance,
    required this.icon,
    this.isSafeZone = false,
  });
}

class LocationPoint {
  final double lat;
  final double lng;
  final DateTime timestamp;

  LocationPoint({required this.lat, required this.lng, required this.timestamp});
}

class TripAlert {
  final String message;
  final DateTime timestamp;
  final AlertSeverity severity;

  TripAlert({required this.message, required this.timestamp, required this.severity});
}

enum AlertSeverity { info, warning, danger, critical }

class SafetyReport {
  final String id;
  final String userId;
  final double lat;
  final double lng;
  final String type;
  final String description;
  final DateTime timestamp;
  final int upvotes;
  final bool isVerified;

  SafetyReport({
    required this.id,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.type,
    required this.description,
    required this.timestamp,
    this.upvotes = 0,
    this.isVerified = false,
  });
}

class RiskAssessment {
  final double overallScore;
  final String riskLevel;
  final String description;
  final List<RiskFactor> factors;
  final List<String> recommendations;
  final bool isSafeRoute;

  RiskAssessment({
    required this.overallScore,
    required this.riskLevel,
    required this.description,
    required this.factors,
    required this.recommendations,
    this.isSafeRoute = true,
  });

  static RiskAssessment calculate({
    required double lat,
    required double lng,
    required DateTime time,
  }) {
    final hour = time.hour;
    double timeRisk = 0;
    if (hour >= 22 || hour <= 5) {
      timeRisk = 35;
    } else if (hour >= 19 || hour <= 6) {
      timeRisk = 20;
    } else {
      timeRisk = 5;
    }

    double locationRisk = 0;
    final hotspots = SafetyModels.getCrimeHotspots();
    for (var hotspot in hotspots) {
      double dist = _haversineDistance(lat, lng, hotspot.lat, hotspot.lng);
      if (dist < 2.0) {
        locationRisk = math.max(locationRisk, hotspot.intensity * 40);
      }
    }

    double dayRisk = (time.weekday == DateTime.friday || time.weekday == DateTime.saturday) ? 10 : 5;

    double overall = (timeRisk + locationRisk + dayRisk).clamp(0, 100).toDouble();

    String level;
    String desc;
    if (overall <= 25) {
      level = 'Low';
      desc = 'This area appears safe at this time. Stay aware of your surroundings.';
    } else if (overall <= 50) {
      level = 'Moderate';
      desc = 'Exercise caution. Some risk factors detected in your area.';
    } else if (overall <= 75) {
      level = 'High';
      desc = 'Elevated risk detected. Consider using a safer route or traveling with company.';
    } else {
      level = 'Critical';
      desc = 'Danger zone! Immediate action recommended. Move to a safe location.';
    }

    List<RiskFactor> factors = [];
    if (timeRisk > 15) factors.add(RiskFactor(name: 'Late Night Hours', impact: timeRisk, icon: '🌙'));
    if (locationRisk > 15) factors.add(RiskFactor(name: 'Crime Hotspot Proximity', impact: locationRisk, icon: '📍'));
    if (dayRisk > 5) factors.add(RiskFactor(name: 'Weekend Activity', impact: dayRisk, icon: '📅'));

    List<String> recommendations = [];
    if (overall > 50) {
      recommendations.add('Share your live location with trusted contacts');
      recommendations.add('Use well-lit and populated routes');
      recommendations.add('Keep emergency SOS ready');
    }
    if (overall > 25) {
      recommendations.add('Stay on main roads');
      recommendations.add('Keep your phone charged');
    }
    recommendations.add('Trust your instincts');

    return RiskAssessment(
      overallScore: overall,
      riskLevel: level,
      description: desc,
      factors: factors,
      recommendations: recommendations,
    );
  }

  static double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
    const p = 0.017453292519943295;
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lng2 - lng1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }
}

class RiskFactor {
  final String name;
  final double impact;
  final String icon;

  RiskFactor({required this.name, required this.impact, required this.icon});
}
