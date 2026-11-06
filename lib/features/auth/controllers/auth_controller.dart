import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_service.dart';
import '../domain/auth_state.dart';
import '../domain/auth_user.dart';

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  AuthService get _service => ref.read(authServiceProvider);

  @override
  AuthState build() {
    _hydrateAuth();
    return const AuthState(status: AuthStatus.initial);
  }

  Future<void> _hydrateAuth() async {
    try {
      final user = await _service.getCurrentUser();
      final onboardingDone = await _service.hasCompletedOnboarding();

      if (user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          hasCompletedOnboarding: onboardingDone,
        );
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          user: null,
          hasCompletedOnboarding: onboardingDone,
        );
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  /// Creates an anonymous sovereign vault.
  Future<AuthUser?> createAnonymousVault({String? codename}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _service.createAnonymousVault(codename: codename);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
      return user;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Signs in with an existing email and password.
  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _service.signInWithEmail(email, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
      return true;
    } catch (e) {
      final msg = e is FormatException ? e.message : e.toString();
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: msg,
      );
      return false;
    }
  }

  /// Registers a new email and password vault account.
  Future<bool> signUpWithEmail(
    String email,
    String password, {
    String? codename,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _service.signUpWithEmail(
        email,
        password,
        codename: codename,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
      return true;
    } catch (e) {
      final msg = e is FormatException ? e.message : e.toString();
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: msg,
      );
      return false;
    }
  }

  /// Upgrades an anonymous vault to an email-secured cloud vault.
  Future<bool> linkEmail(
    String email,
    String password, {
    String? codename,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _service.linkEmailToAnonymous(
        email,
        password,
        codename: codename,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
      return true;
    } catch (e) {
      final msg = e is FormatException ? e.message : e.toString();
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: msg,
      );
      return false;
    }
  }

  /// Marks onboarding as officially completed.
  Future<void> completeOnboarding() async {
    await _service.setOnboardingCompleted(true);
    state = state.copyWith(hasCompletedOnboarding: true);
  }

  /// Signs out of the current session.
  Future<void> signOut() async {
    await _service.signOut();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
      clearError: true,
    );
  }

  /// Permanently deletes account and local session data.
  Future<void> deleteAccount() async {
    await _service.deleteAccount();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      user: null,
      hasCompletedOnboarding: false,
    );
  }

  /// Clears any transient error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

