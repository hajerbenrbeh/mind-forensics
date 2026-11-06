import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing biometric device authentication (Fingerprint / Face ID / Passcode).
///
/// Section 11 & Step 9:
/// Optional app lock with biometrics to safeguard sensitive cognitive sessions.
class BiometricSecurityService {
  BiometricSecurityService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;
  static const String prefKeyBiometric = 'mf_settings_biometric';

  /// Checks if the device has biometric hardware or device credential capabilities.
  Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Returns available biometric hardware types (e.g. fingerprint, face).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  /// Prompts user for biometric authentication.
  Future<bool> authenticate({
    String reason = 'Authenticate to access your private session vault',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
      );
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Returns whether biometric lock is enabled in settings.
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefKeyBiometric) ?? false;
  }

  /// Persists the user's biometric lock preference.
  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyBiometric, enabled);
  }
}
