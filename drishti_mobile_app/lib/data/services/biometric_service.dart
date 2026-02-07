/// Drishti App - Biometric Authentication Service
///
/// Handles fingerprint and face ID authentication.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for biometric authentication
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Storage keys
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint('[BiometricService] Error checking device support: $e');
      return false;
    }
  }

  /// Check if biometric authentication is available
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      debugPrint('[BiometricService] Error checking biometrics: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('[BiometricService] Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if biometric authentication is enabled for the app
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      debugPrint('[BiometricService] Error reading biometric enabled: $e');
      return false;
    }
  }

  /// Enable biometric authentication and save credentials
  Future<bool> enableBiometric({
    required String email,
    required String password,
  }) async {
    try {
      // First authenticate with biometric
      final authenticated = await authenticate(
        reason: 'Enable biometric login for quick access',
      );

      if (!authenticated) {
        return false;
      }

      // Save credentials securely
      await _secureStorage.write(key: _savedEmailKey, value: email);
      await _secureStorage.write(key: _savedPasswordKey, value: password);
      await _secureStorage.write(key: _biometricEnabledKey, value: 'true');

      debugPrint('[BiometricService] Biometric authentication enabled');
      return true;
    } catch (e) {
      debugPrint('[BiometricService] Error enabling biometric: $e');
      return false;
    }
  }

  /// Disable biometric authentication and clear saved credentials
  Future<void> disableBiometric() async {
    try {
      await _secureStorage.delete(key: _savedEmailKey);
      await _secureStorage.delete(key: _savedPasswordKey);
      await _secureStorage.delete(key: _biometricEnabledKey);
      debugPrint('[BiometricService] Biometric authentication disabled');
    } catch (e) {
      debugPrint('[BiometricService] Error disabling biometric: $e');
    }
  }

  /// Authenticate with biometric and retrieve saved credentials
  Future<Map<String, String>?> authenticateAndGetCredentials() async {
    try {
      // Check if biometric is enabled
      final enabled = await isBiometricEnabled();
      if (!enabled) {
        debugPrint('[BiometricService] Biometric not enabled');
        return null;
      }

      // Authenticate with biometric
      final authenticated = await authenticate(
        reason: 'Authenticate to login',
      );

      if (!authenticated) {
        return null;
      }

      // Retrieve saved credentials
      final email = await _secureStorage.read(key: _savedEmailKey);
      final password = await _secureStorage.read(key: _savedPasswordKey);

      if (email == null || password == null) {
        debugPrint('[BiometricService] No saved credentials found');
        return null;
      }

      return {
        'email': email,
        'password': password,
      };
    } catch (e) {
      debugPrint('[BiometricService] Error authenticating: $e');
      return null;
    }
  }

  /// Authenticate with biometric
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Biometric Authentication',
            cancelButton: 'Cancel',
            biometricHint: 'Verify identity',
            biometricNotRecognized: 'Not recognized. Try again.',
            biometricSuccess: 'Success',
            deviceCredentialsRequiredTitle: 'Device credentials required',
            deviceCredentialsSetupDescription: 'Please set up device credentials',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancel',
            goToSettingsButton: 'Settings',
            goToSettingsDescription: 'Please set up biometric authentication',
            lockOut: 'Biometric authentication is disabled. Please lock and unlock your screen to enable it.',
          ),
        ],
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // Allow PIN/Pattern as fallback
        ),
      );

      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] Platform exception: ${e.message}');
      
      // Handle specific error codes
      switch (e.code) {
        case 'NotAvailable':
          debugPrint('[BiometricService] Biometric not available');
          break;
        case 'NotEnrolled':
          debugPrint('[BiometricService] No biometrics enrolled');
          break;
        case 'LockedOut':
          debugPrint('[BiometricService] Too many attempts, locked out');
          break;
        case 'PermanentlyLockedOut':
          debugPrint('[BiometricService] Permanently locked out');
          break;
        default:
          debugPrint('[BiometricService] Unknown error: ${e.code}');
      }
      
      return false;
    } catch (e) {
      debugPrint('[BiometricService] Error during authentication: $e');
      return false;
    }
  }

  /// Get biometric type name for display
  Future<String> getBiometricTypeName() async {
    final biometrics = await getAvailableBiometrics();
    
    if (biometrics.isEmpty) {
      return 'Biometric';
    }
    
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (biometrics.contains(BiometricType.strong)) {
      return 'Biometric';
    } else if (biometrics.contains(BiometricType.weak)) {
      return 'Device Credentials';
    }
    
    return 'Biometric';
  }

  /// Check if biometric is available and ready to use
  Future<bool> isBiometricAvailable() async {
    final isSupported = await isDeviceSupported();
    if (!isSupported) return false;

    final canCheck = await canCheckBiometrics();
    if (!canCheck) return false;

    final biometrics = await getAvailableBiometrics();
    return biometrics.isNotEmpty;
  }
}
