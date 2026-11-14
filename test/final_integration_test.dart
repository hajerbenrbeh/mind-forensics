import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/router/app_router.dart';
import 'package:mind_forensics/features/investigation/data/local_case_repository.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/journey/data/local_journey_repository.dart';
import 'package:mind_forensics/features/mind_trace/data/local_mind_trace_repository.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/profile/data/local_profile_repository.dart';
import 'package:mind_forensics/features/profile/domain/condition_type.dart';
import 'package:mind_forensics/features/profile/domain/diagnostic_status.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:mind_forensics/features/progress/data/progress_analytics_service.dart';
import 'package:mind_forensics/features/progress/domain/progress_analytics_model.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'mf_onboarding_completed': true,
    });
  });

  group('Cross-Feature Multi-User Isolation Tests', () {
    test('isolates Mind Traces, Cases, Journey and Profile per authenticated user', () async {
      const userA = 'user_alpha_uuid';
      const userB = 'user_beta_uuid';

      // 1. Repositories for User A
      final traceRepoA = LocalMindTraceRepository(userId: userA);
      final caseRepoA = LocalCaseRepository(userId: userA);
      final journeyRepoA = LocalJourneyRepository(userId: userA);
      final profileRepoA = LocalProfileRepository();

      // Write User A data
      final now = DateTime.now();
      await traceRepoA.saveTrace(MindTraceModel(
        id: 'trace_a1',
        userId: userA,
        date: now,
        overallMood: 'calm',
        moodIntensity: 4,
        energyLevel: 8,
        journalText: 'User A private journal entry',
        createdAt: now,
        updatedAt: now,
      ));

      await caseRepoA.saveCase(CaseModel(
        id: 'case_a1',
        userId: userA,
        caseNumber: 'CASE 01',
        title: 'User A Thought',
        createdAt: now,
        updatedAt: now,
        currentStage: CaseStage.conclusion,
        incidentDescription: 'User A incident',
        userConclusion: 'User A reframe',
        isCompleted: true,
      ));

      final journeyStateA = await journeyRepoA.getJourneyState();
      await journeyRepoA.saveJourneyState(journeyStateA.copyWith(
        activities: journeyStateA.activities.map((a) {
          if (a.id == 'act_1_1') {
            return a.copyWith(isCompleted: true, personalNotes: 'User A exercise note');
          }
          return a;
        }).toList(),
      ));

      await profileRepoA.saveProfile(
        PsychologicalProfileModel(
          userId: userA,
          preferredName: 'Investigator Alpha',
          personalGoals: 'User A goals',
          updatedAt: now,
        ),
        userId: userA,
      );

      // 2. Repositories for User B
      final traceRepoB = LocalMindTraceRepository(userId: userB);
      final caseRepoB = LocalCaseRepository(userId: userB);
      final journeyRepoB = LocalJourneyRepository(userId: userB);
      final profileRepoB = LocalProfileRepository();

      // Verify User B does not see User A's data
      final tracesB = await traceRepoB.getAllTraces();
      expect(tracesB.where((t) => t.id == 'trace_a1'), isEmpty);

      final casesB = await caseRepoB.getAllCases();
      expect(casesB.where((c) => c.id == 'case_a1'), isEmpty);

      final journeyB = await journeyRepoB.getJourneyState();
      expect(journeyB.activities.firstWhere((a) => a.id == 'act_1_1').personalNotes, isEmpty);

      final profileB = await profileRepoB.getProfile(userId: userB);
      expect(profileB.preferredName, isNot(equals('Investigator Alpha')));

      // 3. User B writes their own data
      await traceRepoB.saveTrace(MindTraceModel(
        id: 'trace_b1',
        userId: userB,
        date: now,
        overallMood: 'anxious',
        moodIntensity: 7,
        journalText: 'User B private note',
        createdAt: now,
        updatedAt: now,
      ));

      // 4. Verify User A data remains intact and uncontaminated
      final tracesA = await traceRepoA.getAllTraces();
      expect(tracesA.length, equals(1));
      expect(tracesA.first.journalText, equals('User A private journal entry'));
    });
  });

  group('Daily Mind Trace & Progress Lifecycle Integration', () {
    test('creates, updates on same date, and removes from analytics on delete', () async {
      final now = DateTime.now();
      final todayKey =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final repo = LocalMindTraceRepository(userId: 'test_user');
      const strings = AppStrings('en');

      // 1. Create first entry today
      final initialTrace = MindTraceModel(
        id: 'trace_today',
        date: now,
        overallMood: 'restless',
        selectedEmotions: const ['Restless', 'Anxious'],
        moodIntensity: 6,
        energyLevel: 5,
        journalText: 'Midday racing thoughts',
        createdAt: now,
        updatedAt: now,
      );
      await repo.saveTrace(initialTrace);

      var traces = await repo.getAllTraces();
      expect(traces.length, equals(1));

      var analytics = ProgressAnalyticsCalculator.computeAnalytics(
        allTraces: traces,
        allCases: const [],
        journeyState: null,
        timeWindow: ProgressTimeWindow.thirtyDays,
        dismissedInsightIds: const {},
        strings: strings,
      );
      expect(analytics.totalEntries, equals(1));
      expect(analytics.averageIntensity, equals(6.0));
      expect(analytics.emotionFrequencies['Restless'], equals(1));

      // 2. Edit entry today (same dateKey)
      final editedTrace = initialTrace.copyWith(
        overallMood: 'grounded',
        selectedEmotions: const ['Calm', 'Grounded'],
        moodIntensity: 3,
        journalText: 'Evening walk helped me decompress',
      );
      await repo.saveTrace(editedTrace);

      traces = await repo.getAllTraces();
      // Must NOT duplicate on same date
      expect(traces.length, equals(1));
      expect(traces.first.dateKey, equals(todayKey));
      expect(traces.first.overallMood, equals('grounded'));

      analytics = ProgressAnalyticsCalculator.computeAnalytics(
        allTraces: traces,
        allCases: const [],
        journeyState: null,
        timeWindow: ProgressTimeWindow.thirtyDays,
        dismissedInsightIds: const {},
        strings: strings,
      );
      expect(analytics.totalEntries, equals(1));
      expect(analytics.averageIntensity, equals(3.0));
      expect(analytics.emotionFrequencies['Restless'], isNull);
      expect(analytics.emotionFrequencies['Calm'], equals(1));

      // 3. Delete entry
      await repo.deleteTrace(initialTrace.id);
      traces = await repo.getAllTraces();
      expect(traces, isEmpty);

      analytics = ProgressAnalyticsCalculator.computeAnalytics(
        allTraces: traces,
        allCases: const [],
        journeyState: null,
        timeWindow: ProgressTimeWindow.thirtyDays,
        dismissedInsightIds: const {},
        strings: strings,
      );
      expect(analytics.isEmpty, isTrue);
    });
  });

  group('Onboarding & Profile Data Continuity', () {
    test('preserves conditions, goals, and consent preferences across profile edits', () async {
      final repo = LocalProfileRepository();
      const userId = 'continuity_user';

      // 1. Initial profile from onboarding
      final initialProfile = PsychologicalProfileModel(
        userId: userId,
        preferredName: 'Investigator 409',
        conditions: const [
          UserConditionEntry(
            condition: ConditionType.generalizedAnxiety,
            status: DiagnosticStatus.professionallyDiagnosed,
          ),
          UserConditionEntry(
            condition: ConditionType.sleepDisorders,
            status: DiagnosticStatus.selfIdentifiedExploring,
          ),
        ],
        personalGoals: 'Understand sleep and anxiety loops',
        communicationPreference: 'analytical_reflective',
        shareWithAiCompanion: true,
        updatedAt: DateTime.now(),
      );

      await repo.saveProfile(initialProfile, userId: userId);

      // 2. Load profile
      var loaded = await repo.getProfile(userId: userId);
      expect(loaded.conditions.length, equals(2));
      expect(loaded.conditions.first.condition, equals(ConditionType.generalizedAnxiety));
      expect(loaded.conditions.first.status, equals(DiagnosticStatus.professionallyDiagnosed));
      expect(loaded.shareWithAiCompanion, isTrue);

      // 3. Edit personal context without losing conditions
      final updated = loaded.copyWith(
        personalIntroduction: 'Forensic analyst exploring cognitive patterns',
        shareWithAiCompanion: false, // User revokes AI context consent
      );
      await repo.saveProfile(updated, userId: userId);

      loaded = await repo.getProfile(userId: userId);
      expect(loaded.personalIntroduction, equals('Forensic analyst exploring cognitive patterns'));
      expect(loaded.conditions.length, equals(2)); // Conditions fully intact
      expect(loaded.shareWithAiCompanion, isFalse); // Revocation respected
    });
  });

  group('Navigation & Routing Aliasing Tests', () {
    testWidgets('resolves /check-in and /mind-trace redirects to TrackScreen without throwing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to /check-in alias -> lands on TrackScreen
      AppRouter.router.go('/check-in');
      await tester.pumpAndSettle();
      expect(find.byType(TrackScreen), findsOneWidget);
      expect(find.text('Check-In Today'), findsOneWidget);

      // Navigate to /mind-trace alias -> lands on TrackScreen
      AppRouter.router.go(AppRouter.mindTrace);
      await tester.pumpAndSettle();
      expect(find.byType(TrackScreen), findsOneWidget);

      // Navigate with initialTabIndex: 1 -> lands on History & Calendar tab
      AppRouter.router.go(AppRouter.mindTrace, extra: {'initialTabIndex': 1});
      await tester.pumpAndSettle();
      expect(find.byType(TrackScreen), findsOneWidget);
      expect(find.byTooltip('Previous month'), findsOneWidget);

      // Return home
      AppRouter.router.go(AppRouter.home);
      await tester.pumpAndSettle();
      expect(find.textContaining('Mind Forensics'), findsWidgets);
    });
  });
}
