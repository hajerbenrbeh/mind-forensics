import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'biometric_service.dart';

/// State of the biometric app lock.
class AppLockState {
  const AppLockState({
    required this.isEnabled,
    required this.isLocked,
  });

  final bool isEnabled;
  final bool isLocked;

  AppLockState copyWith({
    bool? isEnabled,
    bool? isLocked,
  }) {
    return AppLockState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

/// Controller managing the biometric vault lock lifecycle using Notifier.
class AppLockNotifier extends Notifier<AppLockState> {
  BiometricSecurityService get _securityService => ref.read(biometricServiceProvider);

  @override
  AppLockState build() {
    _init();
    return const AppLockState(isEnabled: false, isLocked: false);
  }

  Future<void> _init() async {
    final enabled = await BiometricSecurityService.isBiometricEnabled();
    if (enabled) {
      state = const AppLockState(isEnabled: true, isLocked: true);
    } else {
      state = const AppLockState(isEnabled: false, isLocked: false);
    }
  }

  /// Attempts biometric unlock.
  Future<bool> unlock({String? reason}) async {
    final enabled = state.isEnabled || await BiometricSecurityService.isBiometricEnabled();
    if (!enabled) {
      state = state.copyWith(isLocked: false);
      return true;
    }

    final success = await _securityService.authenticate(
      reason: reason ?? 'Authenticate to unlock your Mind Forensics vault',
    );
    if (success) {
      state = state.copyWith(isEnabled: true, isLocked: false);
      return true;
    } else {
      state = state.copyWith(isEnabled: true, isLocked: true);
      return false;
    }
  }

  /// Enables or disables biometric lock with authentication verification.
  Future<bool> toggleBiometrics(bool enable) async {
    if (enable) {
      final canAuth = await _securityService.canAuthenticate();
      if (!canAuth) return false;

      final success = await _securityService.authenticate(
        reason: 'Confirm biometrics to enable session vault lock',
      );
      if (success) {
        await BiometricSecurityService.setBiometricEnabled(true);
        state = state.copyWith(isEnabled: true, isLocked: false);
        return true;
      }
      return false;
    } else {
      await BiometricSecurityService.setBiometricEnabled(false);
      state = state.copyWith(isEnabled: false, isLocked: false);
      return true;
    }
  }

  /// Locks the app manually.
  void lockManually() {
    if (state.isEnabled) {
      state = state.copyWith(isLocked: true);
    }
  }
}

final biometricServiceProvider = Provider<BiometricSecurityService>((ref) {
  return BiometricSecurityService();
});

final appLockProvider =
    NotifierProvider<AppLockNotifier, AppLockState>(AppLockNotifier.new);
