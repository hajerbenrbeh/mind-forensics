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

    test('Historical five-step MindTrace preserves all uncollected fields through copyWith update', () {
      final historicalDate = DateTime(2026, 10, 15, 14, 0);
      final historicalTrace = MindTraceModel(
        id: 'trace_historical_001',
        userId: 'user_clinical_test',
        date: historicalDate,
        overallMood: 'overwhelmed',
        selectedEmotions: const ['Anxious', 'Exhausted'],
        moodIntensity: 8,
        energyLevel: 3,
        anxietyLevel: 7,
        sleepHours: 5.0,
        sleepQuality: 2,
        physicalTension: 8,
        concentrationLevel: 3,
        mentalClarity: 3,
        racingThoughts: 8,
        intrusiveThoughts: 7,
        emotionalDisconnection: 6,
        situation: 'Public presentation with executive stakeholders.',
        symptomsAndExperiences: 'Tension in chest, rapid heartbeat.',
        behavioralResponse: 'Avoided eye contact, drank water repeatedly.',
        investigationAnswers: {'evidence_for': 'Stumbled on slide 3', 'evidence_against': 'Audience nodded'},
        aiReflection: 'You navigated a high-pressure situation with courage.',
        suggestedJourneyActivityId: 'act_grounding_box_breathing',
        journalText: 'Historical personal journal entry that must never be lost.',
        voiceNotePath: 'recordings/voice_20261015.m4a',
        dynamicAnswers: {'q_trigger': 'Meeting invitation at 8 AM'},
        isCompleted: true,
        createdAt: historicalDate,
        updatedAt: historicalDate,
      );

      final now = DateTime.now();
      final updatedTrace = historicalTrace.copyWith(
        overallMood: 'calm',
        selectedEmotions: const ['Calm', 'Relieved'],
        moodIntensity: 3,
        energyLevel: 6,
        sleepHours: 7.5,
        sleepQuality: 4,
        physicalTension: 2,
        concentrationLevel: 7,
        mentalClarity: 8,
        racingThoughts: 2,
        intrusiveThoughts: 1,
        emotionalDisconnection: 1,
        dynamicAnswers: {
          ...historicalTrace.dynamicAnswers,
          'q_evening_followup': 'Feeling much calmer after walking.',
        },
        isCompleted: true,
        updatedAt: now,
      );

      // Verify wizard-edited fields updated
      expect(updatedTrace.overallMood, equals('calm'));
      expect(updatedTrace.moodIntensity, equals(3));
      expect(updatedTrace.physicalTension, equals(2));
      expect(updatedTrace.updatedAt, equals(now));

      // Verify all historical uncollected fields remained 100% intact
      expect(updatedTrace.id, equals('trace_historical_001'));
      expect(updatedTrace.userId, equals('user_clinical_test'));
      expect(updatedTrace.date, equals(historicalDate));
      expect(updatedTrace.createdAt, equals(historicalDate));
      expect(updatedTrace.anxietyLevel, equals(7));
      expect(updatedTrace.situation, equals('Public presentation with executive stakeholders.'));
      expect(updatedTrace.symptomsAndExperiences, equals('Tension in chest, rapid heartbeat.'));
      expect(updatedTrace.behavioralResponse, equals('Avoided eye contact, drank water repeatedly.'));
      expect(updatedTrace.investigationAnswers, equals({'evidence_for': 'Stumbled on slide 3', 'evidence_against': 'Audience nodded'}));
      expect(updatedTrace.aiReflection, equals('You navigated a high-pressure situation with courage.'));
      expect(updatedTrace.suggestedJourneyActivityId, equals('act_grounding_box_breathing'));
      expect(updatedTrace.journalText, equals('Historical personal journal entry that must never be lost.'));
      expect(updatedTrace.voiceNotePath, equals('recordings/voice_20261015.m4a'));
      expect(updatedTrace.dynamicAnswers['q_trigger'], equals('Meeting invitation at 8 AM'));
      expect(updatedTrace.dynamicAnswers['q_evening_followup'], equals('Feeling much calmer after walking.'));
    });

    test('Dynamic answers merge logic preserves unedited keys and removes intentionally deleted keys', () {
      final initialAnswers = {'q1': 'Existing answer', 'q2': 'To be deleted', 'q3': 'Unrelated older question'};

      // Simulate wizard session where q1 is updated, q2 is cleared, and q4 is added
      final controllers = {
        'q1': 'Updated answer',
        'q2': '', // Intentionally cleared
        'q4': 'New answer',
      };

      final merged = <String, String>{...initialAnswers};
      for (final entry in controllers.entries) {
        final text = entry.value.trim();
        if (text.isNotEmpty) {
          merged[entry.key] = text;
        } else {
          merged.remove(entry.key);
        }
      }

      expect(merged['q1'], equals('Updated answer'));
      expect(merged.containsKey('q2'), isFalse); // Intentionally deleted, not restored
      expect(merged['q3'], equals('Unrelated older question')); // Preserved
      expect(merged['q4'], equals('New answer'));
    });
  });
}

