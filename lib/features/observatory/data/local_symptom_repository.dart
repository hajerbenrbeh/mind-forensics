import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/security/encrypted_storage_helper.dart';
import '../../../core/security/secure_key_manager.dart';
import '../domain/default_symptom_library.dart';
import '../domain/symptom_entry.dart';
import '../domain/symptom_report.dart';

final symptomRepositoryProvider = Provider<LocalSymptomRepository>((ref) {
  final keyManager = ref.watch(secureKeyManagerProvider);
  return LocalSymptomRepository(keyManager: keyManager);
});

class LocalSymptomRepository {
  LocalSymptomRepository({SecureKeyManager? keyManager})
      : _keyManager = keyManager ?? SecureKeyManager();

  final SecureKeyManager _keyManager;
  static const String _customSymptomsKey = 'mf_custom_symptoms_v1';
  static const String _reportsKey = 'mf_symptom_reports_v1';

  // ---------------------------------------------------------------------------
  // Symptoms (Default Library + Custom Symptoms)
  // ---------------------------------------------------------------------------

  Future<List<SymptomEntry>> getAllSymptoms() async {
    final custom = await getCustomSymptoms();
    return [...DefaultSymptomLibrary.entries, ...custom];
  }

  Future<List<SymptomEntry>> getCustomSymptoms() async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _keyManager.getCipherForUser('observatory_symptoms');
    final raw = await EncryptedStorageHelper.readAndMigrate(
      prefs: prefs,
      key: _customSymptomsKey,
      cipher: cipher,
    );
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => SymptomEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomSymptom(SymptomEntry symptom) async {
    final custom = await getCustomSymptoms();
    final index = custom.indexWhere((s) => s.id == symptom.id);
    if (index != -1) {
      custom[index] = symptom;
    } else {
      custom.add(symptom);
    }

    final prefs = await SharedPreferences.getInstance();
    final cipher = await _keyManager.getCipherForUser('observatory_symptoms');
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: _customSymptomsKey,
      plaintext: jsonEncode(custom.map((s) => s.toJson()).toList()),
      cipher: cipher,
    );
  }

  Future<void> deleteCustomSymptom(String id) async {
    final custom = await getCustomSymptoms();
    custom.removeWhere((s) => s.id == id);

    final prefs = await SharedPreferences.getInstance();
    final cipher = await _keyManager.getCipherForUser('observatory_symptoms');
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: _customSymptomsKey,
      plaintext: jsonEncode(custom.map((s) => s.toJson()).toList()),
      cipher: cipher,
    );
  }

  // ---------------------------------------------------------------------------
  // Symptom Reports (Longitudinal Logging & Analysis)
  // ---------------------------------------------------------------------------

  Future<List<SymptomReport>> getAllReports() async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = await _keyManager.getCipherForUser('observatory_reports');
    final raw = await EncryptedStorageHelper.readAndMigrate(
      prefs: prefs,
      key: _reportsKey,
      cipher: cipher,
    );
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      final reports = list
          .map((item) => SymptomReport.fromJson(item as Map<String, dynamic>))
          .toList();
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveReport(SymptomReport report) async {
    final reports = await getAllReports();
    final index = reports.indexWhere((r) => r.id == report.id);
    if (index != -1) {
      reports[index] = report;
    } else {
      reports.insert(0, report);
    }

    final prefs = await SharedPreferences.getInstance();
    final cipher = await _keyManager.getCipherForUser('observatory_reports');
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: _reportsKey,
      plaintext: jsonEncode(reports.map((r) => r.toJson()).toList()),
      cipher: cipher,
    );
  }

  Future<void> deleteReport(String id) async {
    final reports = await getAllReports();
    reports.removeWhere((r) => r.id == id);

    final prefs = await SharedPreferences.getInstance();
    final cipher = await _keyManager.getCipherForUser('observatory_reports');
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: _reportsKey,
      plaintext: jsonEncode(reports.map((r) => r.toJson()).toList()),
      cipher: cipher,
    );
  }

  /// Calculates frequency of each symptom ID over a given day window.
  Future<Map<String, int>> getSymptomFrequencies({int days = 14}) async {
    final reports = await getAllReports();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recent = reports.where((r) => r.createdAt.isAfter(cutoff));

    final Map<String, int> counts = {};
    for (final r in recent) {
      for (final id in r.symptomIds) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    return counts;
  }
}

