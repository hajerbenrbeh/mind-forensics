import 'dart:convert';

/// The authentication method used to secure the mental vault.
enum AuthType {
  /// Zero-identity footprint, completely local and encrypted on device.
  anonymous,

  /// Remote cloud sync secured with email and password credentials.
  emailPassword,

  /// Local biometric authentication (fingerprint / Face ID).
  biometric,
}

/// The authenticated forensic user profile.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.codename,
    this.email,
    required this.authType,
    required this.createdAt,
    this.lastActiveAt,
  });

  /// Unique immutable identifier for the user's forensic vault.
  final String id;

  /// Private alias or display name (e.g., "Investigator #4092" or user-chosen codename).
  final String codename;

  /// Optional email address (null for anonymous sovereign vaults).
  final String? email;

  /// The primary authentication mechanism.
  final AuthType authType;

  /// Timestamp when the vault was first established.
  final DateTime createdAt;

  /// Timestamp of the most recent activity.
  final DateTime? lastActiveAt;

  /// Returns true if this is an anonymous vault with zero personal identifiable information.
  bool get isAnonymous => authType == AuthType.anonymous || email == null;

  AuthUser copyWith({
    String? id,
    String? codename,
    String? email,
    AuthType? authType,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      codename: codename ?? this.codename,
      email: email ?? this.email,
      authType: authType ?? this.authType,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codename': codename,
      'email': email,
      'authType': authType.name,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    };
  }

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: map['id'] as String,
      codename: map['codename'] as String? ?? 'Forensic Investigator',
      email: map['email'] as String?,
      authType: AuthType.values.firstWhere(
        (e) => e.name == map['authType'],
        orElse: () => AuthType.anonymous,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      lastActiveAt: map['lastActiveAt'] != null
          ? DateTime.tryParse(map['lastActiveAt'] as String)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AuthUser.fromJson(String source) =>
      AuthUser.fromMap(json.decode(source) as Map<String, dynamic>);
}

