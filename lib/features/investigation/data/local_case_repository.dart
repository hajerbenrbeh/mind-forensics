import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/case_model.dart';
import '../domain/case_repository.dart';

/// Persistent local repository implementation using SharedPreferences.
///
/// Keeps user cases and AI Companion conversations stored securely and offline
/// on the device across sessions, with multi-user isolation by [userId].
class LocalCaseRepository implements CaseRepository {
  LocalCaseRepository({this.userId});

  final String? userId;

  static const String _legacyKeyCases = 'mind_forensics_cases_store_v1';
  static const String _keyCounter = 'mind_forensics_case_counter_v1';

  String get _storageKey => userId != null && userId!.trim().isNotEmpty
      ? 'mind_forensics_cases_${userId!.trim()}'
      : _legacyKeyCases;

  Map<String, CaseModel>? _cache;

  Future<Map<String, CaseModel>> _ensureLoaded() async {
    if (_cache != null) return _cache!;
    _cache = {};

    final prefs = await SharedPreferences.getInstance();
    String? rawJson = prefs.getString(_storageKey);

    // Backward-compatibility: fallback to legacy key if user-specific key is empty
    if ((rawJson == null || rawJson.isEmpty) && _storageKey != _legacyKeyCases) {
      rawJson = prefs.getString(_legacyKeyCases);
    }

    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final model = CaseModel.fromJson(item);
            _cache![model.id] = model;
          }
        }
      } catch (_) {
        // Fallback to empty cache on corrupted data
      }
    }
    return _cache!;
  }

  Future<void> _persist() async {
    if (_cache == null) return;
    final prefs = await SharedPreferences.getInstance();
    final list = _cache!.values.map((c) => c.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(list));
  }

  @override
  Future<List<CaseModel>> getAllCases() async {
    final map = await _ensureLoaded();
    final list = map.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<CaseModel?> getCaseById(String id) async {
    final map = await _ensureLoaded();
    return map[id];
  }

  @override
  Future<void> saveCase(CaseModel caseModel) async {
    final map = await _ensureLoaded();
    map[caseModel.id] = caseModel;
    await _persist();
  }

  @override
  Future<void> deleteCase(String id) async {
    final map = await _ensureLoaded();
    map.remove(id);
    await _persist();
  }

  @override
  Future<void> renameCase(String id, String newTitle) async {
    final map = await _ensureLoaded();
    final current = map[id];
    if (current != null) {
      map[id] = current.copyWith(
        title: newTitle.trim(),
        updatedAt: DateTime.now(),
      );
      await _persist();
    }
  }

  @override
  Future<void> deleteAllCases() async {
    final map = await _ensureLoaded();
    map.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_legacyKeyCases);
    await prefs.setInt(_keyCounter, 1);
  }

  @override
  Future<void> toggleCasePrivacy(String id) async {
    final map = await _ensureLoaded();
    final current = map[id];
    if (current != null) {
      map[id] = current.copyWith(isPrivate: !current.isPrivate);
      await _persist();
    }
  }

  @override
  Future<String> getNextCaseNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyCounter) ?? 1;
    await prefs.setInt(_keyCounter, current + 1);
    final formatted = current.toString().padLeft(2, '0');
    return 'SESSION $formatted';
  }
}
