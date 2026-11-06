import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/clinical_export_record.dart';

/// Service managing the visible audit history of exported Session Briefs.
///
/// Section 12 Principle 5: "Visible history of what was shared, with whom, and when."
class ClinicalExportLogService {
  static const String _prefKey = 'mind_forensics_clinical_export_history_v1';

  /// Retrieves the chronological history of clinical exports.
  Future<List<ClinicalExportRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .whereType<Map<String, dynamic>>()
          .map((item) => ClinicalExportRecord.fromJson(item))
          .toList();
      list.sort((a, b) => b.exportedAt.compareTo(a.exportedAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Logs a new patient-initiated export event.
  Future<void> logExport({
    required List<String> sessionNumbers,
    String recipientOrNote = '',
  }) async {
    final current = await getRecords();
    final newRecord = ClinicalExportRecord(
      id: const Uuid().v4(),
      exportedAt: DateTime.now(),
      sessionNumbers: sessionNumbers,
      recipientOrNote: recipientOrNote.trim(),
    );

    current.insert(0, newRecord);

    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(current.map((r) => r.toJson()).toList());
    await prefs.setString(_prefKey, encoded);
  }

  /// Clears the history log upon user request.
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}

final clinicalExportLogServiceProvider = Provider<ClinicalExportLogService>((ref) {
  return ClinicalExportLogService();
});

