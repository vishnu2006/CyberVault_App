import '../services/master_key_service.dart';

/// Duress Mode helpers: open fake vault, wipe keys.
/// Used when user enters duress PIN (e.g. 9999) or triggers panic.
class DuressHelper {
  DuressHelper._();
  static final DuressHelper instance = DuressHelper._();

  /// Duress password — opens empty vault instead of real content.
  static const duressPin = '9999';

  /// Check if password is the duress code.
  bool isDuressPin(String password) => password == duressPin;

  /// Open fake vault: wipe real MasterKey, navigate to VaultHomeFake.
  /// Call when duress PIN is entered.
  void openFakeVault() {
    wipeKeys();
    // Navigation to VaultHomeFake is handled by LoginScreen
  }

  /// Wipe MasterKey and session. Call on panic or auto-lock.
  void wipeKeys() {
    MasterKeyService.instance.wipe();
    // TODO: Clear Firebase session if using Firebase Auth
    // TODO: Invalidate biometric cache if used
  }

  /// Panic: wipe keys and optionally close app or navigate to login.
  void panic() {
    wipeKeys();
  }
}
