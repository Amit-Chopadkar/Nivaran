import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class UserProfile {
  final String name;
  final String phone;
  final String idNumber;
  final String email;
  final bool isVerified;
  final String? kycTxHash;
  final String? kycHash;
  final String gender;

  UserProfile({
    required this.name,
    required this.phone,
    required this.idNumber,
    required this.email,
    required this.gender,
    this.isVerified = false,
    this.kycTxHash,
    this.kycHash,
  });

  UserProfile copyWith({
    String? name,
    String? phone,
    String? idNumber,
    String? email,
    bool? isVerified,
    String? kycTxHash,
    String? kycHash,
    String? gender,
  }) {
    return UserProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      idNumber: idNumber ?? this.idNumber,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      isVerified: isVerified ?? this.isVerified,
      kycTxHash: kycTxHash ?? this.kycTxHash,
      kycHash: kycHash ?? this.kycHash,
    );
  }
}

class UserService extends ChangeNotifier {
  UserProfile? _profile;

  UserProfile? get profile => _profile;
  bool get isLoggedIn => _profile != null;

  String? _pendingPassword;

  Future<String?> register(UserProfile profile, String password) async {
    _profile = profile;
    _pendingPassword = password;
    final error = await _syncToSupabase();
    notifyListeners();
    return error; // null = success
  }

  void login(UserProfile profile) {
    _profile = profile;
    _syncToSupabase();
    notifyListeners();
  }

  Future<String?> _syncToSupabase() async {
    if (_profile == null) return null;
    return SupabaseService.syncUserProfile(
      name: _profile!.name,
      email: _profile!.email,
      phone: _profile!.phone,
      idNumber: _profile!.idNumber,
      gender: _profile!.gender,
      isVerified: _profile!.isVerified,
      kycHash: _profile!.kycHash,
      kycTxHash: _profile!.kycTxHash,
      password: _pendingPassword,
    );
  }

  void updateVerificationStatus(bool isVerified, String txHash, String kycHash) {
    if (_profile != null) {
      _profile = _profile!.copyWith(isVerified: isVerified, kycTxHash: txHash, kycHash: kycHash);
      
      // Update only verification fields in Supabase
      SupabaseService.updateVerificationDetails(
        email: _profile!.email,
        isVerified: isVerified,
        kycHash: kycHash,
        kycTxHash: txHash,
      );
      
      notifyListeners();
    }
  }

  Future<bool> loginWithEmailAndPassword(String email, String password) async {
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('email', email)
          .eq('password', password)
          .maybeSingle();

      if (data != null) {
        _profile = UserProfile(
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          idNumber: data['id_number'] ?? '',
          gender: data['gender'] ?? 'female',
          isVerified: data['is_verified'] ?? false,
          kycHash: data['kyc_hash'],
          kycTxHash: data['kyc_tx_hash'],
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login Error: $e');
      return false;
    }
  }

  Future<bool> fetchProfileByEmail(String email) async {
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (data != null) {
        _profile = UserProfile(
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          idNumber: data['id_number'] ?? '',
          gender: data['gender'] ?? 'female',
          isVerified: data['is_verified'] ?? false,
          kycHash: data['kyc_hash'],
          kycTxHash: data['kyc_tx_hash'],
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Fetch Profile Error: $e');
      return false;
    }
  }

  void logout() {
    _profile = null;
    notifyListeners();
  }
}
