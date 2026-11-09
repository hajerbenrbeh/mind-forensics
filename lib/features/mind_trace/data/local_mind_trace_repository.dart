import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/security/encrypted_storage_helper.dart';
import '../../../core/security/secure_key_manager.dart';
import '../domain/mind_trace_model.dart';

abstract class MindTraceRepository {
  Future<List<MindTraceModel>> getAllTraces();
  Future<MindTraceModel?> getTodayTrace();
  Future<void> saveTrace(MindTraceModel trace);
  Future<void> deleteTrace(String id);
  Future<void> clearAllTraces();
}

class LocalMindTraceRepository implements MindTraceRepository {
  LocalMindTraceRepository({this.userId, SecureKeyManager? keyManager})
      : _keyManager = keyManager ?? SecureKeyManager();

  final String? userId;
  final SecureKeyManager _keyManager;

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
    final cipher = await _keyManager.getCipherForUser(userId);

    var raw = await EncryptedStorageHelper.readAndMigrate(
      prefs: prefs,
      key: _storageKey,
      cipher: cipher,
    );

    // Fallback check to legacy key ONLY if user is anonymous or local default
    if ((raw == null || raw.isEmpty) &&
        _storageKey != _legacyStorageKey &&
        (userId == null || userId == 'local_user')) {
      final legacyCipher = await _keyManager.getCipherForUser(null);
      raw = await EncryptedStorageHelper.readAndMigrate(
        prefs: prefs,
        key: _legacyStorageKey,
        cipher: legacyCipher,
      );
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
    final cipher = await _keyManager.getCipherForUser(userId);
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
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: _storageKey,
      plaintext: raw,
      cipher: cipher,
    );
  }

  @override
  Future<void> deleteTrace(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _keyManager.getCipherForUser(userId);
    final all = await getAllTraces();
    all.removeWhere((t) => t.id == id);

    final raw = jsonEncode(all.map((t) => t.toJson()).toList());
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: _storageKey,
      plaintext: raw,
      cipher: cipher,
    );
  }

  @override
  Future<void> clearAllTraces() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
