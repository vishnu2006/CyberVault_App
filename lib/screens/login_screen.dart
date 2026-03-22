import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../helpers/auto_lock_helper.dart';
import '../helpers/duress_helper.dart';
import '../helpers/key_derivation_helper.dart';
import '../services/auth_storage_service.dart';
import '../services/biometric_service.dart';
import '../services/biometric_storage_service.dart';
import '../services/master_key_service.dart';
import '../utils/app_navigator.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/vault_lock_animation.dart';
import '../widgets/biometric_prompt_dialog.dart';
import 'vault_home_screen.dart';
import 'vault_home_fake_screen.dart';
import 'set_password_screen.dart';

/// Login: correct password required, then biometric when available.
/// Biometric failure (emulator) allows password-only unlock.
class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _vaultUnlocked = false;
  final _localAuth = LocalAuthentication();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  // Biometric services
  final BiometricService _biometricService = BiometricService();
  final BiometricStorageService _biometricStorage = BiometricStorageService();
  
  // Cache theme colors to avoid null issues
  Color? _primaryColor;
  Color? _onSurfaceColor;
  Color? _surfaceColor;
  
  // Biometric state
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _biometricType = 'Biometric';
  bool _passwordExists = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_animationController);
    
    _slideAnimation = Tween<double>(begin: 0.3, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_animationController);
    
    _animationController.forward();
    _loadBiometricSettings();
    _checkPasswordExists();
  }

  Future<void> _checkPasswordExists() async {
    try {
      final passwordExists = await AuthStorageService.instance.hasPasswordSet;
      if (mounted) {
        setState(() {
          _passwordExists = passwordExists;
        });
      }
      debugPrint('Password exists: $passwordExists');
    } catch (e) {
      debugPrint('Error checking password existence: $e');
    }
  }

  Future<void> _loadBiometricSettings() async {
    try {
      // Use the enhanced biometric availability check
      final availability = await _biometricService.checkBiometricAvailability();
      final isEnabled = await _biometricStorage.isBiometricEnabled();
      final biometricName = await _biometricService.getPrimaryBiometricName();
      
      if (mounted) {
        setState(() {
          _biometricAvailable = availability.isAvailable;
          _biometricEnabled = isEnabled && availability.isAvailable;
          _biometricType = biometricName;
        });
      }
      
      debugPrint('Biometric availability: $availability');
      debugPrint('Biometric enabled: $_biometricEnabled');
      debugPrint('Biometric type: $_biometricType');
    } catch (e) {
      debugPrint('Error loading biometric settings: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache theme colors after dependencies are established
    _primaryColor = Theme.of(context).colorScheme.primary;
    _onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    _surfaceColor = Theme.of(context).colorScheme.surface;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Safe getters for theme colors with fallbacks
  Color get primaryColor => _primaryColor ?? Colors.blue;
  Color get onSurfaceColor => _onSurfaceColor ?? Colors.white;
  Color get surfaceColor => _surfaceColor ?? Colors.grey;

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter password';
    return null;
  }

  Future<void> _onUnlock() async {
    final password = _passwordController.text.trim();

    // Duress PIN
    if (DuressHelper.instance.isDuressPin(password)) {
      DuressHelper.instance.openFakeVault();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(VaultHomeFakeScreen.routeName);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 1. Get salt and derive key
      final salt = await AuthStorageService.instance.getSalt();
      final keyBytes = await KeyDerivationHelper.instance.deriveKeyFromPin(
        password,
        salt,
      );

      // 2. Verify password matches stored hash
      final isValid = await AuthStorageService.instance.verifyPassword(keyBytes);
      if (!isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid password')),
          );
        }
        return;
      }

      // 3. Store key in memory
      MasterKeyService.instance.setMasterKeyBytes(keyBytes);

      // 4. Check if biometric authentication should be used
      final hasBio = await _hasBiometrics();
      if (hasBio && _biometricEnabled) {
        _showBiometricDialog();
      } else {
        _completeLogin();
      }
    } catch (e) {
      MasterKeyService.instance.wipe();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showBiometricDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BiometricPromptDialog(
        customMessage: 'Use $_biometricType to unlock your vault',
        onSuccess: _completeLogin,
        onFailure: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_biometricType authentication failed'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        onCancel: () {
          // Allow password-only login if biometric is cancelled
          _completeLogin();
        },
      ),
    );
  }

  void _completeLogin() {
    if (!mounted) return;
    AutoLockHelper.instance.start();
    setState(() => _vaultUnlocked = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(VaultHomeScreen.routeName);
      }
    });
  }

  Future<void> _authenticateBiometricOnly() async {
    if (!_biometricAvailable || !_biometricEnabled) return;

    setState(() => _loading = true);

    try {
      final result = await _biometricService.authenticate(
        reason: 'Use $_biometricType to unlock your vault',
      );

      if (result.success) {
        // For biometric-only login, we need to get the stored master key
        // This would require storing the derived key securely after first login
        // For now, we'll show the password dialog
        _showPasswordDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_biometricType authentication failed'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Biometric error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPasswordDialog() {
    // Reset password field and focus
    _passwordController.clear();
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _goToSetPassword() {
    Navigator.of(context).pushNamed(SetPasswordScreen.routeName).then((_) {
      // After setting password, check if it was set successfully
      _checkPasswordExists();
    });
  }

  void _onPanic() {
    DuressHelper.instance.panic();
    AutoLockHelper.instance.cancel();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session wiped — keys cleared from memory'),
          backgroundColor: Colors.red,
        ),
      );
      goToLogin();
    }
  }

  Future<bool> _hasBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.scale(
                    scale: _slideAnimation.value,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Vault lock animation with premium effect
                          VaultLockAnimation(
                            isLocked: !_vaultUnlocked,
                            onAnimationComplete: () {
                              // Animation completed, vault is unlocked
                            },
                          ),
                          const SizedBox(height: 32),
                          
                          // App title with premium styling
                          Text(
                            'CyberFest Vault',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Subtitle
                          Text(
                            'Secure Document Storage',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  letterSpacing: 0.5,
                                ),
                          ),
                          const SizedBox(height: 48),
                          
                          Text(
                            'Enter your master password to unlock',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                          ),
                          const SizedBox(height: 48),
                          
                          // Premium glassmorphism card for password input
                          GlassmorphismCard(
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  validator: _validatePassword,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    letterSpacing: 0.5,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Master Password',
                                    labelStyle: TextStyle(
                                      color: onSurfaceColor.withOpacity(0.7),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_rounded,
                                      color: primaryColor,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                        color: onSurfaceColor.withOpacity(0.6),
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    filled: true,
                                    fillColor: surfaceColor.withOpacity(0.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: primaryColor.withOpacity(0.2),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Premium neon glow unlock button
                                NeonGlowButton(
                                  onPressed: _loading ? null : _onUnlock,
                                  glowColor: primaryColor,
                                  borderRadius: 16,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  enabled: !_loading,
                                  child: _loading
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: onSurfaceColor,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Verifying...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.lock_open_rounded, size: 20),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Unlock Vault',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                                
                                // Biometric login button (if available and enabled)
                                if (_biometricAvailable && _biometricEnabled) ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _loading ? null : _authenticateBiometricOnly,
                                      icon: Icon(
                                        Icons.fingerprint_rounded,
                                        color: primaryColor,
                                        size: 20,
                                      ),
                                      label: Text(
                                        'Use $_biometricType',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        side: BorderSide(
                                          color: primaryColor.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                
                                // Set password button (only show if password doesn't exist)
                                if (!_passwordExists) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: primaryColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: OutlinedButton.icon(
                                      onPressed: _goToSetPassword,
                                      icon: Icon(
                                        Icons.lock_reset_rounded,
                                        color: primaryColor,
                                        size: 20,
                                      ),
                                      label: Text(
                                        'Set Up Password',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        side: BorderSide(
                                          color: primaryColor.withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Security indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield_rounded,
                                size: 16,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AES-256 Encrypted',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ],
                          ),
                          
                          // Set/Change password button
                          TextButton.icon(
                            onPressed: _goToSetPassword,
                            icon: Icon(
                              Icons.settings_rounded,
                              color: primaryColor.withOpacity(0.7),
                              size: 16,
                            ),
                            label: Text(
                              'Set/Change Password',
                              style: TextStyle(
                                color: primaryColor.withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
