import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/auth/controllers/auth_controller.dart';
import 'package:mind_forensics/features/auth/data/auth_service.dart';
import 'package:mind_forensics/features/backup/data/unified_backup_service.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/conversation_mode.dart';
import 'package:mind_forensics/features/investigation/domain/statement.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/data/local_mind_trace_repository.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/profile/controllers/profile_controller.dart';
import 'package:mind_forensics/features/profile/domain/condition_type.dart';
import 'package:mind_forensics/features/profile/domain/diagnostic_status.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Mind Forensics Critical Scenarios Verification Suite', () {
    test('TEST A: Create mood entry, close app, reopen, verify record remains', () async {
      final mockStore = <String, Object>{};
      SharedPreferences.setMockInitialValues(mockStore);

      // Session 1: User creates mood check-in
      final container1 = ProviderContainer();
      final now = DateTime.now();
      final trace = MindTraceModel(
        id: 'trace_persistence_test_01',
        userId: 'alice_01',
        date: now,
        overallMood: 'calm',
        moodIntensity: 8,
        energyLevel: 7,
        anxietyLevel: 2,
        sleepHours: 8.5,
        journalText: 'Feeling grounded after morning walk.',
        createdAt: now,
        updatedAt: now,
      );

      final repo1 = container1.read(mindTraceRepositoryProvider);
      await repo1.saveTrace(trace);
      final tracesSession1 = await repo1.getAllTraces();
      expect(tracesSession1.length, equals(1));
      expect(tracesSession1.first.id, equals('trace_persistence_test_01'));
      container1.dispose();

      // Session 2: App reopens (simulated by fresh ProviderContainer backed by same persisted SharedPreferences)
      final container2 = ProviderContainer();
      final repo2 = container2.read(mindTraceRepositoryProvider);
      final tracesSession2 = await repo2.getAllTraces();

      expect(tracesSession2.length, equals(1));
      expect(tracesSession2.first.id, equals('trace_persistence_test_01'));
      expect(tracesSession2.first.overallMood, equals('calm'));
      expect(tracesSession2.first.moodIntensity, equals(8));
      expect(tracesSession2.first.journalText, equals('Feeling grounded after morning walk.'));
      container2.dispose();
    });

    test('TEST B: Multi-turn conversation retains context and persists across restarts', () async {
      final mockStore = <String, Object>{};
      SharedPreferences.setMockInitialValues(mockStore);

      // Session 1: Begin conversation turn
      final container1 = ProviderContainer();
      final activeCaseController = container1.read(activeCaseControllerProvider.notifier);
      final initialCase = await activeCaseController.startNewCase(
        'Unexpected meeting cancelled',
        mode: ConversationMode.exploreThought,
      );

      await activeCaseController.addStatement(
        'I immediately assumed nobody valued my contribution.',
        StatementSpeaker.user,
      );

      final service = container1.read(investigatorServiceProvider);
      final reply = await service.getNextQuestion(
        currentCase: container1.read(activeCaseControllerProvider).value!,
        conversationHistory: container1.read(activeCaseControllerProvider).value!.statements,
        sessionSummary: null,
        languageCode: 'en',
        profile: null,
      );

      await activeCaseController.addStatement(
        reply,
        StatementSpeaker.investigator,
      );

      final savedCase = container1.read(activeCaseControllerProvider).value!;
      expect(savedCase.statements.length, equals(3));
      container1.dispose();

      // Session 2: App restarts, ensure hydrated case restores all turns verbatim
      final container2 = ProviderContainer();
      final activeCaseController2 = container2.read(activeCaseControllerProvider.notifier);
      final hydratedCase = await activeCaseController2.ensureHydrated();

      expect(hydratedCase, isNotNull);
      expect(hydratedCase!.id, equals(initialCase.id));
      expect(hydratedCase.statements.length, equals(3));
      expect(hydratedCase.statements[0].text, equals('Unexpected meeting cancelled'));
      expect(hydratedCase.statements[1].text, equals('I immediately assumed nobody valued my contribution.'));
      expect(hydratedCase.statements.last.speaker, equals(StatementSpeaker.investigator));
      container2.dispose();
    });

    test('TEST C: Unified Backup creation, structural verification, and full restoration', () async {
      final mockStore = <String, Object>{};
      SharedPreferences.setMockInitialValues(mockStore);

      final container1 = ProviderContainer();

      // 1. Seed historical records
      final now = DateTime.now();
      await container1.read(mindTraceRepositoryProvider).saveTrace(
            MindTraceModel(
              id: 'trace_backup_01',
              date: now,
              overallMood: 'anxious',
              moodIntensity: 7,
              createdAt: now,
              updatedAt: now,
            ),
          );

      await container1.read(caseRepositoryProvider).saveCase(
            CaseModel(
              id: 'case_backup_01',
              caseNumber: 'SESSION 01',
              title: 'Project review',
              createdAt: now,
              updatedAt: now,
              currentStage: CaseStage.evidence,
              incidentDescription: 'Felt nervous before the presentation.',
              statements: [
                Statement(id: 's1', text: 'I felt unprepared.', speaker: StatementSpeaker.user, timestamp: now),
              ],
            ),
          );

      await container1.read(profileRepositoryProvider).saveProfile(
            PsychologicalProfileModel(
              userId: 'local_user',
              preferredName: 'Alice',
              conditions: const [
                UserConditionEntry(
                  condition: ConditionType.generalizedAnxiety,
                  status: DiagnosticStatus.professionallyDiagnosed,
                ),
              ],
              updatedAt: now,
            ),
          );

      // 2. Create full backup
      final backupService1 = container1.read(unifiedBackupServiceProvider);
      final backupResult = await backupService1.createFullBackup();

      expect(backupResult.success, isTrue);
      expect(backupResult.tracesCount, equals(1));
      expect(backupResult.sessionsCount, equals(1));
      expect(backupResult.rawJson, isNotNull);

      // Validate JSON structure
      final decoded = jsonDecode(backupResult.rawJson!) as Map<String, dynamic>;
      expect(decoded['schemaVersion'], equals('2.0.0'));
      expect(decoded['app'], equals('Mind Forensics'));
      expect((decoded['traces'] as List).length, equals(1));
      expect((decoded['sessions'] as List).length, equals(1));
      expect(decoded['profile'], isNotNull);
      container1.dispose();

      // 3. Simulate new device / fresh wipe by clearing SharedPreferences
      final freshStore = <String, Object>{};
      SharedPreferences.setMockInitialValues(freshStore);

      final container2 = ProviderContainer();
      // Verify empty state
      expect((await container2.read(mindTraceRepositoryProvider).getAllTraces()).isEmpty, isTrue);
      expect((await container2.read(caseRepositoryProvider).getAllCases()).isEmpty, isTrue);

      // 4. Restore from backup
      final backupService2 = container2.read(unifiedBackupServiceProvider);
      final restoreResult = await backupService2.restoreFromBackupJson(backupResult.rawJson!);

      expect(restoreResult.success, isTrue);
      expect(restoreResult.tracesCount, equals(1));
      expect(restoreResult.sessionsCount, equals(1));

      // Verify records are restored with original IDs
      final restoredTraces = await container2.read(mindTraceRepositoryProvider).getAllTraces();
      expect(restoredTraces.length, equals(1));
      expect(restoredTraces.first.id, equals('trace_backup_01'));
      expect(restoredTraces.first.overallMood, equals('anxious'));

      final restoredCases = await container2.read(caseRepositoryProvider).getAllCases();
      expect(restoredCases.length, equals(1));
      expect(restoredCases.first.id, equals('case_backup_01'));
      expect(restoredCases.first.statements.length, equals(1));

      final restoredProfile = await container2.read(profileRepositoryProvider).getProfile();
      expect(restoredProfile.preferredName, equals('Alice'));
      container2.dispose();
    });

    test('TEST D: Offline changes are safely retained and sync reports accurate status', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      final backupService = container.read(unifiedBackupServiceProvider);

      final status = await backupService.getCloudSyncStatus();
      expect(status.state, equals(CloudSyncState.missingConfiguration));
      expect(status.description, contains('Missing google-services.json'));

      // Perform offline records
      final now = DateTime.now();
      await container.read(mindTraceRepositoryProvider).saveTrace(
            MindTraceModel(
              id: 'offline_trace_01',
              date: now,
              overallMood: 'calm',
              moodIntensity: 6,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final traces = await container.read(mindTraceRepositoryProvider).getAllTraces();
      expect(traces.length, equals(1));
      expect(traces.first.id, equals('offline_trace_01'));
      container.dispose();
    });

    test('TEST E: Sign out, sign in with new user, verify strict multi-user isolation', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      final authNotifier = container.read(authControllerProvider.notifier);

      // 1. Sign up Alice
      final userAlice = await container.read(authServiceProvider).signUpWithEmail(
            'alice@example.com',
            'Password123!',
            codename: 'Alice',
          );
      await authNotifier.signInWithEmail('alice@example.com', 'Password123!');

      // Save Alice's mood record
      final repoAlice = LocalMindTraceRepository(userId: userAlice.id);
      final now = DateTime.now();
      await repoAlice.saveTrace(
        MindTraceModel(
          id: 'alice_trace_01',
          userId: userAlice.id,
          date: now,
          overallMood: 'calm',
          moodIntensity: 9,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final aliceTraces = await repoAlice.getAllTraces();
      expect(aliceTraces.length, equals(1));

      // 2. Sign out Alice
      await authNotifier.signOut();

      // 3. Sign up Bob
      final userBob = await container.read(authServiceProvider).signUpWithEmail(
            'bob@example.com',
            'Password123!',
            codename: 'Bob',
          );
      await authNotifier.signInWithEmail('bob@example.com', 'Password123!');

      // Bob's repository must be isolated and have ZERO traces from Alice
      final repoBob = LocalMindTraceRepository(userId: userBob.id);
      final bobTraces = await repoBob.getAllTraces();
      expect(bobTraces.isEmpty, isTrue);

      // 4. Sign out Bob, sign back in as Alice
      await authNotifier.signOut();
      await authNotifier.signInWithEmail('alice@example.com', 'Password123!');

      final aliceTracesReloaded = await repoAlice.getAllTraces();
      expect(aliceTracesReloaded.length, equals(1));
      expect(aliceTracesReloaded.first.id, equals('alice_trace_01'));
      expect(aliceTracesReloaded.first.moodIntensity, equals(9));
      container.dispose();
    });
  });
}
