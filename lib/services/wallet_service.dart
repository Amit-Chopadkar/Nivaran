import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:flutter/foundation.dart';
import 'dart:math';

class WalletService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );
  static const _privateKeyKey = 'wallet_private_key';

  web3.EthPrivateKey? _credentials;
  String? _address;

  String? get address => _address;
  bool get hasWallet => _credentials != null;

  /// Loads wallet if existing, returns true if found
  Future<bool> initWallet() async {
    try {
      final pk = await _storage.read(key: _privateKeyKey);
      if (pk != null) {
        _credentials = web3.EthPrivateKey.fromHex(pk);
        _address = _credentials!.address.eip55With0x;
        return true;
      }
    } catch (e) {
      debugPrint("Error initializing wallet: $e");
    }
    return false;
  }

  /// Creates a new wallet and stores it securely
  Future<String> createWallet() async {
    final rng = Random.secure();
    final privateKeyBytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      privateKeyBytes[i] = rng.nextInt(256);
    }
    
    _credentials = web3.EthPrivateKey(privateKeyBytes);
    _address = _credentials!.address.eip55With0x;

    // Save to secure storage
    await _storage.write(key: _privateKeyKey, value: _credentials!.privateKeyInt.toRadixString(16));

    return _address!;
  }

  /// Signs a message (like a nonce) for authentication
  Future<String?> signMessage(String message) async {
    if (_credentials == null) return null;

    try {
      final signature = _credentials!.signPersonalMessageToUint8List(
        Uint8List.fromList(message.codeUnits),
      );
      
      // Convert to hex string
      return '0x${signature.map((e) => e.toRadixString(16).padLeft(2, '0')).join('')}';
    } catch (e) {
      debugPrint("Signing error: $e");
      return null;
    }
  }

  /// Erase wallet (Optional recovery/logout feature)
  Future<void> clearWallet() async {
    await _storage.delete(key: _privateKeyKey);
    _credentials = null;
    _address = null;
  }
}
