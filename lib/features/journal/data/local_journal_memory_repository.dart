import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/security/encrypted_storage_helper.dart';
import '../../../core/security/secure_key_manager.dart';
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

/// Sovereign local repository storing compressed journal memories with AES-256-GCM encryption.
///
/// Section 8 & Step 3.2:
/// - 100% on-device offline storage.
/// - Isolated per user ID (`mf_journal_memories_${userId}`).
/// - Encrypted at rest via authenticated AES-GCM.
/// - Catches JSON errors gracefully to prevent crashes.
class LocalJournalMemoryRepository implements JournalMemoryRepository {
  LocalJournalMemoryRepository({this.userId, SecureKeyManager? keyManager})
      : _keyManager = keyManager ?? SecureKeyManager();

  final String? userId;
  final SecureKeyManager _keyManager;

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
    final cipher = await _keyManager.getCipherForUser(userId);

    var raw = await EncryptedStorageHelper.readAndMigrate(
      prefs: prefs,
      key: _storageKey,
      cipher: cipher,
    );

    if ((raw == null || raw.isEmpty) && _storageKey != _legacyKey && (userId == null || userId == 'local_user')) {
      final legacyCipher = await _keyManager.getCipherForUser(null);
      raw = await EncryptedStorageHelper.readAndMigrate(
        prefs: prefs,
        key: _legacyKey,
        cipher: legacyCipher,
      );
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
    final cipher = await _keyManager.getCipherForUser(userId);

    final raw = await EncryptedStorageHelper.readAndMigrate(
      prefs: prefs,
      key: _suppressedKey,
      cipher: cipher,
    );

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.map((e) => e.toString()).toSet();
      } catch (_) {}
    }

    // Fallback to legacy string list if present
    final list = prefs.getStringList(_suppressedKey);
    return (list ?? []).toSet();
  }

  @override
  Future<void> suppressKey(String dedupKey) async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _keyManager.getCipherForUser(userId);
    final current = await getSuppressedKeys();
    current.add(dedupKey);
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: _suppressedKey,
      plaintext: jsonEncode(current.toList()),
      cipher: cipher,
    );
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
    final cipher = await _keyManager.getCipherForUser(userId);
    final raw = jsonEncode(memories.map((m) => m.toJson()).toList());
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: _storageKey,
      plaintext: raw,
      cipher: cipher,
    );
  }
}
