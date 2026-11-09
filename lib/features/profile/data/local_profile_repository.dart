import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/security/encrypted_storage_helper.dart';
import '../../../core/security/secure_key_manager.dart';
import '../domain/psychological_profile_model.dart';

abstract class ProfileRepository {
  Future<PsychologicalProfileModel> getProfile({String? userId});
  Future<void> saveProfile(PsychologicalProfileModel profile, {String? userId});
  Future<void> clearProfile({String? userId});
}

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository({SecureKeyManager? keyManager})
      : _keyManager = keyManager ?? SecureKeyManager();

  final SecureKeyManager _keyManager;
  static const String _defaultProfileKey = 'mf_psychological_profile_v1';

  String _getKey(String? userId) {
    if (userId != null &&
        userId.trim().isNotEmpty &&
        userId != 'local_user') {
      return 'mf_psychological_profile_$userId';
    }
    return _defaultProfileKey;
  }

  @override
  Future<PsychologicalProfileModel> getProfile({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(userId);
    final cipher = await _keyManager.getCipherForUser(userId);

    var raw = await EncryptedStorageHelper.readAndMigrate(
      prefs: prefs,
      key: key,
      cipher: cipher,
    );

    // Fallback check to default profile if user-specific key is fresh
    if ((raw == null || raw.trim().isEmpty) && key != _defaultProfileKey) {
      final legacyCipher = await _keyManager.getCipherForUser(null);
      final defaultRaw = await EncryptedStorageHelper.readAndMigrate(
        prefs: prefs,
        key: _defaultProfileKey,
        cipher: legacyCipher,
      );
      if (defaultRaw != null && defaultRaw.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(defaultRaw) as Map<String, dynamic>;
          final model = PsychologicalProfileModel.fromJson(decoded);
          return model.copyWith(userId: userId);
        } catch (_) {}
      }
    }

    if (raw == null || raw.trim().isEmpty) {
      return PsychologicalProfileModel.empty(userId: userId ?? 'local_user');
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return PsychologicalProfileModel.fromJson(decoded);
    } catch (_) {
      return PsychologicalProfileModel.empty(userId: userId ?? 'local_user');
    }
  }

  @override
  Future<void> saveProfile(
    PsychologicalProfileModel profile, {
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final effectiveUser = userId ?? profile.userId;
    final key = _getKey(effectiveUser);
    final cipher = await _keyManager.getCipherForUser(effectiveUser);
    final updatedProfile = profile.copyWith(
      userId: effectiveUser,
      updatedAt: DateTime.now(),
    );
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: key,
      plaintext: jsonEncode(updatedProfile.toJson()),
      cipher: cipher,
    );
  }

  @override
  Future<void> clearProfile({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(userId);
    await prefs.remove(key);
  }
}
