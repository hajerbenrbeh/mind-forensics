import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/features/auth/controllers/auth_controller.dart';
import 'package:mind_forensics/features/auth/data/auth_service.dart';
import 'package:mind_forensics/features/auth/domain/auth_state.dart';
import 'package:mind_forensics/features/auth/domain/auth_user.dart';
import 'package:mind_forensics/features/investigation/data/cloud_sync_service.dart';
import 'package:mind_forensics/features/investigation/data/direct_gemini_investigator_service.dart';
import 'package:mind_forensics/features/investigation/data/direct_groq_investigator_service.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/mind_trace/data/mind_trace_ai_service.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/observatory/data/observatory_ai_service.dart';
import 'package:mind_forensics/features/profile/domain/condition_type.dart';
import 'package:mind_forensics/features/profile/domain/diagnostic_status.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:mind_forensics/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Step 6.1A — Data Transparency & Anti-Cloud-Sync Guarantees', () {
    test('AppStrings localization across EN, FR, and AR enforces truthful local-only terminology', () {
      final en = AppStrings('en');
      final fr = AppStrings('fr');
      final ar = AppStrings('ar');

      // 1. cloudSyncTitle & Description
      expect(en.cloudSyncTitle, equals('Local Backup & Export'));
      expect(fr.cloudSyncTitle, equals('Sauvegarde locale & Export'));
      expect(ar.cloudSyncTitle, equals('النسخ الاحتياطي والتصدير المحلي'));

      expect(en.cloudSyncDesc, contains('exported JSON files are unencrypted plaintext'));
      expect(en.cloudSyncDesc, contains('Backup files are never sent to remote servers'));
      expect(fr.cloudSyncDesc, contains('exports JSON sont en texte clair non chiffré'));
      expect(ar.cloudSyncDesc, contains('ملفات JSON المصدّرة نص غير مشفر'));

      // 2. Account password protection (formerly misleading "Sync to Cloud Account")
      expect(en.linkEmailTitle, equals('Protect Account with Password'));
      expect(fr.linkEmailTitle, equals('Protéger par mot de passe'));
      expect(ar.linkEmailTitle, equals('حماية الحساب بكلمة مرور'));

      expect(en.linkEmailSubtitle, contains('salted cryptographic hash'));
      expect(en.linkEmailSubtitle, isNot(contains('encrypted credentials')));
      expect(fr.linkEmailSubtitle, contains('hachage cryptographique salé'));
      expect(ar.linkEmailSubtitle, contains('تجزئة مشفرة ومملّحة'));

      expect(en.linkEmailBtn, equals('SAVE & PROTECT ACCOUNT'));
      expect(fr.linkEmailBtn, equals('ENREGISTRER & PROTÉGER'));
      expect(ar.linkEmailBtn, equals('حفظ وتأمين الحساب'));

      expect(en.linkEmailSuccess, contains('Account successfully protected with local password'));
      expect(fr.linkEmailSuccess, contains('Compte protégé par mot de passe local'));
      expect(ar.linkEmailSuccess, contains('تم تأمين الحساب بكلمة المرور المحلية'));

      expect(en.vaultStatusCloud, equals('Local Password-Secured Account'));
      expect(fr.vaultStatusCloud, equals('Compte local protégé par mot de passe'));
      expect(ar.vaultStatusCloud, equals('حساب محلي محمي بكلمة مرور'));

      expect(en.cloudChoiceBadge, equals('LOCAL PASSWORD PROTECTED'));
      expect(fr.cloudChoiceBadge, equals('PROTÉGÉ LOCALEMENT'));
      expect(ar.cloudChoiceBadge, equals('محمي بكلمة مرور محلية'));

      // 3. Export disclaimer
      expect(en.exportVaultSuccess, contains('unencrypted'));
      expect(fr.exportVaultSuccess, contains('n’est pas chiffré'));
      expect(ar.exportVaultSuccess, contains('غير مشفر'));
    });

    test('Local account password protection updates SharedPreferences credentials without network calls', () async {
      final authService = AuthService();
      final anon = await authService.createAnonymousVault(codename: 'LocalObserver');
      expect(anon.authType, equals(AuthType.anonymous));

      final upgraded = await authService.linkEmailToAnonymous(
        'observer@local.internal',
        'safeLocalPass123',
        codename: 'SecuredObserver',
      );

      expect(upgraded.id, equals(anon.id));
      expect(upgraded.email, equals('observer@local.internal'));
      expect(upgraded.authType, equals(AuthType.emailPassword));
      expect(upgraded.codename, equals('SecuredObserver'));

      // Verify credentials stored locally in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final credsRaw = prefs.getString('mf_auth_user_credentials');
      expect(credsRaw, isNotNull);
      final Map<String, dynamic> creds = jsonDecode(credsRaw!);
      expect(creds.containsKey('observer@local.internal'), isTrue);
      // Credential must be a salted PBKDF2 hash, never plaintext
      expect(creds['observer@local.internal'], isNot(equals('safeLocalPass123')));
      expect(creds['observer@local.internal'], contains('pbkdf2_sha256'));
    });

    test('Local JSON export and parsing operates cleanly and remains offline', () {
      final syncService = CloudSyncService();
      final cases = [
        CaseModel(
          id: 'case-transparency-1',
          caseNumber: 'SESSION 01',
          title: 'Thought Exploration',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          currentStage: CaseStage.conclusion,
          incidentDescription: 'Reflecting on stress response.',
        ),
      ];

      final jsonOutput = syncService.exportBackupJson(cases);
      expect(jsonOutput, contains('Mind Forensics'));
      expect(jsonOutput, contains('SESSION 01'));

      final parsed = syncService.parseBackupJson(jsonOutput);
      expect(parsed.length, equals(1));
      expect(parsed.first.id, equals('case-transparency-1'));
    });

    testWidgets('SettingsScreen does not contain misleading cloud sync claims or non-functional switches', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_MockAuthController.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified: Misleading claims must NOT exist
      expect(find.text('CLOUD SYNCED'), findsNothing);
      expect(find.text('DATA BACKUP & CLOUD RESTORATION'), findsNothing);
      expect(find.text('Sync to Cloud Account'), findsNothing);
      expect(find.text('Account successfully linked to cloud.'), findsNothing);

      // Verified: Honest, transparent copy is rendered
      expect(find.text('LOCAL SECURED'), findsOneWidget);
      expect(find.text('LOCAL BACKUP & DATA EXPORT'), findsOneWidget);
      expect(find.text('LOCAL SOVEREIGN'), findsOneWidget);
      expect(find.text('LOCAL SOVEREIGN STORAGE: ACTIVE'), findsOneWidget);
      expect(
        find.textContaining('Your mood logs, reflection sessions, and clinical profiles are encrypted at rest with local AES-256-GCM'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Personal records are never automatically synced to the cloud; external AI processing occurs only when you explicitly use an AI feature'),
        findsOneWidget,
      );
      expect(find.textContaining('No personal records are transmitted to remote servers.'), findsNothing);
    });
  });

  group('Stage 6.1A.1 — Explicit AI Consent Remediation & Fail-Closed Privacy', () {
    test('1. New psychological profile defaults to false for both AI permissions with current consent version', () {
      final profile = PsychologicalProfileModel(updatedAt: DateTime.now());
      expect(profile.shareWithAiCompanion, isFalse);
      expect(profile.allowAiPersonalization, isFalse);
      expect(profile.consentVersion, equals(PsychologicalProfileModel.kCurrentConsentVersion));

      final emptyProfile = PsychologicalProfileModel.empty();
      expect(emptyProfile.shareWithAiCompanion, isFalse);
      expect(emptyProfile.allowAiPersonalization, isFalse);
      expect(emptyProfile.consentVersion, equals(PsychologicalProfileModel.kCurrentConsentVersion));
    });

    test('2. Missing consent fields in JSON default to false', () {
      final json = <String, dynamic>{
        'id': 'test-profile-1',
        'preferredName': 'Alice',
        'conditions': [],
      };
      final profile = PsychologicalProfileModel.fromJson(json);
      expect(profile.shareWithAiCompanion, isFalse);
      expect(profile.allowAiPersonalization, isFalse);
      expect(profile.preferredName, equals('Alice'));
    });

    test('3. Legacy unversioned profile (consentVersion < 1) with implicit true migrates to false while preserving clinical data', () {
      final legacyJson = <String, dynamic>{
        'id': 'legacy-profile-123',
        'preferredName': 'Sami',
        'selectedSymptoms': ['insomnia', 'racing_thoughts'],
        'conditions': [
          {
            'condition': 'generalizedAnxiety',
            'status': 'exploring',
            'note': 'Worse in the evenings',
          }
        ],
        'selectedGoals': ['Improve sleep quality', 'Mindful breathing'],
        'currentDifficulties': 'Evening rumination',
        'personalTriggers': 'Late night emails',
        'currentTreatment': 'Occasional mindfulness apps',
        'notesForAiCompanion': 'Be gentle and direct',
        'shareWithAiCompanion': true,
        'allowAiPersonalization': true,
      };

      final migrated = PsychologicalProfileModel.fromJson(legacyJson);

      expect(migrated.shareWithAiCompanion, isFalse);
      expect(migrated.allowAiPersonalization, isFalse);
      expect(migrated.consentVersion, equals(0));

      expect(migrated.preferredName, equals('Sami'));
      expect(migrated.selectedSymptoms, equals(['insomnia', 'racing_thoughts']));
      expect(migrated.conditions.length, equals(1));
      expect(migrated.conditions.first.note, equals('Worse in the evenings'));
      expect(migrated.selectedGoals, equals(['Improve sleep quality', 'Mindful breathing']));
      expect(migrated.currentDifficulties, equals('Evening rumination'));
      expect(migrated.personalTriggers, equals('Late night emails'));
      expect(migrated.currentTreatment, equals('Occasional mindfulness apps'));
      expect(migrated.notesForAiCompanion, equals('Be gentle and direct'));
    });

    test('4. Modern profile with explicit user consent (consentVersion >= 1) correctly preserves true values', () {
      final modernJson = <String, dynamic>{
        'id': 'modern-profile-456',
        'preferredName': 'Leila',
        'consentVersion': 1,
        'shareWithAiCompanion': true,
        'allowAiPersonalization': true,
      };

      final profile = PsychologicalProfileModel.fromJson(modernJson);
      expect(profile.shareWithAiCompanion, isTrue);
      expect(profile.allowAiPersonalization, isTrue);
      expect(profile.consentVersion, equals(1));
    });

    test('5. Permissions are decoupled: toggling one never alters the other', () {
      final base = PsychologicalProfileModel(
        updatedAt: DateTime.now(),
        consentVersion: 1,
        shareWithAiCompanion: false,
        allowAiPersonalization: false,
      );

      final enabledShare = base.copyWith(shareWithAiCompanion: true);
      expect(enabledShare.shareWithAiCompanion, isTrue);
      expect(enabledShare.allowAiPersonalization, isFalse);

      final enabledPersonalization = base.copyWith(allowAiPersonalization: true);
      expect(enabledPersonalization.shareWithAiCompanion, isFalse);
      expect(enabledPersonalization.allowAiPersonalization, isTrue);

      final bothEnabled = PsychologicalProfileModel(
        updatedAt: DateTime.now(),
        consentVersion: 1,
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
      );
      final disabledShareOnly = bothEnabled.copyWith(shareWithAiCompanion: false);
      expect(disabledShareOnly.shareWithAiCompanion, isFalse);
      expect(disabledShareOnly.allowAiPersonalization, isTrue);

      final disabledPersonalizationOnly = bothEnabled.copyWith(allowAiPersonalization: false);
      expect(disabledPersonalizationOnly.shareWithAiCompanion, isTrue);
      expect(disabledPersonalizationOnly.allowAiPersonalization, isFalse);
    });

    test('6. All four outbound AI pathways fail-closed with zero network calls when consent is absent, even with valid API key', () async {
      final testCase = CaseModel(
        id: 'case-test-consent',
        caseNumber: 'TEST-01',
        title: 'Safety Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentStage: CaseStage.conclusion,
        incidentDescription: 'Feeling overwhelmed by work deadlines.',
      );

      final profileNoConsent = PsychologicalProfileModel(
        updatedAt: DateTime.now(),
        shareWithAiCompanion: false,
        allowAiPersonalization: false,
      );

      const liveKey = 'AIzaSyFakeLiveProductionKey1234567890';

      // Pathway 1: DirectGeminiInvestigatorService
      final geminiService = DirectGeminiInvestigatorService(
        apiKey: liveKey,
        onRequestAttempted: (_, _) {
          fail('Gemini attempted outbound network call without user consent');
        },
      );
      final geminiQuestion = await geminiService.getNextQuestion(
        currentCase: testCase,
        conversationHistory: const [],
        profile: profileNoConsent,
      );
      expect(geminiService.networkRequestsAttempted, equals(0));
      expect(geminiQuestion, isNotEmpty);

      // Pathway 2: DirectGroqInvestigatorService
      final groqService = DirectGroqInvestigatorService(
        apiKey: 'gsk_fakeLiveGroqKey1234567890',
        onRequestAttempted: (_, _) {
          fail('Groq attempted outbound network call without user consent');
        },
      );
      final groqQuestion = await groqService.getNextQuestion(
        currentCase: testCase,
        conversationHistory: const [],
        profile: profileNoConsent,
      );
      expect(groqService.networkRequestsAttempted, equals(0));
      expect(groqQuestion, isNotEmpty);

      // Pathway 3: MindTraceAiService
      final traceService = MindTraceAiService(apiKey: liveKey);
      final reflection = await traceService.generateDailyReflection(
        currentTrace: MindTraceModel(
          id: 'trace-1',
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          overallMood: 'calm',
          moodIntensity: 5,
        ),
        history: const [],
        profile: profileNoConsent,
        languageCode: 'en',
      );
      expect(traceService.lastCallWasLive, isFalse);
      expect(reflection, isNotEmpty);

      // Pathway 4: ObservatoryAiService
      final observatoryService = ObservatoryAiService(apiKey: liveKey);
      final result = await observatoryService.analyzeSymptoms(
        selectedSymptoms: const [],
        intensity: 6,
        contextTrigger: 'Upcoming presentation',
        somaticLocation: 'Chest',
        userAdaptiveAnswer: 'Trying slow breaths',
        baseline: null,
        profile: profileNoConsent,
        languageCode: 'en',
      );
      expect(observatoryService.lastCallWasLive, isFalse);
      expect(result.analysis, isNotEmpty);
      expect(result.stabilizingStrategy, isNotEmpty);
    });

    test('7. Combination: shareWithAiCompanion == false & allowAiPersonalization == true routes to local AI across all 4 pathways (zero network calls)', () async {
      final testCase = CaseModel(
        id: 'case-test-share-false-pers-true',
        caseNumber: 'TEST-02',
        title: 'Share False Pers True Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentStage: CaseStage.conclusion,
        incidentDescription: 'Distress inquiry.',
      );

      final profileShareFalse = PsychologicalProfileModel(
        updatedAt: DateTime.now(),
        shareWithAiCompanion: false,
        allowAiPersonalization: true,
        conditions: const [
          UserConditionEntry(
            condition: ConditionType.generalizedAnxiety,
            status: DiagnosticStatus.selfIdentifiedExploring,
          ),
        ],
      );

      const liveKey = 'AIzaSyFakeLiveProductionKey1234567890';

      // 1. DirectGeminiInvestigatorService
      final geminiService = DirectGeminiInvestigatorService(
        apiKey: liveKey,
        onRequestAttempted: (_, _) => fail('Gemini made outbound call when shareWithAiCompanion is false'),
        clientFactory: () => throw const SocketException('Should never be called'),
      );
      final geminiQ = await geminiService.getNextQuestion(
        currentCase: testCase,
        conversationHistory: const [],
        profile: profileShareFalse,
      );
      expect(geminiService.networkRequestsAttempted, equals(0));
      expect(geminiQ, isNotEmpty);

      // 2. DirectGroqInvestigatorService
      final groqService = DirectGroqInvestigatorService(
        apiKey: 'gsk_fakeLiveGroqKey1234567890',
        onRequestAttempted: (_, _) => fail('Groq made outbound call when shareWithAiCompanion is false'),
        clientFactory: () => throw const SocketException('Should never be called'),
      );
      final groqQ = await groqService.getNextQuestion(
        currentCase: testCase,
        conversationHistory: const [],
        profile: profileShareFalse,
      );
      expect(groqService.networkRequestsAttempted, equals(0));
      expect(groqQ, isNotEmpty);

      // 3. MindTraceAiService
      final traceService = MindTraceAiService(apiKey: liveKey);
      final reflection = await traceService.generateDailyReflection(
        currentTrace: MindTraceModel(
          id: 'trace-2',
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          overallMood: 'restless',
          moodIntensity: 7,
        ),
        history: const [],
        profile: profileShareFalse,
        languageCode: 'en',
      );
      expect(traceService.lastCallWasLive, isFalse);
      expect(reflection, isNotEmpty);

      // 4. ObservatoryAiService
      final obsService = ObservatoryAiService(apiKey: liveKey);
      final result = await obsService.analyzeSymptoms(
        selectedSymptoms: const [],
        intensity: 4,
        contextTrigger: null,
        somaticLocation: null,
        userAdaptiveAnswer: null,
        baseline: null,
        profile: profileShareFalse,
        languageCode: 'en',
      );
      expect(obsService.lastCallWasLive, isFalse);
      expect(result.analysis, isNotEmpty);
    });

    test('8. Combination: shareWithAiCompanion == true & allowAiPersonalization == false isolates external AI and executes local-only behavior', () async {
      final testCase = CaseModel(
        id: 'case-test-share-true-pers-false',
        caseNumber: 'TEST-03',
        title: 'Share True Pers False Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentStage: CaseStage.conclusion,
        incidentDescription: 'Work stress incident.',
      );

      final profileShareOnly = PsychologicalProfileModel(
        updatedAt: DateTime.now(),
        shareWithAiCompanion: true,
        allowAiPersonalization: false,
        preferredName: 'SecretObserverName',
        conditions: const [
          UserConditionEntry(
            condition: ConditionType.generalizedAnxiety,
            status: DiagnosticStatus.selfIdentifiedExploring,
          ),
        ],
        notesForAiCompanion: 'Sensitive psychological note',
      );

      const liveKey = 'AIzaSyFakeLiveProductionKey1234567890';

      // 1. DirectGeminiInvestigatorService
      Map<String, dynamic>? geminiCapturedPayload;
      final geminiService = DirectGeminiInvestigatorService(
        apiKey: liveKey,
        onRequestAttempted: (_, payload) {
          geminiCapturedPayload = payload;
        },
        clientFactory: () => throw const SocketException('Simulated offline network response'),
      );
      final geminiReply = await geminiService.getNextQuestion(
        currentCase: testCase,
        conversationHistory: const [],
        profile: profileShareOnly,
      );
      // Stage 6.1A.3: Gemini network transmission is permanently disabled (zero requests attempted)
      expect(geminiService.networkRequestsAttempted, equals(0));
      expect(geminiCapturedPayload, isNull);
      expect(geminiService.lastCallWasLive, isFalse);
      expect(geminiReply.isNotEmpty, isTrue);

      // 2. DirectGroqInvestigatorService
      Map<String, dynamic>? groqCapturedPayload;
      final groqService = DirectGroqInvestigatorService(
        apiKey: 'gsk_fakeLiveGroqKey1234567890',
        onRequestAttempted: (_, payload) {
          groqCapturedPayload = payload;
        },
        clientFactory: () => throw const SocketException('Simulated offline network response'),
      );
      final groqReply = await groqService.getNextQuestion(
        currentCase: testCase,
        conversationHistory: const [],
        profile: profileShareOnly,
      );
      // Stage 6.1A.3: Groq network transmission is permanently disabled (zero requests attempted)
      expect(groqService.networkRequestsAttempted, equals(0));
      expect(groqCapturedPayload, isNull);
      expect(groqService.lastCallWasLive, isFalse);
      expect(groqReply.isNotEmpty, isTrue);

      // 3. MindTraceAiService routes directly to local reflection with zero network calls
      final traceService = MindTraceAiService(apiKey: liveKey);
      final traceReply = await traceService.generateDailyReflection(
        currentTrace: MindTraceModel(
          id: 'trace-3',
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          overallMood: 'calm',
          moodIntensity: 5,
        ),
        history: const [],
        profile: profileShareOnly,
        languageCode: 'en',
      );
      expect(traceService.lastCallWasLive, isFalse);
      expect(traceReply.isNotEmpty, isTrue);

      // 4. ObservatoryAiService routes directly to local analysis with zero network calls
      final obsService = ObservatoryAiService(apiKey: liveKey);
      final obsAnalysis = await obsService.analyzeSymptoms(
        selectedSymptoms: const [],
        intensity: 5,
        contextTrigger: 'Meeting',
        somaticLocation: 'Neck',
        userAdaptiveAnswer: 'Deep breath',
        baseline: null,
        profile: profileShareOnly,
        languageCode: 'en',
      );
      expect(obsService.lastCallWasLive, isFalse);
      expect(obsAnalysis.analysis.isNotEmpty, isTrue);
    });

    test('9. Combination: shareWithAiCompanion == true & allowAiPersonalization == true isolates external AI and executes local-only behavior', () async {
      final testCase = CaseModel(
        id: 'case-test-both-true',
        caseNumber: 'TEST-04',
        title: 'Both True Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentStage: CaseStage.conclusion,
        incidentDescription: 'Evening panic sensation.',
      );

      final profileBothConsented = PsychologicalProfileModel(
        updatedAt: DateTime.now(),
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        preferredName: 'Karim',
        conditions: const [
          UserConditionEntry(
            condition: ConditionType.generalizedAnxiety,
            status: DiagnosticStatus.selfIdentifiedExploring,
          ),
        ],
        notesForAiCompanion: 'Please use compassionate framing',
      );

      const liveKey = 'AIzaSyFakeLiveProductionKey1234567890';

      // 1. DirectGeminiInvestigatorService
      Map<String, dynamic>? geminiPayload;
      final geminiService = DirectGeminiInvestigatorService(
        apiKey: liveKey,
        onRequestAttempted: (_, payload) {
          geminiPayload = payload;
        },
        clientFactory: () => throw const SocketException('Simulated offline network response'),
      );
      final geminiReply = await geminiService.getNextQuestion(
        currentCase: testCase,
        conversationHistory: const [],
        profile: profileBothConsented,
      );
      expect(geminiService.networkRequestsAttempted, equals(0));
      expect(geminiPayload, isNull);
      expect(geminiService.lastCallWasLive, isFalse);
      expect(geminiReply.isNotEmpty, isTrue);

      // 2. DirectGroqInvestigatorService
      final groqService = DirectGroqInvestigatorService(
        apiKey: 'gsk_fakeLiveGroqKey1234567890',
        clientFactory: () => throw const SocketException('Simulated offline network response'),
      );
      final groqReply = await groqService.getNextQuestion(
        currentCase: testCase,
        conversationHistory: const [],
        profile: profileBothConsented,
      );
      expect(groqService.networkRequestsAttempted, equals(0));
      expect(groqService.lastCallWasLive, isFalse);
      expect(groqReply.isNotEmpty, isTrue);

      // 3. MindTraceAiService routes to local reflection
      final traceService = MindTraceAiService(apiKey: liveKey);
      final reflection = await traceService.generateDailyReflection(
        currentTrace: MindTraceModel(
          id: 'trace-4',
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          overallMood: 'anxious',
          moodIntensity: 8,
          physicalTension: 8,
        ),
        history: const [],
        profile: profileBothConsented,
        languageCode: 'en',
      );
      expect(traceService.lastCallWasLive, isFalse);
      expect(reflection.isNotEmpty, isTrue);

      // 4. ObservatoryAiService routes to local analysis
      final obsService = ObservatoryAiService(apiKey: liveKey);
      final analysis = await obsService.analyzeSymptoms(
        selectedSymptoms: const [],
        intensity: 8,
        contextTrigger: 'Late night rumination',
        somaticLocation: 'Chest',
        userAdaptiveAnswer: 'Box breathing',
        baseline: null,
        profile: profileBothConsented,
        languageCode: 'en',
      );
      expect(obsService.lastCallWasLive, isFalse);
      expect(analysis.analysis.isNotEmpty, isTrue);
    });

    test('10. Revocation of consent immediately blocks subsequent requests and persists across storage reloads', () async {
      final testCase = CaseModel(
        id: 'case-test-revocation',
        caseNumber: 'TEST-05',
        title: 'Revocation Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentStage: CaseStage.conclusion,
        incidentDescription: 'Inquiry after revocation.',
      );

      var profile = PsychologicalProfileModel(
        updatedAt: DateTime.now(),
        consentVersion: 1,
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
      );

      const liveKey = 'AIzaSyFakeLiveProductionKey1234567890';

      // 1. Initial state: sharing permitted
      expect(DirectGeminiInvestigatorService.canTransmitCaseData(
        currentCase: testCase,
        profile: profile,
        checkProfileConsent: true,
      ), isTrue);

      // 2. User revokes external sharing consent
      profile = profile.copyWith(
        shareWithAiCompanion: false,
        consentVersion: PsychologicalProfileModel.kCurrentConsentVersion,
        updatedAt: DateTime.now(),
      );

      // Immediately blocked
      expect(DirectGeminiInvestigatorService.canTransmitCaseData(
        currentCase: testCase,
        profile: profile,
        checkProfileConsent: true,
      ), isFalse);

      final geminiService = DirectGeminiInvestigatorService(
        apiKey: liveKey,
        onRequestAttempted: (_, _) => fail('Attempted request after revocation'),
        clientFactory: () => throw const SocketException('Should never be called'),
      );
      await geminiService.getNextQuestion(
        currentCase: testCase,
        conversationHistory: const [],
        profile: profile,
      );
      expect(geminiService.networkRequestsAttempted, equals(0));

      // 3. Simulate persistence and reload: json serialization and deserialization
      final serialized = profile.toJson();
      final reloaded = PsychologicalProfileModel.fromJson(serialized);

      // Reopening does NOT restore revoked consent
      expect(reloaded.shareWithAiCompanion, isFalse);
      expect(reloaded.consentVersion, equals(1));
      expect(DirectGeminiInvestigatorService.canTransmitCaseData(
        currentCase: testCase,
        profile: reloaded,
        checkProfileConsent: true,
      ), isFalse);
    });

    test('11. Normal profile edits (notes, symptoms, goals) preserve consentVersion without silently enabling consent', () {
      final legacyProfile = PsychologicalProfileModel(
        updatedAt: DateTime.now(),
        consentVersion: 0,
        shareWithAiCompanion: false,
        allowAiPersonalization: false,
        preferredName: 'OldUser',
      );

      // User updates symptoms and goals without touching consent
      final updated = legacyProfile.copyWith(
        selectedSymptoms: ['headache', 'fatigue'],
        personalGoals: 'Rest well',
        updatedAt: DateTime.now(),
      );

      // Invariant: consentVersion remains 0, consent remains false
      expect(updated.consentVersion, equals(0));
      expect(updated.shareWithAiCompanion, isFalse);
      expect(updated.allowAiPersonalization, isFalse);
      expect(updated.selectedSymptoms, equals(['headache', 'fatigue']));
      expect(updated.personalGoals, equals('Rest well'));
    });

    test('12. Local fallback is strictly self-contained and no automatic external provider fallback exists', () async {
      final testCase = CaseModel(
        id: 'case-test-fallback-isolation',
        caseNumber: 'TEST-06',
        title: 'Fallback Isolation Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentStage: CaseStage.conclusion,
        incidentDescription: 'Offline fallback inquiry.',
      );

      final consentedProfile = PsychologicalProfileModel(
        updatedAt: DateTime.now(),
        consentVersion: 1,
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
      );

      // Gemini failure falls back to local MockInvestigatorService, NEVER makes a Groq request
      final geminiService = DirectGeminiInvestigatorService(
        apiKey: 'fake-gemini-key',
        clientFactory: () => throw const SocketException('Gemini network unavailable'),
      );
      final geminiResponse = await geminiService.getNextQuestion(
        currentCase: testCase,
        conversationHistory: const [],
        profile: consentedProfile,
      );
      expect(geminiResponse, isNotEmpty);
      expect(geminiService.lastCallWasLive, isFalse);

      // Groq failure falls back to local MockInvestigatorService, NEVER makes a Gemini request
      final groqService = DirectGroqInvestigatorService(
        apiKey: 'fake-groq-key',
        clientFactory: () => throw const SocketException('Groq network unavailable'),
      );
      final groqResponse = await groqService.getNextQuestion(
        currentCase: testCase,
        conversationHistory: const [],
        profile: consentedProfile,
      );
      expect(groqResponse, isNotEmpty);
      // Stage 6.1A.3: Both Gemini and Groq network requests are completely isolated (0 attempts)
      expect(groqService.networkRequestsAttempted, equals(0));
      expect(geminiService.networkRequestsAttempted, equals(0));
    });

    test('13. AppStrings provides clear, trilingual, non-misleading copy for both decoupled toggles', () {
      for (final code in ['en', 'fr', 'ar']) {
        final strings = AppStrings(code);

        expect(strings.aiDataSharingToggle, isNotEmpty);
        expect(strings.aiDataSharingDescEnabled, isNotEmpty);
        expect(strings.aiDataSharingDescDisabled, isNotEmpty);

        expect(strings.aiPersonalizationToggle, isNotEmpty);
        expect(strings.aiPersonalizationDescEnabled, isNotEmpty);
        expect(strings.aiPersonalizationDescDisabled, isNotEmpty);

        if (code == 'en') {
          expect(strings.aiDataSharingDescDisabled, contains('remain fully functional'));
          expect(strings.aiPersonalizationDescDisabled, contains('excluded from AI prompts'));
        } else if (code == 'fr') {
          expect(strings.aiDataSharingDescDisabled, contains('pleinement opérationnels'));
          expect(strings.aiPersonalizationDescDisabled, contains('exclu des requêtes'));
        } else if (code == 'ar') {
          expect(strings.aiDataSharingDescDisabled, contains('تعمل بالكامل'));
          expect(strings.aiPersonalizationDescDisabled, contains('حجب بيانات ملفك'));
        }
      }
    });
  });
}

class _MockAuthController extends AuthController {
  @override
  AuthState build() {
    return AuthState(
      status: AuthStatus.authenticated,
      user: AuthUser(
        id: 'test-user-id',
        email: 'test@local.internal',
        codename: 'Observer',
        authType: AuthType.emailPassword,
        createdAt: DateTime(2026, 1, 1),
      ),
      hasCompletedOnboarding: true,
    );
  }
}
