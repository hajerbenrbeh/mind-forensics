import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/core/security/local_data_cipher.dart';
import 'package:mind_forensics/features/auth/controllers/auth_controller.dart';
import 'package:mind_forensics/features/auth/data/auth_service.dart';
import 'package:mind_forensics/features/auth/domain/auth_state.dart';
import 'package:mind_forensics/features/auth/domain/auth_user.dart';
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

    test('TEST F: Password security — Credentials stored with salted SHA-256 and never in plaintext', () async {
      final mockStore = <String, Object>{};
      SharedPreferences.setMockInitialValues(mockStore);
      final service = AuthService();

      await service.signUpWithEmail('secure@example.com', 'SuperSecret99!');

      final prefs = await SharedPreferences.getInstance();
      final credsRaw = prefs.getString('mf_auth_user_credentials') ?? '{}';
      final Map<String, dynamic> creds = jsonDecode(credsRaw);

      // Verify the plaintext password was never stored and uses PBKDF2
      expect(creds['secure@example.com'], isNot(equals('SuperSecret99!')));
      expect((creds['secure@example.com'] as String).startsWith('pbkdf2_sha256\$10000\$'), isTrue);

      // Verify successful sign in using the salted hash
      final user = await service.signInWithEmail('secure@example.com', 'SuperSecret99!');
      expect(user.email, equals('secure@example.com'));

      // Verify failure on wrong password
      expect(
        () => service.signInWithEmail('secure@example.com', 'WrongPassword!'),
        throwsA(isA<FormatException>()),
      );
    });

    test('TEST G: Account deletion — Purges user-specific data partitions from storage', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AuthService();

      final user = await service.signUpWithEmail('charlie@example.com', 'Password123!');
      final uid = user.id;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mf_mind_traces_$uid', jsonEncode([{'id': 'trace_charlie'}]));
      await prefs.setString('mind_forensics_cases_$uid', jsonEncode([{'id': 'case_charlie'}]));

      expect(prefs.containsKey('mf_mind_traces_$uid'), isTrue);
      expect(prefs.containsKey('mind_forensics_cases_$uid'), isTrue);

      // Delete account
      await service.deleteAccount();

      // Verify user partitions were completely purged
      expect(prefs.containsKey('mf_mind_traces_$uid'), isFalse);
      expect(prefs.containsKey('mind_forensics_cases_$uid'), isFalse);
      expect(await service.getCurrentUser(), isNull);
    });

    test('TEST H: Backup restoration — Schema version rejection and non-destructive deduplication', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      final backupService = container.read(unifiedBackupServiceProvider);
      final traceRepo = container.read(mindTraceRepositoryProvider);

      // Seed an existing local trace
      final now = DateTime.now();
      await traceRepo.saveTrace(
        MindTraceModel(
          id: 'existing_trace_01',
          date: now,
          overallMood: 'peaceful',
          moodIntensity: 8,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // 1. Incompatible major schema version is rejected safely
      final incompatibleBackup = jsonEncode({
        'app': 'Mind Forensics',
        'schemaVersion': '9.0.0',
        'traces': [],
      });
      final resIncompatible = await backupService.restoreFromBackupJson(incompatibleBackup);
      expect(resIncompatible.success, isFalse);
      expect(resIncompatible.message, contains('Unsupported backup schema version'));

      // 2. Valid backup with duplicate trace and new trace from yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      final validBackup = jsonEncode({
        'app': 'Mind Forensics',
        'schemaVersion': '2.0.0',
        'traces': [
          {
            'id': 'existing_trace_01', // Duplicate ID
            'date': now.toIso8601String(),
            'overallMood': 'overwrite_attempt',
            'moodIntensity': 1,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
          {
            'id': 'new_incoming_trace_02', // New ID and distinct date
            'date': yesterday.toIso8601String(),
            'overallMood': 'calm',
            'moodIntensity': 7,
            'createdAt': yesterday.toIso8601String(),
            'updatedAt': yesterday.toIso8601String(),
          },
        ],
      });

      final resValid = await backupService.restoreFromBackupJson(validBackup);
      expect(resValid.success, isTrue);
      expect(resValid.tracesCount, equals(1)); // Only the 1 new non-duplicate trace was inserted

      final allTraces = await traceRepo.getAllTraces();
      expect(allTraces.length, equals(2));
      final original = allTraces.firstWhere((t) => t.id == 'existing_trace_01');
      expect(original.overallMood, equals('peaceful')); // Preserved original value, NOT overwritten

      container.dispose();
    });

    test('TEST I: Account switching and backup restoration into a distinct account preserves isolation without polluting other accounts', () async {
      SharedPreferences.setMockInitialValues({});
      final authService = AuthService();

      // 1. Alice creates account and a trace
      final alice = await authService.signUpWithEmail('alice_isolation@clinic.org', 'Pass123456!');
      final aliceRepo = LocalMindTraceRepository(userId: alice.id);
      final now = DateTime.now();
      await aliceRepo.saveTrace(
        MindTraceModel(
          id: 'alice_isolated_trace',
          userId: alice.id,
          date: now,
          overallMood: 'optimistic',
          moodIntensity: 9,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Verify Alice has 1 trace
      expect((await aliceRepo.getAllTraces()).length, equals(1));

      // 2. Bob registers and signs in
      final bob = await authService.signUpWithEmail('bob_isolation@clinic.org', 'Pass123456!');
      final bobRepo = LocalMindTraceRepository(userId: bob.id);

      // Verify Bob starts completely empty
      expect((await bobRepo.getAllTraces()).isEmpty, isTrue);

      // 3. Bob imports a backup payload
      final containerBob = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => _MockAuthenticatedAuthController(bob),
          ),
        ],
      );

      final backupService = containerBob.read(unifiedBackupServiceProvider);
      final importedDate = now.subtract(const Duration(days: 2));
      final bobBackup = jsonEncode({
        'app': 'Mind Forensics',
        'schemaVersion': '2.0.0',
        'traces': [
          {
            'id': 'bob_imported_trace',
            'date': importedDate.toIso8601String(),
            'overallMood': 'reflective',
            'moodIntensity': 6,
            'createdAt': importedDate.toIso8601String(),
            'updatedAt': importedDate.toIso8601String(),
          }
        ],
      });

      final restoreResult = await backupService.restoreFromBackupJson(bobBackup);
      expect(restoreResult.success, isTrue);
      expect(restoreResult.tracesCount, equals(1));

      // Verify Bob's store now has exactly 1 trace (his imported one)
      final bobTraces = await bobRepo.getAllTraces();
      expect(bobTraces.length, equals(1));
      expect(bobTraces.first.id, equals('bob_imported_trace'));

      // Verify Alice's store remains 100% UNTOUCHED
      final aliceTraces = await aliceRepo.getAllTraces();
      expect(aliceTraces.length, equals(1));
      expect(aliceTraces.first.id, equals('alice_isolated_trace'));
      expect(aliceTraces.first.overallMood, equals('optimistic'));

      // 4. Bob deletes his account
      await authService.deleteAccount(); // Deletes Bob's active account and partitions

      // Verify Bob's store is purged
      expect((await bobRepo.getAllTraces()).isEmpty, isTrue);

      // Verify Alice's store is STILL 100% intact
      final aliceTracesAfterBobDeletion = await aliceRepo.getAllTraces();
      expect(aliceTracesAfterBobDeletion.length, equals(1));
      expect(aliceTracesAfterBobDeletion.first.id, equals('alice_isolated_trace'));

      containerBob.dispose();
    });

    test('TEST J: Password-encrypted backup roundtrip, tamper resistance, and iteration migration', () async {
      SharedPreferences.setMockInitialValues({});
      final container1 = ProviderContainer();
      addTearDown(container1.dispose);

      final now = DateTime.now();
      await container1.read(mindTraceRepositoryProvider).saveTrace(
            MindTraceModel(
              id: 'trace_encrypted_backup_01',
              date: now,
              overallMood: 'restless',
              moodIntensity: 7,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final backupService1 = container1.read(unifiedBackupServiceProvider);

      // 1. Create password-encrypted backup with 100,000 iterations
      final backupResult = await backupService1.createPasswordEncryptedBackup('SecureMasterKey123!');
      expect(backupResult.success, isTrue);
      expect(backupResult.rawJson, isNotNull);

      final backupPayload = jsonDecode(backupResult.rawJson!) as Map<String, dynamic>;
      expect(backupPayload['encrypted'], isTrue);
      expect(backupPayload['iterations'], equals(100000));
      expect(backupPayload['kdf'], equals('pbkdf2_sha256'));
      expect(backupPayload['salt'], isNotNull);
      expect(backupPayload['ciphertext'], startsWith('enc:v1\$'));

      // Assert zero plaintext trace data is exposed in the serialized payload
      expect(backupResult.rawJson!.contains('restless'), isFalse);
      expect(backupResult.rawJson!.contains('trace_encrypted_backup_01'), isFalse);

      // 2. Clear store to simulate new device restore and reject incorrect password
      SharedPreferences.setMockInitialValues({});
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      final backupService2 = container2.read(unifiedBackupServiceProvider);

      final wrongPasswordResult = await backupService2.restoreFromPasswordEncryptedBackup(
        backupResult.rawJson!,
        'WrongPassword999!',
      );
      expect(wrongPasswordResult.success, isFalse);
      expect(wrongPasswordResult.message, contains('Decryption failed'));

      // 3. Reject tampered ciphertext
      final tamperedCiphertext = backupPayload['ciphertext'].toString().replaceRange(15, 20, 'AAAAA');
      final tamperedPayload = Map<String, dynamic>.from(backupPayload);
      tamperedPayload['ciphertext'] = tamperedCiphertext;
      final tamperedJson = jsonEncode(tamperedPayload);

      final tamperedResult = await backupService2.restoreFromPasswordEncryptedBackup(
        tamperedJson,
        'SecureMasterKey123!',
      );
      expect(tamperedResult.success, isFalse);
      expect(tamperedResult.message, contains('Decryption failed'));

      // 4. Restore with correct password
      final successResult = await backupService2.restoreFromPasswordEncryptedBackup(
        backupResult.rawJson!,
        'SecureMasterKey123!',
      );
      expect(successResult.success, isTrue);
      expect(successResult.tracesCount, equals(1));

      final restoredTraces = await container2.read(mindTraceRepositoryProvider).getAllTraces();
      expect(restoredTraces.length, equals(1));
      expect(restoredTraces.first.id, equals('trace_encrypted_backup_01'));
      expect(restoredTraces.first.overallMood, equals('restless'));

      // 5. Backwards compatibility: verify restoration of 10,000-iteration backup
      final salt10k = AuthService.generateSecureSalt(16);
      final derived10kHash = AuthService.hashPassword(
        'LegacyKey123!',
        explicitSalt: salt10k,
        iterations: 10000,
      );
      final derived10kKeyBytes = base64Url.decode(derived10kHash.split('\$')[3]);
      final cipher10k = LocalDataCipher(secretKeyBytes: derived10kKeyBytes);

      final innerPayloadJson = jsonEncode({
        'schemaVersion': '2.0.0',
        'app': 'Mind Forensics',
        'timestamp': DateTime.now().toIso8601String(),
        'traces': [
          {
            'id': 'trace_legacy_10k',
            'userId': 'legacy_user',
            'date': DateTime.now().toIso8601String(),
            'overallMood': 'calm',
            'moodIntensity': 8,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }
        ],
        'sessions': [],
        'memories': [],
      });
      final ciphertext10k = await cipher10k.encryptString(innerPayloadJson);

      final legacyPayload = {
        'app': 'Mind Forensics',
        'encrypted': true,
        'schemaVersion': '2.0.0',
        'kdf': 'pbkdf2_sha256',
        'iterations': 10000,
        'salt': base64Url.encode(salt10k),
        'ciphertext': ciphertext10k,
      };

      final legacyRestoreResult = await backupService2.restoreFromPasswordEncryptedBackup(
        jsonEncode(legacyPayload),
        'LegacyKey123!',
      );
      expect(legacyRestoreResult.success, isTrue);
      expect(legacyRestoreResult.tracesCount, equals(1));

      final legacyTraces = await container2.read(mindTraceRepositoryProvider).getAllTraces();
      expect(legacyTraces.any((t) => t.id == 'trace_legacy_10k'), isTrue);
    });
  });
}

class _MockAuthenticatedAuthController extends AuthController {
  _MockAuthenticatedAuthController(this._user);
  final AuthUser _user;

  @override
  AuthState build() {
    return AuthState(
      status: AuthStatus.authenticated,
      user: _user,
      hasCompletedOnboarding: true,
    );
  }
}
