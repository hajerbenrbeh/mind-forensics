import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/features/journey/controllers/journey_controller.dart';
import 'package:mind_forensics/features/observatory/data/local_symptom_repository.dart';
import 'package:mind_forensics/features/observatory/data/observatory_ai_service.dart';
import 'package:mind_forensics/features/observatory/domain/default_symptom_library.dart';
import 'package:mind_forensics/features/observatory/domain/symptom_entry.dart';
import 'package:mind_forensics/features/observatory/domain/symptom_report.dart';
import 'package:mind_forensics/features/observatory/presentation/inner_observatory_screen.dart';
import 'package:mind_forensics/features/observatory/presentation/widgets/add_discovery_sheet.dart';
import 'package:mind_forensics/features/observatory/presentation/widgets/custom_perspective_sheet.dart';
import 'package:mind_forensics/features/observatory/presentation/widgets/custom_symptom_sheet.dart';
import 'package:mind_forensics/features/observatory/presentation/widgets/longitudinal_analysis_view.dart';
import 'package:mind_forensics/features/observatory/presentation/widgets/symptom_assessment_sheet.dart';
import 'package:mind_forensics/features/observatory/presentation/widgets/symptom_library_view.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:mind_forensics/features/support/presentation/widgets/micro_action_card.dart';
import 'package:mind_forensics/features/support/presentation/widgets/routine_anchor_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Inner Observatory Condition-First Symptom Architecture Tests', () {
    test('DefaultSymptomLibrary contains condition-first symptoms across 6 domains', () {
      final all = DefaultSymptomLibrary.entries;
      expect(all.length, greaterThanOrEqualTo(20));

      final domains = all.map((s) => s.domain).toSet();
      expect(domains, contains(SymptomDomain.mood));
      expect(domains, contains(SymptomDomain.anxiety));
      expect(domains, contains(SymptomDomain.cognitive));
      expect(domains, contains(SymptomDomain.attention));
      expect(domains, contains(SymptomDomain.somatic));
      expect(domains, contains(SymptomDomain.stress));

      // Assert zero emojis in all titles and descriptions
      final emojiRegex = RegExp(
        r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
        unicode: true,
      );
      for (final s in all) {
        expect(emojiRegex.hasMatch(s.titleEn), isFalse);
        expect(emojiRegex.hasMatch(s.descriptionEn), isFalse);
      }
    });

    test('LocalSymptomRepository saves custom symptoms and logs multiple symptom reports', () async {
      final repo = LocalSymptomRepository();

      // 1. Initial list has defaults
      final initial = await repo.getAllSymptoms();
      expect(initial.length, DefaultSymptomLibrary.entries.length);

      // 2. Add custom symptom
      final custom = SymptomEntry(
        id: 'custom_1',
        titleEn: 'Afternoon Sensory Drain',
        titleFr: 'Fatigue sensorielle de l’après-midi',
        titleAr: 'إجهاد حسي بعد الظهر',
        descriptionEn: 'Sharp sensitivity to sound after lunch',
        descriptionFr: 'Sensibilité accrue au bruit après le déjeuner',
        descriptionAr: 'حساسية مفرطة للأصوات بعد الغداء',
        domain: SymptomDomain.stress,
        isCustom: true,
        createdAt: DateTime.now(),
      );
      await repo.saveCustomSymptom(custom);

      final withCustom = await repo.getAllSymptoms();
      expect(withCustom.length, initial.length + 1);
      expect(withCustom.any((s) => s.id == 'custom_1'), isTrue);

      // 3. Save multiple symptom report
      final report = SymptomReport(
        id: 'rep_1',
        symptomIds: ['sym_persistent_heaviness', 'sym_task_initiation_paralysis', 'custom_1'],
        intensity: 7,
        somaticLocation: 'chest',
        contextTrigger: 'work_study',
        createdAt: DateTime.now(),
      );
      await repo.saveReport(report);

      final reports = await repo.getAllReports();
      expect(reports.length, 1);
      expect(reports.first.symptomIds.length, 3);
      expect(reports.first.symptomIds, contains('custom_1'));

      // 4. Frequency calculation
      final freqs = await repo.getSymptomFrequencies(days: 14);
      expect(freqs['custom_1'], 1);
      expect(freqs['sym_persistent_heaviness'], 1);

      // 5. Delete custom symptom
      await repo.deleteCustomSymptom('custom_1');
      final afterDelete = await repo.getAllSymptoms();
      expect(afterDelete.any((s) => s.id == 'custom_1'), isFalse);
    });

    test('ObservatoryAiService distinguishes observations from hypotheses and respects mock key', () async {
      final aiService = ObservatoryAiService(
        apiKey: ObservatoryAiService.kDevMockKey,
      );

      final symptoms = [
        DefaultSymptomLibrary.entries.firstWhere((s) => s.id == 'sym_task_initiation_paralysis'),
        DefaultSymptomLibrary.entries.firstWhere((s) => s.id == 'sym_mental_scatter'),
      ];

      // 1. Adaptive follow-up question
      final question = aiService.generateAdaptiveFollowUpQuestion(
        selectedSymptoms: symptoms,
        profile: null,
        languageCode: 'en',
      );
      expect(question, isNotEmpty);
      expect(question, contains('barrier to starting'));

      // 2. Immediate analysis
      final result = await aiService.analyzeSymptoms(
        selectedSymptoms: symptoms,
        intensity: 8,
        contextTrigger: 'work_study',
        somaticLocation: 'jaw_neck',
        userAdaptiveAnswer: 'Overwhelmed by small details',
        baseline: null,
        profile: null,
        languageCode: 'en',
      );

      expect(result.analysis, contains('Reported Observations'));
      expect(result.analysis, contains('Reflective Hypothesis'));
      expect(result.analysis, contains('not a clinical diagnosis'));
      expect(result.stabilizingStrategy, isNotEmpty);
    });

    testWidgets('SymptomLibraryView renders condition-first symptoms and supports multi-selection', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SymptomLibraryView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify search input
      expect(find.byType(TextField), findsOneWidget);

      // Verify category chips
      expect(find.text('Mood & Emotion'), findsOneWidget);
      expect(find.text('Anxiety & Tension'), findsOneWidget);
      expect(find.text('Focus & Attention'), findsOneWidget);

      // Verify symptom entries
      expect(find.text('Persistent Heaviness'), findsOneWidget);
      expect(find.text('Task Initiation Paralysis'), findsOneWidget);

      // Select multiple symptoms
      await tester.tap(find.text('Persistent Heaviness'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Task Initiation Paralysis'));
      await tester.pumpAndSettle();

      // Verify action bar with 2 selected
      expect(find.text('2 symptoms selected'), findsOneWidget);
      expect(find.text('Assess Symptoms'), findsOneWidget);
    });

    testWidgets('CustomSymptomSheet allows adding custom non-compulsory symptom', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CustomSymptomSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Custom Symptom / Experience'), findsOneWidget);
      expect(find.text('Category Domain:'), findsOneWidget);
      expect(find.text('Save to Observatory'), findsOneWidget);
    });

    testWidgets('SymptomAssessmentSheet walks through structured steps to immediate analysis', (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final symptoms = [
        DefaultSymptomLibrary.entries.firstWhere((s) => s.id == 'sym_constant_apprehension'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SymptomAssessmentSheet(selectedSymptoms: symptoms),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 0: Intensity & Context
      expect(find.text('Constant Apprehension'), findsOneWidget);
      expect(find.text('Current Intensity:'), findsOneWidget);
      expect(find.text('Continue Exploration'), findsOneWidget);

      // Advance to Step 1: Adaptive Socratic Inquiry
      await tester.tap(find.text('Continue Exploration'));
      await tester.pumpAndSettle();

      expect(find.text('Suggested responses (Options-First):'), findsOneWidget);
      expect(find.text('Generate Immediate Analysis'), findsOneWidget);

      // Advance to Step 2: Immediate Analysis
      await tester.tap(find.text('Generate Immediate Analysis'));
      await tester.pumpAndSettle();

      expect(find.text('IMMEDIATE REFLECTIVE SYNTHESIS'), findsOneWidget);
      expect(find.text('Log to Observatory Timeline'), findsOneWidget);
    });

    test('JourneyNotifier adds and deletes custom discoveries correctly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = await container.read(journeyControllerProvider.future);
      final initialCount = initial.activities.length;

      // Add a custom discovery
      await container.read(journeyControllerProvider.notifier).addCustomDiscovery(
        title: 'Energy fluctuates naturally',
        notes: 'Low stamina in morning does not ruin whole day',
        category: 'Body Wisdom',
      );

      final afterAdd = container.read(journeyControllerProvider).value!;
      expect(afterAdd.activities.length, initialCount + 1);
      final newDiscovery = afterAdd.activities.first;
      expect(newDiscovery.title, 'Energy fluctuates naturally');
      expect(newDiscovery.personalNotes, 'Low stamina in morning does not ruin whole day');
      expect(newDiscovery.isCompleted, isTrue);

      // Delete the custom discovery
      await container.read(journeyControllerProvider.notifier).deleteDiscovery(newDiscovery.id);
      final afterDelete = container.read(journeyControllerProvider).value!;
      expect(afterDelete.activities.length, initialCount);
      expect(afterDelete.activities.any((a) => a.id == newDiscovery.id), isFalse);
    });

    testWidgets('LongitudinalAnalysisView renders time windows and baseline card', (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LongitudinalAnalysisView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LONGITUDINAL SYMPTOM ANALYSIS'), findsOneWidget);
      expect(find.text('7d'), findsOneWidget);
      expect(find.text('14d'), findsOneWidget);
      expect(find.text('30d'), findsOneWidget);
      expect(find.text('PERSONAL BASELINE TELEMETRY'), findsOneWidget);

      // Switch to 30d window
      await tester.tap(find.text('30d'));
      await tester.pumpAndSettle();
    });

    testWidgets('AddDiscoverySheet allows selecting category and saving custom discovery', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(journeyControllerProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AddDiscoverySheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RECORD A DISCOVERY'), findsOneWidget);
      expect(find.text('Thought Shift'), findsOneWidget);
      expect(find.text('Body Wisdom'), findsOneWidget);
      expect(find.text('Boundary'), findsOneWidget);
      expect(find.text('Gentle Reminder'), findsOneWidget);

      // Tap Body Wisdom category
      await tester.tap(find.text('Body Wisdom'));
      await tester.pumpAndSettle();

      // Tap a suggestion pill
      await tester.tap(find.text('Energy fluctuates naturally'));
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save Personal Discovery'));
      await tester.pumpAndSettle();

      final state = container.read(journeyControllerProvider).value!;
      expect(state.activities.any((a) => a.title == 'Energy fluctuates naturally'), isTrue);
    });

    testWidgets('CustomPerspectiveSheet steps through Fact -> Interpretation -> Alternative and saves', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(journeyControllerProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: CustomPerspectiveSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 0: Fact
      expect(find.text('1. What is the observable fact?'), findsOneWidget);
      await tester.tap(find.text('Unanswered message or silence'));
      await tester.pumpAndSettle();

      // Step 1: Interpretation
      expect(find.text('2. What story did your mind assume?'), findsOneWidget);
      await tester.tap(find.text('They are annoyed and rejecting me'));
      await tester.pumpAndSettle();

      // Step 2: Grounded Alternative
      expect(find.text('3. Grounded alternative explanation'), findsOneWidget);
      await tester.tap(find.text('Their delay reflects their own busy day, not a verdict on me.'));
      await tester.pumpAndSettle();

      // Save as discovery
      expect(find.text('Save as Personal Discovery'), findsOneWidget);
      await tester.tap(find.text('Save as Personal Discovery'));
      await tester.pumpAndSettle();

      final state = container.read(journeyControllerProvider).value!;
      expect(state.activities.any((a) => a.title.contains('Their delay reflects their own busy day')), isTrue);
      expect(state.activities.any((a) => a.purpose == 'Perspective Reframe'), isTrue);
    });

    testWidgets('InnerObservatoryScreen renders tabs and allows deleting a discovery', (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Ensure journey state is loaded before adding
      await container.read(journeyControllerProvider.future);
      await container.read(journeyControllerProvider.notifier).addCustomDiscovery(
        title: 'Observatory Insight',
        notes: 'Testing insight delete action',
        category: 'Thought Shift',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: InnerObservatoryScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tab 0 is Reframe Thought
      expect(find.text('Reframe Thought'), findsWidgets);

      // Switch to Tab 1: Coping Steps
      await tester.tap(find.text('Coping Steps').first);
      await tester.pumpAndSettle();
      expect(find.byType(MicroActionCard), findsOneWidget);
      expect(find.byType(RoutineAnchorCard), findsOneWidget);

      // Switch to Tab 2: Saved Notes
      await tester.tap(find.text('Saved Notes').first);
      await tester.pumpAndSettle();
      expect(find.text('Observatory Insight'), findsOneWidget);
      expect(find.text('Testing insight delete action'), findsOneWidget);

      // Delete the discovery
      final deleteBtn = find.bySemanticsLabel('Delete discovery');
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Verify discovery is removed from UI
      expect(find.text('Observatory Insight'), findsNothing);
    });

    testWidgets('MicroActionCard allows completing action and saving as discovery', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(journeyControllerProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: MicroActionCard()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start 2 Minutes'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Complete action
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Save to Discoveries'), findsOneWidget);
      await tester.tap(find.text('Save to Discoveries'));
      await tester.pumpAndSettle();

      final state = container.read(journeyControllerProvider).value!;
      expect(state.activities.any((a) => a.purpose == 'Behavioral Strategy'), isTrue);
    });

    testWidgets('RoutineAnchorCard allows adopting anchor and saving to discoveries', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(journeyControllerProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: RoutineAnchorCard()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Adopt as My Anchor Today'), findsOneWidget);
      await tester.tap(find.text('Adopt as My Anchor Today'));
      await tester.pumpAndSettle();

      expect(find.text('Adopted for Today'), findsOneWidget);
      expect(find.text('Save Anchor to Discoveries'), findsOneWidget);

      await tester.tap(find.text('Save Anchor to Discoveries'));
      await tester.pumpAndSettle();

      final state = container.read(journeyControllerProvider).value!;
      expect(state.activities.any((a) => a.purpose == 'Daily Routine Anchor'), isTrue);
    });

    testWidgets('LongitudinalAnalysisView dynamically computes frequency distributions from actual multiple reports', (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Save two real reports with different symptoms
      final repo = container.read(symptomRepositoryProvider);
      final now = DateTime.now();

      await repo.saveReport(SymptomReport(
        id: 'rep_101',
        symptomIds: ['sym_persistent_heaviness', 'sym_mental_scatter'],
        intensity: 8,
        createdAt: now.subtract(const Duration(hours: 2)),
      ));

      await repo.saveReport(SymptomReport(
        id: 'rep_102',
        symptomIds: ['sym_persistent_heaviness'],
        intensity: 6,
        createdAt: now.subtract(const Duration(hours: 1)),
      ));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: LongitudinalAnalysisView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Frequencies: Persistent Heaviness appeared twice, Mental Scatter appeared once
      expect(find.text('2 times'), findsOneWidget);
      expect(find.text('1 times'), findsOneWidget);
      expect(find.text('Persistent Heaviness'), findsOneWidget);
      expect(find.text('Mental Scatter & Brain Fog'), findsOneWidget);
    });

    test('ObservatoryAiService respects explicit consent and remains non-pathologizing', () async {
      final aiService = ObservatoryAiService(apiKey: 'some_real_key_format');

      // Profile without consent
      final noConsentProfile = PsychologicalProfileModel(
        userId: 'u1',
        shareWithAiCompanion: false,
        allowAiPersonalization: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final symptoms = [
        DefaultSymptomLibrary.entries.firstWhere((s) => s.id == 'sym_persistent_heaviness'),
      ];

      final res = await aiService.analyzeSymptoms(
        selectedSymptoms: symptoms,
        intensity: 7,
        contextTrigger: 'work',
        somaticLocation: 'chest',
        userAdaptiveAnswer: 'Felt tired',
        baseline: null,
        profile: noConsentProfile,
        languageCode: 'en',
      );

      // Must generate local non-diagnostic analysis without making remote calls
      expect(res.analysis, contains('Reported Observations:'));
      expect(res.analysis, contains('Reflective Hypothesis:'));
      expect(res.analysis, contains('not a clinical diagnosis'));
      expect(res.stabilizingStrategy, isNotEmpty);
    });
  });
}
