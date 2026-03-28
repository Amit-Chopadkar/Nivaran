import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Full User Profile Sync (including password)
  // Returns null on success, or an error string on failure.
  static Future<String?> syncUserProfile({
    required String name,
    required String email,
    required String phone,
    required String idNumber,
    required String gender,
    bool isVerified = false,
    String? kycHash,
    String? kycTxHash,
    String? password,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'email': email,
        'name': name,
        'phone': phone,
        'id_number': idNumber,
        'gender': gender,
        'is_verified': isVerified,
        'kyc_hash': kycHash,
        'kyc_tx_hash': kycTxHash,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (password != null) {
        data['password'] = password;
      }

      await _supabase.from('users').upsert(data, onConflict: 'email');
      debugPrint('Supabase: Profile synced for $email');
      return null; // success
    } catch (e) {
      final errMsg = 'Supabase Error (syncUserProfile): $e';
      debugPrint(errMsg);
      return errMsg;
    }
  }

  // 1a. Update only Verification Data (prevents clearing password)
  static Future<void> updateVerificationDetails({
    required String email,
    required bool isVerified,
    required String kycHash,
    required String kycTxHash,
  }) async {
    try {
      await _supabase.from('users').update({
        'is_verified': isVerified,
        'kyc_hash': kycHash,
        'kyc_tx_hash': kycTxHash,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('email', email);
      debugPrint('Supabase: Verification details updated for $email');
    } catch (e) {
      debugPrint('Supabase Error (updateVerificationDetails): $e');
    }
  }

  // 1b. Log a Scanned Verification (When user scans someone else)
  static Future<void> logIdentityVerification({
    required String verifierEmail,
    required String scannedHash,
  }) async {
    try {
      await _supabase.from('verified_identities').insert({
        'verifier_email': verifierEmail,
        'scanned_hash': scannedHash,
        'verified_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Supabase: Verification logged for $verifierEmail -> $scannedHash');
    } catch (e) {
      debugPrint('Supabase Error (logIdentityVerification): $e');
    }
  }

  // 2. Log SOS Event
  static Future<Map<String, dynamic>> logSOSEvent({
    required String userEmail,
    required String userName,
    required String type,
    required double latitude,
    required double longitude,
    required List<String> meshPath,
    String? blockchainHash,
  }) async {
    try {
      final data = {
        'user_email': userEmail,
        'type': type.toLowerCase(),
        'latitude': latitude,
        'longitude': longitude,
        'blockchain_hash': blockchainHash,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      final response = await _supabase.from('sos_logs').insert(data).select();
      
      if (response.isNotEmpty) {
        final id = response.first['id']?.toString();
        debugPrint('Supabase: SOS Alert logged (ID: $id)');
        return {'success': true, 'id': id};
      }
      return {'success': false, 'error': 'No response from database'};
    } catch (e) {
      debugPrint('Supabase Critical Error (logSOSEvent): $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // 2b. Update SOS Location (Live Tracking)
  static Future<void> updateSOSLocation({
    required String logId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _supabase.from('sos_logs').update({
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', logId);
      // Silent update to avoid log spam
    } catch (e) {
      debugPrint('Supabase Error (updateSOSLocation): $e');
    }
  }

  // 2a. Log Community Incident
  static Future<void> logIncident({
    required String title,
    required String type,
    required String severity,
    required double lat,
    required double lng,
    required String address,
    required String description,
    required int riskScore,
    String? source,
  }) async {
    try {
      // Map severity label to integer 1-4 for DB storage
      final Map<String, int> severityValues = {
        'low': 1,
        'medium': 2,
        'high': 3,
        'critical': 4,
      };
      
      await _supabase.from('incidents').insert({
        'title': title,
        'type': type.toLowerCase(),
        'severity': severityValues[severity.toLowerCase()] ?? 2,
        'source': source ?? 'user_report',
        'lat': lat,
        'lng': lng,
        'address': address,
        'description': description,
        'verified': false,
        'risk_score': riskScore,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Supabase: Incident logged by ${source ?? "User"}: $title');
    } catch (e) {
      debugPrint('Supabase Error (logIncident): $e');
    }
  }

  // 3. Sync Contacts — upserts by (user_email, phone) to avoid duplicates
  static Future<String?> syncContact({
    required String userEmail,
    required String name,
    required String phone,
    required String relation,
  }) async {
    try {
      await _supabase.from('contacts').upsert({
        'user_email': userEmail,
        'name': name,
        'phone': phone,
        'relation': relation,
      }, onConflict: 'user_email,phone');
      debugPrint('Supabase: Contact synced for $userEmail');
      return null; // success
    } catch (e) {
      final errMsg = 'Supabase Error (syncContact): $e';
      debugPrint(errMsg);
      return errMsg;
    }
  }

  // 4. Delete Contact
  static Future<void> deleteContact(String id) async {
    try {
      await _supabase.from('contacts').delete().match({'id': id});
      debugPrint('Supabase: Contact deleted ($id)');
    } catch (e) {
      debugPrint('Supabase Error (deleteContact): $e');
    }
  }

  // 5. Admin Broadcasts (Private Chat between User and Admin)
  static Stream<List<Map<String, dynamic>>> getAdminMessages(String userEmail) {
    return _supabase
        .from('admin_broadcasts')
        .stream(primaryKey: ['id'])
        .eq('user_email', userEmail)
        .order('created_at', ascending: true);
  }

  static Future<void> sendAdminMessage({
    required String userEmail,
    required String message,
    required bool isAdmin,
  }) async {
    try {
      await _supabase.from('admin_broadcasts').insert({
        'user_email': userEmail,
        'message': message,
        'is_admin': isAdmin,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase Error (sendAdminMessage): $e');
    }
  }

  // 6. Generic Location Tracking
  static Future<void> updateUserLocation({
    required String email,
    required double lat,
    required double lng,
  }) async {
    try {
      await _supabase.from('users').update({
        'last_lat': lat,
        'last_lng': lng,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('email', email);
    } catch (e) {
      debugPrint('Supabase Error (updateUserLocation): $e');
    }
  }
}
