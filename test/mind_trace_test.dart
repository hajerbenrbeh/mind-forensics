import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/mind_trace/data/local_mind_trace_repository.dart';
import 'package:mind_forensics/features/mind_trace/data/mind_trace_ai_service.dart';
import 'package:mind_forensics/features/mind_trace/domain/dynamic_question_generator.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/mind_trace/domain/trace_milestone.dart';
import 'package:mind_forensics/features/profile/domain/condition_type.dart';
import 'package:mind_forensics/features/profile/domain/diagnostic_status.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Daily Mind Trace Domain & Data Tests', () {
    test('MindTraceModel serializes to and from JSON accurately', () {
      final now = DateTime(2026, 11, 5, 20, 30);
      final trace = MindTraceModel(
        id: 'trace_test_001',
        date: now,
        overallMood: 'anxious',
        selectedEmotions: const ['Overwhelmed', 'Uneasy', 'Fatigued'],
        moodIntensity: 8,
        energyLevel: 3,
        anxietyLevel: 7,
        sleepHours: 5.5,
        sleepQuality: 2,
        physicalTension: 8,
        mentalClarity: 4,
        journalText: 'Felt my mind running ahead with worries about tomorrow.',
        dynamicAnswers: {'q_overwhelmed': 'A sudden meeting invite rushed me.'},
        aiReflection: 'I notice you felt rushed by a meeting.',
        createdAt: now,
        updatedAt: now,
      );

      expect(trace.dateKey, '2026-11-05');
      final json = trace.toJson();
      final restored = MindTraceModel.fromJson(json);

      expect(restored.id, 'trace_test_001');
      expect(restored.overallMood, 'anxious');
      expect(restored.selectedEmotions.length, 3);
      expect(restored.moodIntensity, 8);
      expect(restored.sleepHours, 5.5);
      expect(restored.physicalTension, 8);
      expect(restored.dynamicAnswers['q_overwhelmed'],
          'A sudden meeting invite rushed me.');
      expect(restored.aiReflection, 'I notice you felt rushed by a meeting.');
    });

    test('LocalMindTraceRepository persists, updates, and deletes traces', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalMindTraceRepository();

      // Initially empty
      final initial = await repo.getAllTraces();
      expect(initial.isEmpty, isTrue);

      final now = DateTime.now();
      final trace1 = MindTraceModel(
        id: 't1',
        date: now.subtract(const Duration(days: 1)),
        overallMood: 'calm',
        moodIntensity: 4,
        createdAt: now,
        updatedAt: now,
      );
      final trace2 = MindTraceModel(
        id: 't2',
        date: now,
        overallMood: 'grounded',
        moodIntensity: 6,
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveTrace(trace1);
      await repo.saveTrace(trace2);

      final all = await repo.getAllTraces();
      expect(all.length, 2);

      // Verify today's trace retrieval
      final today = await repo.getTodayTrace();
      expect(today?.id, 't2');

      // Update trace
      final updated = trace2.copyWith(moodIntensity: 7);
      await repo.saveTrace(updated);
      final allUpdated = await repo.getAllTraces();
      expect(allUpdated.firstWhere((t) => t.id == 't2').moodIntensity, 7);

      // Delete trace
      await repo.deleteTrace('t1');
      final afterDelete = await repo.getAllTraces();
      expect(afterDelete.length, 1);
      expect(afterDelete.first.id, 't2');
    });

    test('DynamicQuestionGenerator adapts questions to profile conditions and history', () {
      final profileOcd = PsychologicalProfileModel(
        conditions: const [
          UserConditionEntry(
            condition: ConditionType.ocd,
            status: DiagnosticStatus.selfIdentifiedExploring,
          ),
        ],
        updatedAt: DateTime.now(),
      );

      final questions = DynamicQuestionGenerator.getQuestionsForUser(
        profile: profileOcd,
        recentTraces: [],
        languageCode: 'en',
      );

      expect(questions.any((q) => q.id == 'q_recurring_thoughts'), isTrue);

      // Test with Arabic dialect
      final questionsAr = DynamicQuestionGenerator.getQuestionsForUser(
        profile: profileOcd,
        recentTraces: [],
        languageCode: 'ar',
      );
      expect(questionsAr.first.questionText.contains('أفكار متكررة'), isTrue);
    });

    test('TraceMilestone accurately calculates non-punitive milestone progress', () {
      final milestones = TraceMilestone.allMilestones;
      expect(milestones.isNotEmpty, isTrue);

      final firstStar = milestones.firstWhere((m) => m.id == 'ms_first_star');
      expect(firstStar.isUnlocked(0, 0), isFalse);
      expect(firstStar.isUnlocked(1, 0), isTrue);

      final sevenCluster = milestones.firstWhere((m) => m.id == 'ms_seven_cluster');
      expect(sevenCluster.isUnlocked(6, 0), isFalse);
      expect(sevenCluster.isUnlocked(7, 2), isTrue);

      final master = milestones.firstWhere((m) => m.id == 'ms_constellation_master');
      expect(master.isUnlocked(29, 10), isFalse);
      expect(master.isUnlocked(30, 10), isTrue);
    });

    test('MindTraceAiService generates empathetic reflection distinguishing observations from hypotheses', () async {
      final service = MindTraceAiService();

      final current = MindTraceModel(
        id: 'trace_now',
        date: DateTime.now(),
        overallMood: 'anxious',
        moodIntensity: 8,
        physicalTension: 8,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final reflection = await service.generateDailyReflection(
        currentTrace: current,
        history: [],
        profile: null,
        languageCode: 'en',
      );

      expect(reflection.isNotEmpty, isTrue);
      // Ensure zero emojis
      expect(reflection.contains(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true)), isFalse);
    });
  });
}

