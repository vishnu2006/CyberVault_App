import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// AES-GCM encryption/decryption with random IV.
/// Can be used with MasterKey bytes or pass-through for raw key operations.
class EncryptionHelper {
  EncryptionHelper._();
  static final EncryptionHelper instance = EncryptionHelper._();

  static const _algorithm = AesGcm.with256bits();

  /// Encrypt plaintext with AES-256-GCM using [keyBytes] (32 bytes) and random IV.
  /// Returns combined format: [IV (12 bytes) || ciphertext || mac (16 bytes)].
  Future<Uint8List> encryptWithKey(Uint8List plaintext, Uint8List keyBytes) async {
    final secretKey = SecretKey(_ensure32Bytes(keyBytes));
    final nonce = _algorithm.newNonce();
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );
    final combined = Uint8List(
      nonce.length + secretBox.cipherText.length + secretBox.mac.bytes.length,
    );
    combined.setRange(0, nonce.length, nonce);
    combined.setRange(
      nonce.length,
      nonce.length + secretBox.cipherText.length,
      secretBox.cipherText,
    );
    combined.setRange(
      nonce.length + secretBox.cipherText.length,
      combined.length,
      secretBox.mac.bytes,
    );
    return combined;
  }

  /// Decrypt combined format: first 12 bytes = IV, last 16 = mac.
  Future<Uint8List> decryptWithKey(Uint8List combined, Uint8List keyBytes) async {
    if (combined.length < 28) throw ArgumentError('Invalid combined data');
    final iv = Uint8List.sublistView(combined, 0, 12);
    final mac = combined.sublist(combined.length - 16);
    final ciphertext = combined.sublist(12, combined.length - 16);
    final secretKey = SecretKey(_ensure32Bytes(keyBytes));
    final secretBox = SecretBox(ciphertext, nonce: iv, mac: Mac(mac));
    return Uint8List.fromList(
      await _algorithm.decrypt(secretBox, secretKey: secretKey),
    );
  }

  List<int> _ensure32Bytes(Uint8List key) {
    if (key.length >= 32) return key.take(32).toList();
    final padded = List<int>.filled(32, 0);
    for (var i = 0; i < key.length && i < 32; i++) {
      padded[i] = key[i];
    }
    return padded;
  }
}
