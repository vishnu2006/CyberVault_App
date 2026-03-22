import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../services/master_key_service.dart';
import 'key_derivation_helper.dart';

/// Generate MasterKey only in memory — never persist.
/// Uses PBKDF2 derivation from PIN + salt.
class MasterKeyHelper {
  MasterKeyHelper._();
  static final MasterKeyHelper instance = MasterKeyHelper._();

  /// Derive and store MasterKey in memory from PIN + salt.
  /// Call after successful PIN/biometric auth.
  Future<void> generateAndStoreMasterKey(String pin, Uint8List salt) async {
    final keyBytes = await KeyDerivationHelper.instance.deriveKeyFromPin(
      pin,
      salt,
      iterations: 100000,
    );
    MasterKeyService.instance.setMasterKeyBytes(keyBytes);
  }

  /// Check if MasterKey exists in memory.
  bool get hasMasterKey => MasterKeyService.instance.isUnlocked;

  /// Wipe MasterKey from memory (panic / logout / auto-lock).
  void wipeMasterKey() {
    MasterKeyService.instance.wipe();
  }
}
