import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/security/encrypted_storage_helper.dart';
import '../../../core/security/secure_key_manager.dart';
import '../domain/journey_state_model.dart';
import 'default_journey_curriculum.dart';

abstract class JourneyRepository {
  Future<JourneyStateModel> getJourneyState();
  Future<void> saveJourneyState(JourneyStateModel state);
  Future<void> resetJourneyProgress();
}

class LocalJourneyRepository implements JourneyRepository {
  LocalJourneyRepository({this.userId, SecureKeyManager? keyManager})
      : _keyManager = keyManager ?? SecureKeyManager();

  final String? userId;
  final SecureKeyManager _keyManager;

  static const String _legacyJourneyKey = 'mf_journey_progress_v1';

  String get _prefJourneyKey {
    if (userId != null && userId!.trim().isNotEmpty && userId != 'local_user') {
      return 'mf_journey_progress_${userId!.trim()}';
    }
    return _legacyJourneyKey;
  }

  @override
  Future<JourneyStateModel> getJourneyState() async {
    final defaultActivities = DefaultJourneyCurriculum.getActivities();
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _keyManager.getCipherForUser(userId);

    var raw = await EncryptedStorageHelper.readAndMigrate(
      prefs: prefs,
      key: _prefJourneyKey,
      cipher: cipher,
    );

    // Backward-compatibility: fallback to legacy key if user-specific key is fresh
    if ((raw == null || raw.trim().isEmpty) &&
        _prefJourneyKey != _legacyJourneyKey &&
        (userId == null || userId == 'local_user')) {
      final legacyCipher = await _keyManager.getCipherForUser(null);
      raw = await EncryptedStorageHelper.readAndMigrate(
        prefs: prefs,
        key: _legacyJourneyKey,
        cipher: legacyCipher,
      );
    }

    if (raw == null || raw.trim().isEmpty) {
      return JourneyStateModel(
        activities: defaultActivities,
        updatedAt: DateTime.now(),
      );
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return JourneyStateModel.fromJson(decoded, defaultActivities);
    } catch (_) {
      return JourneyStateModel(
        activities: defaultActivities,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> saveJourneyState(JourneyStateModel state) async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _keyManager.getCipherForUser(userId);
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: _prefJourneyKey,
      plaintext: jsonEncode(state.toJson()),
      cipher: cipher,
    );
  }

  @override
  Future<void> resetJourneyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefJourneyKey);
  }
}
