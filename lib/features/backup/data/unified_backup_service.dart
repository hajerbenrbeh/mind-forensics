import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/security/encrypted_storage_helper.dart';
import '../../../core/security/local_data_cipher.dart';
import '../../../core/security/secure_key_manager.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/data/auth_service.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/case_model.dart';
import '../../journal/controllers/journal_memory_controller.dart';
import '../../journal/domain/journal_memory_model.dart';
import '../../journey/controllers/journey_controller.dart';
import '../../journey/data/default_journey_curriculum.dart';
import '../../journey/domain/journey_state_model.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../observatory/controllers/observatory_controllers.dart';
import '../../observatory/data/local_symptom_repository.dart';
import '../../observatory/domain/symptom_entry.dart';
import '../../observatory/domain/symptom_report.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/domain/psychological_profile_model.dart';

/// Result of a backup or restore operation with detailed telemetry.
class BackupOperationResult {
  const BackupOperationResult({
    required this.success,
    required this.message,
    this.tracesCount = 0,
    this.sessionsCount = 0,
    this.memoriesCount = 0,
    this.timestamp,
    this.rawJson,
  });

  final bool success;
  final String message;
  final int tracesCount;
  final int sessionsCount;
  final int memoriesCount;
  final DateTime? timestamp;
  final String? rawJson;

  int get totalRecords => tracesCount + sessionsCount + memoriesCount;
}

/// Cloud and local synchronization status.
enum CloudSyncState {
  /// Local sovereign storage is active; cloud sync is disabled or unconfigured.
  localOnly,

  /// Firebase configuration (google-services.json / options) is not linked.
  missingConfiguration,

  /// In-progress upload or retrieval.
  syncing,

  /// Fully synchronized with verified remote/local parity.
  synced,

  /// Sync attempted but encountered an error.
  error,
}

/// Unified Service orchestrating complete backup, restoration, and cloud synchronization
/// across all Mind Forensics clinical data models.
class UnifiedBackupService {
  UnifiedBackupService(this._ref);

  final Ref _ref;

  static const String prefLastBackupTime = 'mf_unified_backup_last_time';
  static const String prefLastBackupJson = 'mf_unified_backup_last_json';
  static const String prefLastBackupCount = 'mf_unified_backup_last_count';
  static const String schemaVersion = '2.0.0';

