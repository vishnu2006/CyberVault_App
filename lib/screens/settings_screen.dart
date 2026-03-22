import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../services/biometric_storage_service.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/neon_glow_button.dart';
import '../widgets/biometric_prompt_dialog.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final BiometricService _biometricService = BiometricService();
  final BiometricStorageService _biometricStorage = BiometricStorageService();
  
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _isLoading = true;
  String _biometricType = 'Biometric';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_animationController);
    
    _loadSettings();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
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
          _isLoading = false;
        });
      }
      
      debugPrint('Biometric availability: $availability');
      debugPrint('Biometric enabled: $_biometricEnabled');
      debugPrint('Biometric type: $_biometricType');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!value) {
      // Disable biometric
      await _biometricStorage.setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Biometric login disabled'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    // Enable biometric - show authentication dialog first
    _showBiometricSetupDialog();
  }

  void _showBiometricSetupDialog() async {
    // Check availability before showing dialog
    final availability = await _biometricService.checkBiometricAvailability();
    
    if (!availability.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(availability.message ?? 'Biometric not available'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => BiometricPromptDialog(
        customMessage: 'Authenticate to enable $_biometricType login',
        onSuccess: () async {
          await _biometricStorage.setBiometricEnabled(true);
          await _biometricStorage.setBiometricSetupCompleted(true);
          
          if (mounted) {
            setState(() => _biometricEnabled = true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$_biometricType login enabled'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }
        },
        onFailure: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to enable biometric login'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
      ),
    );
  }

  String _getBiometricStatusMessage() {
    if (_biometricAvailable) {
      return 'Use $_biometricType to unlock your vault';
    } else {
      return 'Biometric authentication not available';
    }
  }

  String _getBiometricUnavailableMessage() {
    // Try to get more specific availability info
    if (_biometricType == 'Fingerprint') {
      return 'Fingerprint authentication not available on this device. Please configure fingerprint in device settings or use a device with fingerprint sensor.';
    } else if (_biometricType == 'Face ID') {
      return 'Face ID not available on this device. Please use a device with Face ID support.';
    } else {
      return 'Biometric authentication not available on this device. Please check device settings or use a device with biometric support.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Security Settings Section
                    Text(
                      'Security',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Biometric Authentication Setting
                    GlassmorphismCard(
                      padding: const EdgeInsets.all(20),
                      opacity: 0.06,
                      blur: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.fingerprint_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Biometric Login',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getBiometricStatusMessage(),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Biometric toggle
                          Row(
                            children: [
                              Text(
                                'Enable Biometric Login',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const Spacer(),
                              Switch(
                                value: _biometricEnabled,
                                onChanged: _biometricAvailable ? _toggleBiometric : null,
                                activeColor: Theme.of(context).colorScheme.primary,
                                inactiveThumbColor: Theme.of(context).colorScheme.surface,
                                inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              ),
                            ],
                          ),
                          
                          if (!_biometricAvailable) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _getBiometricUnavailableMessage(),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.error,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // About Section
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    
                    // App Info
                    GlassmorphismCard(
                      padding: const EdgeInsets.all(20),
                      opacity: 0.06,
                      blur: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CyberFest Vault',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Secure document storage with biometric authentication and zero-knowledge encryption.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Icon(
                                Icons.shield_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AES-256 Encrypted',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
