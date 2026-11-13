import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
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
/// - Anonymous Sovereign Account generation (Zero-trace, offline storage)
/// - Email & Password authentication with salted SHA-256 password hashing
/// - Seamless upgrade from Anonymous to Cloud-Linked Account without data loss
/// - Onboarding state tracking
class AuthService {
  static const String _keyCurrentUser = 'mf_auth_current_user';
  static const String _keyRegisteredUsers = 'mf_auth_registered_users';
  static const String _keyUserCredentials = 'mf_auth_user_credentials';
  static const String _keyOnboardingDone = 'mf_onboarding_completed';

  final Uuid _uuid = const Uuid();

  static const int kPbkdf2Iterations = 10000;
  static const int kPbkdf2KeyLength = 32;
  static const String kPbkdf2Prefix = 'pbkdf2_sha256';

  /// Generates 16 cryptographically secure random bytes for salting.
  static Uint8List generateSecureSalt([int length = 16]) {
    final random = Random.secure();
    final values = Uint8List(length);
    for (var i = 0; i < length; i++) {
      values[i] = random.nextInt(256);
    }
    return values;
  }

  /// Implements standard RFC 8018 PBKDF2 with HMAC-SHA256.
  static Uint8List _pbkdf2HmacSha256({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int keyLength,
  }) {
    final hmac = Hmac(sha256, password);
    const hLen = 32;
    final l = (keyLength / hLen).ceil();
    final r = keyLength - (l - 1) * hLen;

    final derivedKey = Uint8List(keyLength);
    var outOffset = 0;

    for (var i = 1; i <= l; i++) {
      final blockIndexBytes = ByteData(4)..setUint32(0, i, Endian.big);
      final initialData = Uint8List(salt.length + 4)
        ..setRange(0, salt.length, salt)
        ..setRange(salt.length, salt.length + 4, blockIndexBytes.buffer.asUint8List());

      var u = Uint8List.fromList(hmac.convert(initialData).bytes);
      final ti = Uint8List.fromList(u);

      for (var j = 1; j < iterations; j++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var k = 0; k < hLen; k++) {
          ti[k] ^= u[k];
        }
      }

      final bytesToCopy = (i == l) ? r : hLen;
      derivedKey.setRange(outOffset, outOffset + bytesToCopy, ti.sublist(0, bytesToCopy));
      outOffset += bytesToCopy;
    }

