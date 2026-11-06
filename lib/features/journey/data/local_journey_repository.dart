import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/journey_state_model.dart';
import 'default_journey_curriculum.dart';

abstract class JourneyRepository {
  Future<JourneyStateModel> getJourneyState();
  Future<void> saveJourneyState(JourneyStateModel state);
  Future<void> resetJourneyProgress();
}

class LocalJourneyRepository implements JourneyRepository {
  LocalJourneyRepository({this.userId});

  final String? userId;

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
    var raw = prefs.getString(_prefJourneyKey);

    // Backward-compatibility: fallback to legacy key if user-specific key is fresh
    if ((raw == null || raw.trim().isEmpty) && _prefJourneyKey != _legacyJourneyKey) {
      raw = prefs.getString(_legacyJourneyKey);
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
    await prefs.setString(_prefJourneyKey, jsonEncode(state.toJson()));
  }

  @override
  Future<void> resetJourneyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefJourneyKey);
  }
}