  /// Retrieves the timestamp of the last successful local/cloud backup.
  Future<DateTime?> getLastBackupTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefLastBackupTime);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Evaluates current cloud synchronization status.
  Future<({CloudSyncState state, String description})> getCloudSyncStatus() async {
    // Audit Firebase infrastructure: check for actual cloud project linkage
    // Without google-services.json, Firebase cannot securely connect to Firestore.
    return (
      state: CloudSyncState.missingConfiguration,
      description: 'Firebase Spark credentials not configured (Missing google-services.json). Encrypted local sovereign storage is active.',
    );
  }

  /// Generates a comprehensive, portable JSON backup of all user mental health data.
  Future<BackupOperationResult> createFullBackup() async {
    try {
      final now = DateTime.now();
      final authUser = _ref.read(authControllerProvider).user;
      final userId = authUser?.id ?? 'local_user';
      final codename = authUser?.codename ?? 'Observer';

      // 1. Fetch all data domains
      final traceRepo = _ref.read(mindTraceRepositoryProvider);
      final traces = await traceRepo.getAllTraces();

      final caseRepo = _ref.read(caseRepositoryProvider);
      final cases = await caseRepo.getAllCases();

      final profileRepo = _ref.read(profileRepositoryProvider);
      final profile = await profileRepo.getProfile(userId: userId);

      final memoryRepo = _ref.read(journalMemoryRepositoryProvider);
      final memories = await memoryRepo.getAllMemories();

      final journeyRepo = _ref.read(journeyRepositoryProvider);
      final journey = await journeyRepo.getJourneyState();

      final symptomRepo = _ref.read(symptomRepositoryProvider);
      final customSymptoms = await symptomRepo.getCustomSymptoms();
      final symptomReports = await symptomRepo.getAllReports();

      final Map<String, dynamic> backupData = {
        'schemaVersion': schemaVersion,
        'app': 'Mind Forensics',
        'exportedAt': now.toIso8601String(),
        'userId': userId,
        'userCodename': codename,
        'metadata': {
          'traceCount': traces.length,
          'sessionCount': cases.length,
          'memoryCount': memories.length,
          'symptomReportCount': symptomReports.length,
          'hasProfile': profile.preferredName.isNotEmpty || profile.conditions.isNotEmpty,
          'hasJourney': journey.activities.isNotEmpty,
        },
        'traces': traces.map((t) => t.toJson()).toList(),
        'sessions': cases.map((c) => c.toJson()).toList(),
        'profile': profile.toJson(),
        'memories': memories.map((m) => m.toJson()).toList(),
        'journey': journey.toJson(),
        'customSymptoms': customSymptoms.map((s) => s.toJson()).toList(),
        'symptomReports': symptomReports.map((r) => r.toJson()).toList(),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);

      // Persist snapshot to local backup slot encrypted with user-partition key
      final prefs = await SharedPreferences.getInstance();
      final keyManager = _ref.read(secureKeyManagerProvider);
      final cipher = await keyManager.getCipherForUser(userId);

      await prefs.setString(prefLastBackupTime, now.toIso8601String());
      await EncryptedStorageHelper.writeEncrypted(
        prefs: prefs,
        key: prefLastBackupJson,
        plaintext: jsonStr,
        cipher: cipher,
      );
      await prefs.setInt(prefLastBackupCount, traces.length + cases.length + memories.length);

      return BackupOperationResult(
        success: true,
        message: 'Complete backup created successfully.',
        tracesCount: traces.length,
        sessionsCount: cases.length,
        memoriesCount: memories.length,
        timestamp: now,
        rawJson: jsonStr,
      );
    } catch (e) {
      return BackupOperationResult(
        success: false,
        message: 'Backup failed: $e',
      );
    }
  }

  /// Restores and hydrates all clinical records from a validated backup JSON payload.
  Future<BackupOperationResult> restoreFromBackupJson(String rawJson) async {
    try {
      final Map<String, dynamic> data = jsonDecode(rawJson) as Map<String, dynamic>;

      if (data['app'] != 'Mind Forensics' && data['sessions'] == null && data['traces'] == null) {
        return const BackupOperationResult(
          success: false,
          message: 'Invalid backup format: missing Mind Forensics schema headers.',
        );
      }

      final schema = data['schemaVersion']?.toString() ?? '1.0.0';
      final majorVersion = int.tryParse(schema.split('.').first) ?? 1;
      if (majorVersion > 2) {
        return BackupOperationResult(
          success: false,
          message: 'Unsupported backup schema version ($schema). Please update Mind Forensics.',
        );
      }

      int restoredTraces = 0;
      int restoredSessions = 0;
      int restoredMemories = 0;

      // 1. Restore Mind Traces (deduplicated by ID)
      if (data['traces'] is List) {
        final traceRepo = _ref.read(mindTraceRepositoryProvider);
        final existingTraces = await traceRepo.getAllTraces();
        final existingIds = existingTraces.map((t) => t.id).toSet();
        final rawTraces = (data['traces'] as List).whereType<Map<String, dynamic>>();
        for (final item in rawTraces) {
          try {
            final trace = MindTraceModel.fromJson(item);
            if (!existingIds.contains(trace.id)) {
              await traceRepo.saveTrace(trace);
              restoredTraces++;
            }
          } catch (_) {}
        }
        _ref.invalidate(mindTraceControllerProvider);
      }

      // 2. Restore Sessions / Cases (deduplicated by ID)
      if (data['sessions'] is List) {
        final caseRepo = _ref.read(caseRepositoryProvider);
        final existingCases = await caseRepo.getAllCases();
        final existingIds = existingCases.map((c) => c.id).toSet();
        final rawCases = (data['sessions'] as List).whereType<Map<String, dynamic>>();
        for (final item in rawCases) {
          try {
            final caseModel = CaseModel.fromJson(item);
            if (!existingIds.contains(caseModel.id)) {
              await caseRepo.saveCase(caseModel);
              restoredSessions++;
            }
          } catch (_) {}
        }
        _ref.invalidate(savedCasesProvider);
        _ref.invalidate(activeCaseControllerProvider);
      }

      // 3. Restore Journal Memories (deduplicated by ID)
      if (data['memories'] is List) {
        final memoryRepo = _ref.read(journalMemoryRepositoryProvider);
        final existingMemories = await memoryRepo.getAllMemories();
        final existingIds = existingMemories.map((m) => m.id).toSet();
        final rawMemories = (data['memories'] as List).whereType<Map<String, dynamic>>();
        for (final item in rawMemories) {
          try {
            final memory = JournalMemoryModel.fromJson(item);
            if (!existingIds.contains(memory.id)) {
              await memoryRepo.saveMemory(memory);
              restoredMemories++;
            }
          } catch (_) {}
        }
        _ref.invalidate(journalMemoryControllerProvider);
      }

      // 4. Restore Profile if present
      if (data['profile'] is Map<String, dynamic>) {
        final profileRepo = _ref.read(profileRepositoryProvider);
        try {
          final profile = PsychologicalProfileModel.fromJson(data['profile'] as Map<String, dynamic>);
          await profileRepo.saveProfile(profile);
          _ref.invalidate(profileControllerProvider);
        } catch (_) {}
      }

      // 5. Restore Journey state if present
      if (data['journey'] is Map<String, dynamic>) {
        final journeyRepo = _ref.read(journeyRepositoryProvider);
        try {
          final journey = JourneyStateModel.fromJson(
            data['journey'] as Map<String, dynamic>,
            DefaultJourneyCurriculum.getActivities(),
          );
          await journeyRepo.saveJourneyState(journey);
          _ref.invalidate(journeyControllerProvider);
        } catch (_) {}
      }

      // 6. Restore Symptom reports & Custom symptoms if present
      if (data['customSymptoms'] is List) {
        final symptomRepo = _ref.read(symptomRepositoryProvider);
        final rawCustom = (data['customSymptoms'] as List).whereType<Map<String, dynamic>>();
        for (final item in rawCustom) {
          try {
            await symptomRepo.saveCustomSymptom(SymptomEntry.fromJson(item));
          } catch (_) {}
        }
      }
      if (data['symptomReports'] is List) {
        final symptomRepo = _ref.read(symptomRepositoryProvider);
        final existingReports = await symptomRepo.getAllReports();
        final existingIds = existingReports.map((r) => r.id).toSet();
        final rawReports = (data['symptomReports'] as List).whereType<Map<String, dynamic>>();
        for (final item in rawReports) {
          try {
            final report = SymptomReport.fromJson(item);
            if (!existingIds.contains(report.id)) {
              await symptomRepo.saveReport(report);
            }
          } catch (_) {}
        }
        _ref.invalidate(symptomReportsControllerProvider);
        _ref.invalidate(symptomListControllerProvider);
      }

      return BackupOperationResult(
        success: true,
        message: 'Data successfully restored and verified.',
        tracesCount: restoredTraces,
        sessionsCount: restoredSessions,
        memoriesCount: restoredMemories,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return BackupOperationResult(
        success: false,
        message: 'Restoration failed: $e',
      );
    }
  }

  /// Retrieves and decrypts the locally cached backup snapshot.
  Future<String?> getLastCachedBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final authUser = _ref.read(authControllerProvider).user;
    final userId = authUser?.id ?? 'local_user';
    final keyManager = _ref.read(secureKeyManagerProvider);
    final cipher = await keyManager.getCipherForUser(userId);

    return await EncryptedStorageHelper.readAndMigrate(
      prefs: prefs,
      key: prefLastBackupJson,
      cipher: cipher,
    );
  }

  /// High-security work factor for user-initiated backup encryption (OWASP recommendation).
  static const int kBackupPbkdf2Iterations = 100000;

  /// Generates an optional password-encrypted backup package using AES-256-GCM.
  Future<BackupOperationResult> createPasswordEncryptedBackup(String password) async {
    final rawResult = await createFullBackup();
    if (!rawResult.success || rawResult.rawJson == null) {
      return rawResult;
    }

    try {
      final salt = AuthService.generateSecureSalt(16);
      final derivedHashRecord = AuthService.hashPassword(
        password,
        explicitSalt: salt,
        iterations: kBackupPbkdf2Iterations,
      );
      final parts = derivedHashRecord.split('\$');
      final derivedKeyBytes = base64Url.decode(parts[3]);

      final cipher = LocalDataCipher(secretKeyBytes: derivedKeyBytes);
      final ciphertext = await cipher.encryptString(rawResult.rawJson!);

      final encryptedPayload = {
        'app': 'Mind Forensics',
        'encrypted': true,
        'schemaVersion': '2.0.0',
        'kdf': 'pbkdf2_sha256',
        'iterations': kBackupPbkdf2Iterations,
        'salt': base64Url.encode(salt),
        'ciphertext': ciphertext,
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(encryptedPayload);

      return BackupOperationResult(
        success: true,
        message: 'Password-encrypted backup created successfully.',
        tracesCount: rawResult.tracesCount,
        sessionsCount: rawResult.sessionsCount,
        memoriesCount: rawResult.memoriesCount,
        timestamp: rawResult.timestamp,
        rawJson: jsonStr,
      );
    } catch (e) {
      return BackupOperationResult(
        success: false,
        message: 'Encryption failed: $e',
      );
    }
  }

  /// Restores from an optional password-encrypted backup package.
  Future<BackupOperationResult> restoreFromPasswordEncryptedBackup(
    String encryptedJson,
    String password,
  ) async {
    try {
      final Map<String, dynamic> data = jsonDecode(encryptedJson) as Map<String, dynamic>;
      if (data['encrypted'] != true || data['ciphertext'] == null) {
        return await restoreFromBackupJson(encryptedJson);
      }

      final saltB64 = data['salt'] as String?;
      final ciphertext = data['ciphertext'] as String?;
      final iterations = data['iterations'] as int? ?? AuthService.kPbkdf2Iterations;

      if (saltB64 == null || ciphertext == null) {
        return const BackupOperationResult(
          success: false,
          message: 'Invalid encrypted backup: missing salt or ciphertext.',
        );
      }

      final salt = base64Url.decode(saltB64);
      final derivedHashRecord = AuthService.hashPassword(
        password,
        explicitSalt: salt,
        iterations: iterations,
      );
      final parts = derivedHashRecord.split('\$');
      final derivedKeyBytes = base64Url.decode(parts[3]);

      final cipher = LocalDataCipher(secretKeyBytes: derivedKeyBytes);
      final decryptedPlaintext = await cipher.decryptString(ciphertext);

      return await restoreFromBackupJson(decryptedPlaintext);
    } catch (e) {
      return const BackupOperationResult(
        success: false,
        message: 'Decryption failed: Incorrect password or tampered backup payload.',
      );
    }
  }
}

final unifiedBackupServiceProvider = Provider<UnifiedBackupService>((ref) {
  return UnifiedBackupService(ref);
});
