import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'master_key_service.dart';

/// AES-GCM encryption/decryption using MasterKey + random IV.
class EncryptionService {
  EncryptionService._();
  static final EncryptionService instance = EncryptionService._();

  static final _algorithm = AesGcm.with256bits();

  SecretKey _getSecretKey() {
    final keyBytes = MasterKeyService.instance.masterKeyBytes;
    if (keyBytes == null || keyBytes.isEmpty) {
      throw StateError('MasterKey not available');
    }
    var kb = keyBytes;
    if (kb.length < 32) {
      final padded = List<int>.filled(32, 0);
      for (var i = 0; i < kb.length && i < 32; i++) {
        padded[i] = kb[i];
      }
      kb = Uint8List.fromList(padded);
    } else if (kb.length > 32) {
      kb = Uint8List.sublistView(kb, 0, 32);
    }
    return SecretKey(kb);
  }

  /// Encrypt bytes with MasterKey + random IV. Returns IV + ciphertext + mac.
  /// IV is 12 bytes (GCM nonce), prepended to ciphertext.
  Future<EncryptedResult> encrypt(Uint8List plaintext) async {
    final secretKey = _getSecretKey();
    final nonce = _algorithm.newNonce();
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );
    final iv = nonce;
    final combined = Uint8List(
      iv.length + secretBox.cipherText.length + secretBox.mac.bytes.length,
    );
    combined.setRange(0, iv.length, iv);
    combined.setRange(
      iv.length,
      iv.length + secretBox.cipherText.length,
      secretBox.cipherText,
    );
    combined.setRange(
      iv.length + secretBox.cipherText.length,
      combined.length,
      secretBox.mac.bytes,
    );
    return EncryptedResult(
      iv: Uint8List.fromList(iv),
      ciphertext: Uint8List.fromList(secretBox.cipherText),
      mac: secretBox.mac.bytes,
      combined: combined,
    );
  }

  /// Decrypt [IV || ciphertext || mac] using MasterKey.
  Future<Uint8List> decrypt(Uint8List iv, Uint8List ciphertext, List<int> mac) async {
    final secretKey = _getSecretKey();
    final secretBox = SecretBox(
      ciphertext,
      nonce: iv,
      mac: Mac(mac),
    );
    return Uint8List.fromList(
      await _algorithm.decrypt(secretBox, secretKey: secretKey),
    );
  }

  /// Decrypt from combined format: first 12 bytes = IV, last 16 = mac.
  Future<Uint8List> decryptCombined(Uint8List combined) async {
    if (combined.length < 28) throw ArgumentError('Invalid combined data');
    final iv = Uint8List.sublistView(combined, 0, 12);
    final mac = combined.sublist(combined.length - 16);
    final ciphertext = combined.sublist(12, combined.length - 16);
    return decrypt(iv, ciphertext, mac);
  }
}

class EncryptedResult {
  final Uint8List iv;
  final Uint8List ciphertext;
  final List<int> mac;
  final Uint8List combined;

  EncryptedResult({
    required this.iv,
    required this.ciphertext,
    required this.mac,
    required this.combined,
  });
}
