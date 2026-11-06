import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/mind_trace_model.dart';

abstract class MindTraceRepository {
  Future<List<MindTraceModel>> getAllTraces();
  Future<MindTraceModel?> getTodayTrace();
  Future<void> saveTrace(MindTraceModel trace);
  Future<void> deleteTrace(String id);
  Future<void> clearAllTraces();
}

class LocalMindTraceRepository implements MindTraceRepository {
  LocalMindTraceRepository({this.userId});

  final String? userId;

  static const String _legacyStorageKey = 'mf_mind_traces_v1';

  String get _storageKey {
    if (userId != null && userId!.trim().isNotEmpty && userId != 'local_user') {
      return 'mf_mind_traces_${userId!.trim()}';
    }
    return _legacyStorageKey;
  }

  @override
  Future<List<MindTraceModel>> getAllTraces() async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(_storageKey);

    // Fallback check to legacy key if user-specific key is fresh
    if ((raw == null || raw.isEmpty) && _storageKey != _legacyStorageKey) {
      raw = prefs.getString(_legacyStorageKey);
    }

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .map((item) =>
              MindTraceModel.fromJson(item as Map<String, dynamic>))
          .toList();
      // Sort newest first
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<MindTraceModel?> getTodayTrace() async {
    final all = await getAllTraces();
    if (all.isEmpty) return null;

    final now = DateTime.now();
    final todayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    for (final trace in all) {
      if (trace.dateKey == todayKey) {
        return trace;
      }
    }
    return null;
  }

  @override
  Future<void> saveTrace(MindTraceModel trace) async {
    final prefs = await SharedPreferences.getInstance();
    final effectiveUser = userId ?? trace.userId;
    final updatedTrace = trace.copyWith(userId: effectiveUser);
    final all = await getAllTraces();

    // Prevent duplicate entries for the same date or matching ID
    final index = all.indexWhere(
        (t) => t.id == updatedTrace.id || t.dateKey == updatedTrace.dateKey);
    if (index != -1) {
      all[index] = updatedTrace;
    } else {
      all.insert(0, updatedTrace);
    }

    final raw = jsonEncode(all.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  @override
  Future<void> deleteTrace(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllTraces();
    all.removeWhere((t) => t.id == id);

    final raw = jsonEncode(all.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  @override
  Future<void> clearAllTraces() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
