import 'package:flutter/material.dart';

import '../services/auth_storage_service.dart';
import 'login_screen.dart';
import 'set_password_screen.dart';

/// Decides initial route: SetPassword (first time) or Login.
class AuthGateScreen extends StatefulWidget {
  static const routeName = '/';

  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    final hasPassword = await AuthStorageService.instance.hasPasswordSet;
    if (!mounted) return;
    if (hasPassword) {
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    } else {
      Navigator.of(context).pushReplacementNamed(SetPasswordScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
