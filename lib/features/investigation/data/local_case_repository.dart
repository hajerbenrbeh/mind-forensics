import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/security/encrypted_storage_helper.dart';
import '../../../core/security/secure_key_manager.dart';
import '../domain/case_model.dart';
import '../domain/case_repository.dart';

/// Persistent local repository implementation with AES-256-GCM encryption at rest.
///
/// Keeps user cases and AI Companion conversations stored securely and offline
/// on the device across sessions, with multi-user isolation and authenticated encryption.
class LocalCaseRepository implements CaseRepository {
  LocalCaseRepository({this.userId, SecureKeyManager? keyManager})
      : _keyManager = keyManager ?? SecureKeyManager();

  final String? userId;
  final SecureKeyManager _keyManager;

  static const String _legacyKeyCases = 'mind_forensics_cases_store_v1';
  static const String _keyCounter = 'mind_forensics_case_counter_v1';

  String get _storageKey => userId != null && userId!.trim().isNotEmpty
      ? 'mind_forensics_cases_${userId!.trim()}'
      : _legacyKeyCases;

  Map<String, CaseModel>? _cache;
  Future<Map<String, CaseModel>>? _loadingFuture;
  int? _cachedCounter;
  Future<void> _counterLock = Future.value();

  Future<Map<String, CaseModel>> _ensureLoaded() {
    if (_cache != null) return Future.value(_cache!);
    if (_loadingFuture != null) return _loadingFuture!;

    _loadingFuture = _loadFromStorage();
    return _loadingFuture!;
  }

  Future<Map<String, CaseModel>> _loadFromStorage() async {
    final cache = <String, CaseModel>{};
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _keyManager.getCipherForUser(userId);

    String? rawJson = await EncryptedStorageHelper.readAndMigrate(
      prefs: prefs,
      key: _storageKey,
      cipher: cipher,
    );

    // Backward-compatibility: fallback to legacy key ONLY if user is anonymous or local default
    if ((rawJson == null || rawJson.isEmpty) &&
        _storageKey != _legacyKeyCases &&
        (userId == null || userId == 'local_user')) {
      final legacyCipher = await _keyManager.getCipherForUser(null);
      rawJson = await EncryptedStorageHelper.readAndMigrate(
        prefs: prefs,
        key: _legacyKeyCases,
        cipher: legacyCipher,
      );
    }

    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final model = CaseModel.fromJson(item);
            cache[model.id] = model;
          }
        }
      } catch (_) {
        // Fallback to empty cache on corrupted data
      }
    }
    _cache = cache;
    _loadingFuture = null;
    return _cache!;
  }

  Future<void> _persist() async {
    if (_cache == null) return;
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _keyManager.getCipherForUser(userId);
    final list = _cache!.values.map((c) => c.toJson()).toList();
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: _storageKey,
      plaintext: jsonEncode(list),
      cipher: cipher,
    );
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
    _cachedCounter = 1;
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
  Future<String> getNextCaseNumber() {
    final next = _counterLock.then((_) => _getNextCaseNumberInternal());
    _counterLock = next.catchError((_) => '');
    return next;
  }

  Future<String> _getNextCaseNumberInternal() async {
    final prefs = await SharedPreferences.getInstance();

    if (_cachedCounter == null) {
      final storedCounter = prefs.getInt(_keyCounter) ?? 1;
      final map = await _ensureLoaded();
      int maxFromCases = 0;
      for (final c in map.values) {
        final match = RegExp(r'\d+').firstMatch(c.caseNumber);
        if (match != null) {
          final num = int.tryParse(match.group(0) ?? '') ?? 0;
          if (num > maxFromCases) maxFromCases = num;
        }
      }
      _cachedCounter = maxFromCases >= storedCounter ? maxFromCases + 1 : storedCounter;
    }

    final allocated = _cachedCounter!;
    _cachedCounter = allocated + 1;
    await prefs.setInt(_keyCounter, allocated + 1);
    final formatted = allocated.toString().padLeft(2, '0');
    return 'SESSION $formatted';
  }
}
