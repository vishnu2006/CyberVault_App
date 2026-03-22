import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricStorageService {
  static final BiometricStorageService _instance = BiometricStorageService._internal();
  factory BiometricStorageService() => _instance;
  BiometricStorageService._internal();

  static const String _biometricEnabledKey = 'biometric_login_enabled';
  static const String _biometricSetupKey = 'biometric_setup_completed';

  /// Save biometric login preference
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
    } catch (e) {
      debugPrint('Error saving biometric preference: $e');
    }
  }

  /// Get biometric login preference
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Error getting biometric preference: $e');
      return false;
    }
  }

  /// Mark biometric setup as completed
  Future<void> setBiometricSetupCompleted(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricSetupKey, completed);
    } catch (e) {
      debugPrint('Error saving biometric setup status: $e');
    }
  }

  /// Check if biometric setup has been completed
  Future<bool> isBiometricSetupCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricSetupKey) ?? false;
    } catch (e) {
      debugPrint('Error getting biometric setup status: $e');
      return false;
    }
  }

  /// Clear all biometric preferences
  Future<void> clearBiometricPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_biometricEnabledKey);
      await prefs.remove(_biometricSetupKey);
    } catch (e) {
      debugPrint('Error clearing biometric preferences: $e');
    }
  }
}
