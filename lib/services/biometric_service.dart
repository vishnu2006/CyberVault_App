import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      // First check if device supports local authentication
      final isSupported = await _localAuth.isDeviceSupported();
      debugPrint('Device supported: $isSupported');
      
      if (!isSupported) return false;

      // Then check if biometrics are available
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      debugPrint('Can check biometrics: $canCheckBiometrics');
      
      return canCheckBiometrics;
    } catch (e) {
      debugPrint('Error checking biometric support: $e');
      
      // On emulator, sometimes the check fails but biometrics might still work
      // Try to get available biometrics as a fallback
      try {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        debugPrint('Available biometrics (fallback): $availableBiometrics');
        return availableBiometrics.isNotEmpty;
      } catch (fallbackError) {
        debugPrint('Fallback check also failed: $fallbackError');
        return false;
      }
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      debugPrint('Available biometrics: $biometrics');
      return biometrics;
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      
      // For emulator compatibility, return empty list but don't fail
      return [];
    }
  }

  /// Check if specific biometric type is available
  Future<bool> hasBiometricType(BiometricType type) async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.contains(type);
    } catch (e) {
      debugPrint('Error checking biometric type: $e');
      return false;
    }
  }

  /// Check if fingerprint is available
  Future<bool> hasFingerprint() async {
    return await hasBiometricType(BiometricType.fingerprint);
  }

  /// Check if face ID is available
  Future<bool> hasFaceId() async {
    return await hasBiometricType(BiometricType.face);
  }

  /// Enhanced biometric availability check with emulator support
  Future<BiometricAvailability> checkBiometricAvailability() async {
    try {
      // Step 1: Check device support
      final deviceSupported = await _localAuth.isDeviceSupported();
      debugPrint('Device support check: $deviceSupported');
      
      if (!deviceSupported) {
        return BiometricAvailability.unavailable('Device does not support local authentication');
      }

      // Step 2: Check if can check biometrics
      final canCheck = await _localAuth.canCheckBiometrics;
      debugPrint('Can check biometrics: $canCheck');
      
      // Step 3: Get available biometrics
      List<BiometricType> availableBiometrics = [];
      try {
        availableBiometrics = await _localAuth.getAvailableBiometrics();
        debugPrint('Available biometrics: $availableBiometrics');
      } catch (e) {
        debugPrint('Error getting biometrics: $e');
      }

      // Step 4: Determine availability status
      if (availableBiometrics.isNotEmpty) {
        return BiometricAvailability.available(availableBiometrics);
      } else if (canCheck) {
        // On some emulators, canCheckBiometrics returns true but no biometrics are listed
        // This might indicate biometric simulation is available
        if (kDebugMode) {
          debugPrint('Debug mode: Assuming biometric simulation available');
          return BiometricAvailability.simulated();
        }
        return BiometricAvailability.notConfigured('Biometrics not configured on device');
      } else {
        return BiometricAvailability.notAvailable('Biometric authentication not available');
      }
    } catch (e) {
      debugPrint('Comprehensive biometric check failed: $e');
      return BiometricAvailability.error('Error checking biometric availability: $e');
    }
  }

  /// Authenticate with biometrics
  Future<BiometricResult> authenticate({
    String reason = 'Authenticate to access your secure vault',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool biometricOnly = true,
  }) async {
    try {
      final availability = await checkBiometricAvailability();
      
      if (!availability.isAvailable) {
        return BiometricResult.failure(availability.message ?? 'Biometric authentication not available');
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
        ),
      );

      if (authenticated) {
        return BiometricResult.success();
      } else {
        return BiometricResult.failure('Authentication cancelled or failed');
      }
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return BiometricResult.failure('Authentication error: ${e.toString()}');
    }
  }

  /// Get user-friendly biometric type name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.iris:
        return 'Iris Scanner';
      case BiometricType.strong:
        return 'Biometric';
      default:
        return 'Biometric';
    }
  }

  /// Get primary available biometric type name
  Future<String> getPrimaryBiometricName() async {
    final availability = await checkBiometricAvailability();
    
    if (availability.isAvailable && availability.availableBiometrics?.isNotEmpty == true) {
      final biometrics = availability.availableBiometrics!;
      
      if (biometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Fingerprint';
      } else if (biometrics.isNotEmpty) {
        return getBiometricTypeName(biometrics.first);
      }
    }
    
    // For simulated biometrics on emulator
    if (availability.isSimulated) {
      return 'Fingerprint';
    }
    
    return 'Biometric';
  }

  /// Stop authentication (for sticky auth)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      debugPrint('Error stopping authentication: $e');
    }
  }
}

/// Biometric availability status
class BiometricAvailability {
  final bool isAvailable;
  final bool isSimulated;
  final String? message;
  final List<BiometricType>? availableBiometrics;

  BiometricAvailability.available(this.availableBiometrics)
      : isAvailable = true,
        isSimulated = false,
        message = null;

  BiometricAvailability.simulated()
      : isAvailable = true,
        isSimulated = true,
        message = 'Biometric simulation available (debug mode)',
        availableBiometrics = [BiometricType.fingerprint];

  BiometricAvailability.unavailable(this.message)
      : isAvailable = false,
        isSimulated = false,
        availableBiometrics = null;

  BiometricAvailability.notConfigured(this.message)
      : isAvailable = false,
        isSimulated = false,
        availableBiometrics = null;

  BiometricAvailability.notAvailable(this.message)
      : isAvailable = false,
        isSimulated = false,
        availableBiometrics = null;

  BiometricAvailability.error(this.message)
      : isAvailable = false,
        isSimulated = false,
        availableBiometrics = null;

  @override
  String toString() {
    if (isAvailable) {
      if (isSimulated) {
        return 'BiometricAvailability(simulated)';
      }
      return 'BiometricAvailability(available: $availableBiometrics)';
    }
    return 'BiometricAvailability(unavailable: $message)';
  }
}

/// Biometric authentication result
class BiometricResult {
  final bool success;
  final String? errorMessage;

  BiometricResult.success() : success = true, errorMessage = null;
  BiometricResult.failure(this.errorMessage) : success = false;

  @override
  String toString() {
    return success ? 'BiometricResult(success)' : 'BiometricResult.failure: $errorMessage';
  }
}
