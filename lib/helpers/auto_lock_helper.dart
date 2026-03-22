import 'dart:async';

import '../services/master_key_service.dart';
import '../utils/app_navigator.dart' as app_nav;
import 'duress_helper.dart';

/// Auto-lock timer: clears MasterKey after X minutes of inactivity.
/// Call [resetTimer] on each user action; [wipe] runs after idle timeout.
class AutoLockHelper {
  AutoLockHelper._();
  static final AutoLockHelper instance = AutoLockHelper._();

  Timer? _timer;
  static const _defaultMinutes = 3;

  /// Minutes of inactivity before auto-lock.
  int get inactivityMinutes => _defaultMinutes;

  /// Reset the inactivity timer. Call on: vault open, document view, upload, etc.
  void resetTimer({void Function()? onLock}) {
    _timer?.cancel();
    _timer = Timer(Duration(minutes: _defaultMinutes), () {
      _onTimeout(onLock);
    });
  }

  void _onTimeout(void Function()? onLock) {
    DuressHelper.instance.wipeKeys();
    onLock?.call();
  }

  /// Cancel the timer (e.g. on logout).
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Start monitoring; call resetTimer on each activity.
  /// On timeout: wipes keys and redirects to Login.
  void start({void Function()? onLock}) {
    if (MasterKeyService.instance.isUnlocked) {
      resetTimer(onLock: () {
        app_nav.goToLogin();
        onLock?.call();
      });
    }
  }
}