    return derivedKey;
  }

  /// Constant-time comparison to prevent timing attacks.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Hashes a password using PBKDF2-HMAC-SHA256 with a cryptographically secure random salt.
  /// Formatted as: pbkdf2_sha256${iterations}${saltBase64}${derivedKeyBase64}
  static String hashPassword(String password, {Uint8List? explicitSalt, int iterations = kPbkdf2Iterations}) {
    final salt = explicitSalt ?? generateSecureSalt(16);
    final derivedKey = _pbkdf2HmacSha256(
      password: utf8.encode(password),
      salt: salt,
      iterations: iterations,
      keyLength: kPbkdf2KeyLength,
    );
    final saltB64 = base64Url.encode(salt);
    final keyB64 = base64Url.encode(derivedKey);
    return '$kPbkdf2Prefix\$$iterations\$$saltB64\$$keyB64';
  }

  /// Verifies a password against a stored record with support for:
  /// - Format 3: PBKDF2-HMAC-SHA256 (Current)
  /// - Format 2: Salted SHA-256 (Legacy Stage 2: salt:hash)
  /// - Format 1: Plaintext (Legacy Stage 1)
  /// Returns a record: (isValid: bool, needsRehash: bool)
  static ({bool isValid, bool needsRehash}) verifyPasswordWithMigration(String password, String storedRecord) {
    if (storedRecord.isEmpty) {
      return (isValid: false, needsRehash: false);
    }

    // Format 3: PBKDF2-HMAC-SHA256
    if (storedRecord.startsWith('$kPbkdf2Prefix\$')) {
      final parts = storedRecord.split('\$');
      if (parts.length != 4) {
        return (isValid: false, needsRehash: false);
      }
      final iterations = int.tryParse(parts[1]);
      if (iterations == null || iterations <= 0) {
        return (isValid: false, needsRehash: false);
      }
      try {
        final salt = base64Url.decode(parts[2]);
        final expectedKey = base64Url.decode(parts[3]);
        final derived = _pbkdf2HmacSha256(
          password: utf8.encode(password),
          salt: salt,
          iterations: iterations,
          keyLength: expectedKey.length,
        );
        final isValid = constantTimeEquals(derived, expectedKey);
        final needsRehash = iterations < kPbkdf2Iterations;
        return (isValid: isValid, needsRehash: needsRehash);
      } catch (_) {
        return (isValid: false, needsRehash: false);
      }
    }

    // Format 2: Legacy Stage 2 (salt:sha256Hash)
    if (storedRecord.contains(':')) {
      final colonIndex = storedRecord.indexOf(':');
      final salt = storedRecord.substring(0, colonIndex);
      final expectedHash = storedRecord.substring(colonIndex + 1);
      final actualHash = sha256.convert(utf8.encode('$salt:$password')).toString();
      final isValid = constantTimeEquals(utf8.encode(actualHash), utf8.encode(expectedHash));
      return (isValid: isValid, needsRehash: true);
    }

    // Format 1: Legacy Stage 1 Plaintext
    final isValid = constantTimeEquals(utf8.encode(password), utf8.encode(storedRecord));
    return (isValid: isValid, needsRehash: true);
  }

  /// Generates a randomized default user alias.
  String generateDefaultCodename() {
    final randomNum = 1000 + Random().nextInt(9000);
    return 'Observer #$randomNum';
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

  /// Creates a completely private Anonymous Sovereign Account.
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

  /// Signs up with email and password, creating a Cloud-Synced Account with salted hash.
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
      throw const FormatException('An account with this email already exists.');
    }

    // Save PBKDF2-HMAC-SHA256 hash with unique cryptographically secure salt
    credentials[cleanEmail] = hashPassword(cleanPassword);
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

  /// Signs in to an existing Account with PBKDF2 verification and legacy re-hashing.
  Future<AuthUser> signInWithEmail(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    final prefs = await SharedPreferences.getInstance();
    final credsRaw = prefs.getString(_keyUserCredentials) ?? '{}';
    final Map<String, dynamic> credentials = json.decode(credsRaw);

    if (!credentials.containsKey(cleanEmail)) {
      throw const FormatException('Invalid email or password.');
    }

    final verifyResult = verifyPasswordWithMigration(
      cleanPassword,
      credentials[cleanEmail].toString(),
    );

    if (!verifyResult.isValid) {
      throw const FormatException('Invalid email or password.');
    }

    // Transparently upgrade legacy format credentials to PBKDF2-HMAC-SHA256
    if (verifyResult.needsRehash) {
      credentials[cleanEmail] = hashPassword(cleanPassword);
      await prefs.setString(_keyUserCredentials, json.encode(credentials));
    }

    final usersRaw = prefs.getString(_keyRegisteredUsers) ?? '{}';
    final Map<String, dynamic> users = json.decode(usersRaw);

    if (!users.containsKey(cleanEmail)) {
      throw const FormatException('Account profile not found.');
    }

    final userMap = Map<String, dynamic>.from(users[cleanEmail] as Map);
    final user = AuthUser.fromMap(userMap).copyWith(
      lastActiveAt: DateTime.now(),
    );

    await prefs.setString(_keyCurrentUser, user.toJson());
    return user;
  }

  /// Upgrades an anonymous user to an email-secured account without losing any data.
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
      throw const FormatException('An account with this email already exists.');
    }

    // Save PBKDF2-HMAC-SHA256 hash
    credentials[cleanEmail] = hashPassword(cleanPassword);
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

  /// Permanently deletes the active user account, credentials, and data partitions.
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

    if (current != null) {
      final uid = current.id;
      await prefs.remove('mind_forensics_cases_$uid');
      await prefs.remove('mf_mind_traces_$uid');
      await prefs.remove('mf_profile_$uid');
      await prefs.remove('mf_journal_memories_$uid');
      await prefs.remove('mf_journey_state_$uid');
      await prefs.remove('mf_symptom_reports_$uid');
      await prefs.remove('mf_custom_symptoms_$uid');
    }

    await prefs.remove(_keyCurrentUser);
    await prefs.remove(_keyOnboardingDone);
  }
}

