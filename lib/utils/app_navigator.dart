import 'package:flutter/material.dart';

import '../screens/login_screen.dart';

/// Global navigator key for app-wide navigation (e.g. auto-lock redirect).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Navigate to Login and clear stack (e.g. on auto-lock).
void goToLogin() {
  navigatorKey.currentState?.pushNamedAndRemoveUntil(
    LoginScreen.routeName,
    (route) => false,
  );
}
