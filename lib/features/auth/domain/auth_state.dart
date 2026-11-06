import 'auth_user.dart';

/// The authentication status lifecycle.
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

/// The state holder for the authentication controller.
class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.hasCompletedOnboarding = false,
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;
  final bool hasCompletedOnboarding;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  bool get isAnonymous => user?.isAnonymous ?? true;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
    bool? hasCompletedOnboarding,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}

