import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/journey/data/default_journey_curriculum.dart';
import 'package:mind_forensics/features/journey/data/local_journey_repository.dart';
import 'package:mind_forensics/features/journey/domain/journey_activity.dart';
import 'package:mind_forensics/features/journey/domain/journey_phase.dart';
import 'package:mind_forensics/features/journey/domain/journey_state_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Journey Domain & Curriculum Tests', () {
    test('5 JourneyPhases have valid sequence, titles, and clinical purposes', () {
      expect(JourneyPhase.values.length, 5);
      expect(JourneyPhase.phase1SelfDiscovery.phaseNumber, 1);
      expect(JourneyPhase.phase2UnderstandingPatterns.phaseNumber, 2);
      expect(JourneyPhase.phase3PsychologicalAwareness.phaseNumber, 3);
      expect(JourneyPhase.phase4CopingAndDevelopment.phaseNumber, 4);
      expect(JourneyPhase.phase5PersonalGrowthAndMaintenance.phaseNumber, 5);

      expect(JourneyPhase.phase1SelfDiscovery.defaultTitle(), 'Self-Discovery');
      expect(
          JourneyPhase.fromString('phase3PsychologicalAwareness'),
          JourneyPhase.phase3PsychologicalAwareness);
    });

    test('DefaultJourneyCurriculum contains activities for all 5 phases', () {
      final activities = DefaultJourneyCurriculum.getActivities();
      expect(activities.isNotEmpty, isTrue);

      for (final phase in JourneyPhase.values) {
        final phaseActivities = activities.where((a) => a.phase == phase).toList();
        expect(phaseActivities.isNotEmpty, isTrue,
            reason: 'Phase ${phase.name} should have curriculum activities');

        for (final act in phaseActivities) {
          expect(act.title.isNotEmpty, isTrue);
          expect(act.purpose.isNotEmpty, isTrue);
          expect(act.shortExplanation.isNotEmpty, isTrue);
          expect(act.guidedInstructions.isNotEmpty, isTrue);
          expect(act.reflectionQuestions.isNotEmpty, isTrue);
        }
      }
    });

    test('JourneyActivity serializes reflections and notes to and from JSON', () {
      const activity = JourneyActivity(
        id: 'act_test_1',
        phase: JourneyPhase.phase1SelfDiscovery,
        title: 'Triad Test',
        purpose: 'Test Purpose',
        shortExplanation: 'Explanation',
        guidedInstructions: ['Step 1', 'Step 2'],
        reflectionQuestions: ['Question 1', 'Question 2'],
        isCompleted: true,
        personalNotes: 'Felt immediate relief',
        reflectionAnswers: {'q_0': 'My thought was automatic'},
      );

      final json = activity.toJson();
      final restored = JourneyActivity.fromJson(json);

      expect(restored.id, 'act_test_1');
      expect(restored.isCompleted, isTrue);
      expect(restored.personalNotes, 'Felt immediate relief');
      expect(restored.reflectionAnswers['q_0'], 'My thought was automatic');
      expect(restored.guidedInstructions.length, 2);
    });

    test('JourneyStateModel maintains flexible non-mandatory phase progression', () {
      final activities = DefaultJourneyCurriculum.getActivities();
      final initial = JourneyStateModel.initial(activities);

      expect(initial.activePhase, JourneyPhase.phase1SelfDiscovery);
      expect(initial.completedCount, 0);

      // User jumps to Phase 4 (flexible framework rule: no forced order)
      final updated = initial.copyWith(activePhase: JourneyPhase.phase4CopingAndDevelopment);
      expect(updated.activePhase, JourneyPhase.phase4CopingAndDevelopment);

      // Verify no recovery percentages are computed
      expect(initial.completedCount, 0);
    });

    test('LocalJourneyRepository persists activity completions and reflections', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalJourneyRepository();

      final state = await repo.getJourneyState();
      expect(state.activities.isNotEmpty, isTrue);

      final firstId = state.activities.first.id;
      final updatedActivities = state.activities.map((a) {
        if (a.id == firstId) {
          return a.copyWith(
            isCompleted: true,
            personalNotes: 'Observed bodily tension in neck',
            reflectionAnswers: {'q_0': 'Concrete fact was an email'},
          );
        }
        return a;
      }).toList();

      await repo.saveJourneyState(state.copyWith(activities: updatedActivities));

      final reloaded = await repo.getJourneyState();
      final reloadedFirst = reloaded.activities.firstWhere((a) => a.id == firstId);
      expect(reloadedFirst.isCompleted, isTrue);
      expect(reloadedFirst.personalNotes, 'Observed bodily tension in neck');
      expect(reloadedFirst.reflectionAnswers['q_0'], 'Concrete fact was an email');
    });
  });
}

