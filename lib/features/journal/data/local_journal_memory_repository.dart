import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/journal_memory_model.dart';

abstract class JournalMemoryRepository {
  Future<List<JournalMemoryModel>> getAllMemories();
  Future<JournalMemoryModel?> getMemoryById(String id);
  Future<void> saveMemory(JournalMemoryModel memory);
  Future<void> saveAllMemories(List<JournalMemoryModel> memories);
  Future<void> deleteMemory(String id);
  Future<void> clearAllMemories();

  /// Persistent suppression of deleted memories (Section 3).
  Future<Set<String>> getSuppressedKeys();
  Future<void> suppressKey(String dedupKey);
  Future<void> clearSuppressedKeys();
}

/// Sovereign local repository storing compressed journal memories in SharedPreferences.
///
/// Section 8 & Step 3.2:
/// - 100% on-device offline storage.
/// - Isolated per user ID (`mf_journal_memories_${userId}`).
/// - Catches JSON errors gracefully to prevent crashes.
class LocalJournalMemoryRepository implements JournalMemoryRepository {
  LocalJournalMemoryRepository({this.userId});

  final String? userId;

  static const String _legacyKey = 'mf_journal_memories_v1';
  static const String _legacySuppressedKey = 'mf_journal_suppressed_keys_v1';

  String get _storageKey {
    if (userId != null && userId!.trim().isNotEmpty && userId != 'local_user') {
      return 'mf_journal_memories_${userId!.trim()}';
    }
    return _legacyKey;
  }

  String get _suppressedKey {
    if (userId != null && userId!.trim().isNotEmpty && userId != 'local_user') {
      return 'mf_journal_suppressed_keys_${userId!.trim()}';
    }
    return _legacySuppressedKey;
  }

  @override
  Future<List<JournalMemoryModel>> getAllMemories() async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(_storageKey);

    if ((raw == null || raw.isEmpty) && _storageKey != _legacyKey) {
      raw = prefs.getString(_legacyKey);
    }

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .map((item) => JournalMemoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
      // Sort newest observations first
      list.sort((a, b) => b.lastObservedDate.compareTo(a.lastObservedDate));
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<JournalMemoryModel?> getMemoryById(String id) async {
    final all = await getAllMemories();
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  Future<void> saveMemory(JournalMemoryModel memory) async {
    final all = await getAllMemories();
    final index = all.indexWhere((m) => m.id == memory.id);
    if (index != -1) {
      all[index] = memory;
    } else {
      all.insert(0, memory);
    }
    await _persist(all);
  }

  @override
  Future<void> saveAllMemories(List<JournalMemoryModel> memories) async {
    await _persist(memories);
  }

  @override
  Future<void> deleteMemory(String id) async {
    final all = await getAllMemories();
    all.removeWhere((m) => m.id == id);
    await _persist(all);
  }

  @override
  Future<void> clearAllMemories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  @override
  Future<Set<String>> getSuppressedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    var list = prefs.getStringList(_suppressedKey);
    if ((list == null || list.isEmpty) && _suppressedKey != _legacySuppressedKey) {
      list = prefs.getStringList(_legacySuppressedKey);
    }
    return (list ?? []).toSet();
  }

  @override
  Future<void> suppressKey(String dedupKey) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getSuppressedKeys();
    current.add(dedupKey);
    await prefs.setStringList(_suppressedKey, current.toList());
  }

  @override
  Future<void> clearSuppressedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_suppressedKey);
    if (_suppressedKey != _legacySuppressedKey) {
      await prefs.remove(_legacySuppressedKey);
    }
  }

  Future<void> _persist(List<JournalMemoryModel> memories) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(memories.map((m) => m.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
