import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auth persistence: salt + SHA-256 verification hash of derived key.
/// MasterKey is never stored — only used to verify password on login.
class AuthStorageService {
  AuthStorageService._();
  static final AuthStorageService instance = AuthStorageService._();

  static const _keyHasPasswordSet = 'vault_has_password';
  static const _keySalt = 'vault_salt';
  static const _keyVerifyHash = 'vault_verify_hash';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// True only if all required auth data exists (migration-safe).
  Future<bool> get hasPasswordSet async {
    final p = await prefs;
    final hasFlag = p.getBool(_keyHasPasswordSet) ?? false;
    final hasSalt = p.getString(_keySalt) != null;
    final hasHash = p.getString(_keyVerifyHash) != null;

    // Legacy: had password set before we added verifyHash — force reset
    if (hasFlag && (!hasSalt || !hasHash)) {
      await _clearAll(p);
      return false;
    }
    return hasFlag && hasSalt && hasHash;
  }

  Future<void> _clearAll(SharedPreferences p) async {
    await p.remove(_keyHasPasswordSet);
    await p.remove(_keySalt);
    await p.remove(_keyVerifyHash);
  }

  /// Store salt and verification hash. Call after deriving key from password.
  Future<void> setPassword(Uint8List salt, Uint8List derivedKey) async {
    final p = await prefs;
    final hash = await Sha256().hash(derivedKey);
    await p.setBool(_keyHasPasswordSet, true);
    await p.setString(_keySalt, base64Encode(salt));
    await p.setString(_keyVerifyHash, base64Encode(hash.bytes));
  }

  /// Verify that derivedKey matches stored hash. Returns true if password correct.
  Future<bool> verifyPassword(Uint8List derivedKey) async {
    final p = await prefs;
    final stored = p.getString(_keyVerifyHash);
    if (stored == null) return false;

    final hash = await Sha256().hash(derivedKey);
    final storedBytes = Uint8List.fromList(base64Decode(stored));
    if (hash.bytes.length != storedBytes.length) return false;
    for (var i = 0; i < hash.bytes.length; i++) {
      if (hash.bytes[i] != storedBytes[i]) return false;
    }
    return true;
  }

  Future<Uint8List> getSalt() async {
    final p = await prefs;
    final s = p.getString(_keySalt);
    if (s == null) throw StateError('Salt not found');
    return Uint8List.fromList(base64Decode(s));
  }
}
