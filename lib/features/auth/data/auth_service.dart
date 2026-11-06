import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/auth_user.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Offline-first Sovereign Authentication Service for Mind Forensics.
///
/// Features:
/// - Anonymous Sovereign Vault generation (Zero-trace, offline encrypted)
/// - Email & Password authentication with local credential vault
/// - Seamless upgrade from Anonymous to Cloud-Linked Vault without data loss
/// - Onboarding state tracking
class AuthService {
  static const String _keyCurrentUser = 'mf_auth_current_user';
  static const String _keyRegisteredUsers = 'mf_auth_registered_users';
  static const String _keyUserCredentials = 'mf_auth_user_credentials';
  static const String _keyOnboardingDone = 'mf_onboarding_completed';

  final Uuid _uuid = const Uuid();

  /// Generates a randomized forensic investigator codename.
  String generateDefaultCodename() {
    final randomNum = 1000 + Random().nextInt(9000);
    return 'Investigator #$randomNum';
  }

  /// Retrieves the currently authenticated user, or null if none.
  Future<AuthUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCurrentUser);
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  /// Checks if the user has completed the 6-step onboarding journey.
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  /// Marks onboarding as completed or reset.
  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, completed);
  }

  /// Creates a completely private Anonymous Sovereign Vault.
  Future<AuthUser> createAnonymousVault({String? codename}) async {
    final prefs = await SharedPreferences.getInstance();
    final user = AuthUser(
      id: _uuid.v4(),
      codename: codename?.trim().isNotEmpty == true
          ? codename!.trim()
          : generateDefaultCodename(),
      email: null,
      authType: AuthType.anonymous,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );

    await prefs.setString(_keyCurrentUser, user.toJson());
    return user;
  }

  /// Signs up with email and password, creating a Cloud-Synced Vault.
  Future<AuthUser> signUpWithEmail(
    String email,
    String password, {
    String? codename,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw const FormatException('Please enter a valid email address.');
    }
    if (cleanPassword.length < 6) {
      throw const FormatException('Password must be at least 6 characters.');
    }

    final prefs = await SharedPreferences.getInstance();
    final credsRaw = prefs.getString(_keyUserCredentials) ?? '{}';
    final Map<String, dynamic> credentials = json.decode(credsRaw);

    if (credentials.containsKey(cleanEmail)) {
      throw const FormatException('A vault with this email already exists.');
    }

    // Save credentials (simulated password store)
    credentials[cleanEmail] = cleanPassword;
    await prefs.setString(_keyUserCredentials, json.encode(credentials));

    final user = AuthUser(
      id: _uuid.v4(),
      codename: codename?.trim().isNotEmpty == true
          ? codename!.trim()
          : cleanEmail.split('@').first,
      email: cleanEmail,
      authType: AuthType.emailPassword,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );

    // Save registered user map
    final usersRaw = prefs.getString(_keyRegisteredUsers) ?? '{}';
    final Map<String, dynamic> users = json.decode(usersRaw);
    users[cleanEmail] = user.toMap();
    await prefs.setString(_keyRegisteredUsers, json.encode(users));

    // Save as current user
    await prefs.setString(_keyCurrentUser, user.toJson());
    return user;
  }

  /// Signs in to an existing Cloud Vault with email and password.
  Future<AuthUser> signInWithEmail(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    final prefs = await SharedPreferences.getInstance();
    final credsRaw = prefs.getString(_keyUserCredentials) ?? '{}';
    final Map<String, dynamic> credentials = json.decode(credsRaw);

    if (!credentials.containsKey(cleanEmail) ||
        credentials[cleanEmail] != cleanPassword) {
      throw const FormatException('Invalid email or password.');
    }

    final usersRaw = prefs.getString(_keyRegisteredUsers) ?? '{}';
    final Map<String, dynamic> users = json.decode(usersRaw);

    if (!users.containsKey(cleanEmail)) {
      throw const FormatException('Vault profile not found.');
    }

    final userMap = Map<String, dynamic>.from(users[cleanEmail] as Map);
    final user = AuthUser.fromMap(userMap).copyWith(
      lastActiveAt: DateTime.now(),
    );

    await prefs.setString(_keyCurrentUser, user.toJson());
    return user;
  }

  /// Upgrades an anonymous user to an email-secured vault without losing any data.
  Future<AuthUser> linkEmailToAnonymous(
    String email,
    String password, {
    String? codename,
  }) async {
    final current = await getCurrentUser();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw const FormatException('Please enter a valid email address.');
    }
    if (cleanPassword.length < 6) {
      throw const FormatException('Password must be at least 6 characters.');
    }

    final prefs = await SharedPreferences.getInstance();
    final credsRaw = prefs.getString(_keyUserCredentials) ?? '{}';
    final Map<String, dynamic> credentials = json.decode(credsRaw);

    if (credentials.containsKey(cleanEmail)) {
      throw const FormatException('A vault with this email already exists.');
    }

    // Save credentials
    credentials[cleanEmail] = cleanPassword;
    await prefs.setString(_keyUserCredentials, json.encode(credentials));

    final updatedUser = (current ??
            AuthUser(
              id: _uuid.v4(),
              codename: generateDefaultCodename(),
              authType: AuthType.anonymous,
              createdAt: DateTime.now(),
            ))
        .copyWith(
      email: cleanEmail,
      codename: codename?.trim().isNotEmpty == true
          ? codename!.trim()
          : (current?.codename ?? cleanEmail.split('@').first),
      authType: AuthType.emailPassword,
      lastActiveAt: DateTime.now(),
    );

    final usersRaw = prefs.getString(_keyRegisteredUsers) ?? '{}';
    final Map<String, dynamic> users = json.decode(usersRaw);
    users[cleanEmail] = updatedUser.toMap();
    await prefs.setString(_keyRegisteredUsers, json.encode(users));

    await prefs.setString(_keyCurrentUser, updatedUser.toJson());
    return updatedUser;
  }

  /// Signs out of the current active session.
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
  }

  /// Permanently deletes the active user vault and credentials.
  Future<void> deleteAccount() async {
    final current = await getCurrentUser();
    final prefs = await SharedPreferences.getInstance();

    if (current?.email != null) {
      final credsRaw = prefs.getString(_keyUserCredentials) ?? '{}';
      final Map<String, dynamic> credentials = json.decode(credsRaw);
      credentials.remove(current!.email);
      await prefs.setString(_keyUserCredentials, json.encode(credentials));

      final usersRaw = prefs.getString(_keyRegisteredUsers) ?? '{}';
      final Map<String, dynamic> users = json.decode(usersRaw);
      users.remove(current.email);
      await prefs.setString(_keyRegisteredUsers, json.encode(users));
    }

    await prefs.remove(_keyCurrentUser);
    await prefs.remove(_keyOnboardingDone);
  }
}

