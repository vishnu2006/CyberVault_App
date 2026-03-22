import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// PBKDF2 key derivation from user PIN + salt.
/// Outputs 32-byte key suitable for AES-256-GCM.
class KeyDerivationHelper {
  KeyDerivationHelper._();
  static final KeyDerivationHelper instance = KeyDerivationHelper._();

  static const _defaultIterations = 100000;
  static const _keyBits = 256; // 32 bytes for AES-256

  /// Generate random salt for PBKDF2 (store per-user, e.g. in secure storage).
  Uint8List generateSalt({int length = 32}) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  /// Derive MasterKey from user PIN + salt using PBKDF2-HMAC-SHA256.
  /// SECURITY: Output is kept only in memory; never persist MasterKey.
  Future<Uint8List> deriveKeyFromPin(String pin, Uint8List salt,
      {int iterations = _defaultIterations}) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: _keyBits,
    );
    final secretKey = await pbkdf2.deriveKeyFromPassword(
      password: pin,
      nonce: salt,
    );
    return Uint8List.fromList(await secretKey.extractBytes());
  }

  /// Convenience: derive key and return as base64 string (for in-memory use).
  Future<String> deriveMasterKeyBase64(String pin, Uint8List salt,
      {int iterations = _defaultIterations}) async {
    final bytes = await deriveKeyFromPin(pin, salt, iterations: iterations);
    return base64Encode(bytes);
  }
}
