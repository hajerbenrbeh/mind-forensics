import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/investigation/data/cloud_sync_service.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/sync_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CloudSyncService syncService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    syncService = CloudSyncService();
  });

  group('CloudSyncService & Spark Plan Boundaries Tests', () {
    test('Default sync preference is enabled (Spark plan)', () async {
      final isEnabled = await syncService.isSyncEnabled();
      expect(isEnabled, isTrue);
    });

    test('Persists sync toggle in SharedPreferences', () async {
      await syncService.setSyncEnabled(false);
      expect(await syncService.isSyncEnabled(), isFalse);

      await syncService.setSyncEnabled(true);
      expect(await syncService.isSyncEnabled(), isTrue);
    });

    test('Returns offlineOnly status when cloud sync is disabled', () async {
      await syncService.setSyncEnabled(false);
      final status = await syncService.syncSessions([]);
      expect(status, equals(SyncStatus.offlineOnly));
    });

    test('Records last sync timestamp upon successful sync', () async {
      expect(await syncService.getLastSyncTime(), isNull);

      final status = await syncService.syncSessions([]);
      expect(status, equals(SyncStatus.synced));

      final lastSync = await syncService.getLastSyncTime();
      expect(lastSync, isNotNull);
      expect(lastSync!.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
    });

    test('Exports and imports portable session vault backup cleanly', () {
      final testCases = [
        CaseModel(
          id: 'case-sync-1',
          caseNumber: 'SESSION 01',
          title: 'Sync Test Case',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          currentStage: CaseStage.conclusion,
          incidentDescription: 'Testing offline-first backup portability.',
        ),
      ];

      final jsonString = syncService.exportBackupJson(testCases);
      expect(jsonString, contains('Mind Forensics'));
      expect(jsonString, contains('SESSION 01'));

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded['sessionCount'], equals(1));

      final imported = syncService.parseBackupJson(jsonString);
      expect(imported.length, equals(1));
      expect(imported.first.id, equals('case-sync-1'));
      expect(imported.first.caseNumber, equals('SESSION 01'));
      expect(imported.first.title, equals('Sync Test Case'));
    });
  });
}
