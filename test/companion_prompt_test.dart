import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/investigation/domain/psychological_companion_prompt.dart';
import 'package:mind_forensics/features/journey/domain/journey_activity.dart';
import 'package:mind_forensics/features/journey/domain/journey_phase.dart';
import 'package:mind_forensics/features/journey/domain/journey_state_model.dart';
import 'package:mind_forensics/features/profile/domain/condition_type.dart';
import 'package:mind_forensics/features/profile/domain/diagnostic_status.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';

void main() {
  group('Psychological Companion Prompt & Context Builder Tests', () {
    test('Base system prompt contains mandated clinical identity & principles', () {
      final base = PsychologicalCompanionPrompt.baseSystemInstruction;

      expect(base.contains('Mind Forensics Psychological Companion'), isTrue);
      expect(base.contains('Cognitive Behavioral Therapy (CBT)'), isTrue);
      expect(base.contains('HANDLING INTRUSIVE THOUGHTS'), isTrue);
      expect(base.contains('HANDLING MOOD DISORDERS'), isTrue);
      expect(base.contains('HANDLING PSYCHOSIS-RELATED EXPERIENCES'), isTrue);
      expect(base.contains('THERAPEUTIC CONVERSATION STRUCTURE'), isTrue);
      expect(base.contains('SAFETY AND PROFESSIONAL BOUNDARIES'), isTrue);
      expect(base.contains('Strictly NO emojis anywhere in your response'), isTrue);
    });

    test('Condition-aware guidelines dynamically adapt for OCD, Bipolar, PTSD, and ADHD', () {
      final ocdGuidance = PsychologicalCompanionPrompt.buildConditionGuidelines(
        [ConditionType.ocd],
      );
      expect(ocdGuidance.contains('OCD: Strictly avoid providing repetitive reassurance'), isTrue);

      final bipolarGuidance = PsychologicalCompanionPrompt.buildConditionGuidelines(
        [ConditionType.bipolarI],
      );
      expect(bipolarGuidance.contains('BIPOLAR SPECTRUM: Monitor for subtle shifts in sleep regularity'), isTrue);
      expect(bipolarGuidance.contains('Never discuss medication adjustments'), isTrue);

      final traumaGuidance = PsychologicalCompanionPrompt.buildConditionGuidelines(
        [ConditionType.ptsd, ConditionType.complexPtsd],
      );
      expect(traumaGuidance.contains('TRAUMA-INFORMED CARE: Prioritize emotional safety and autonomy'), isTrue);
      expect(traumaGuidance.contains('Never press for narrative trauma details'), isTrue);

      final adhdGuidance = PsychologicalCompanionPrompt.buildConditionGuidelines(
        [ConditionType.adhd],
      );
      expect(adhdGuidance.contains('ADHD: Deliver clear, concise, actionable thoughts'), isTrue);

      final psychosisGuidance = PsychologicalCompanionPrompt.buildConditionGuidelines(
        [ConditionType.schizophrenia],
      );
      expect(psychosisGuidance.contains('PSYCHOSIS SPECTRUM: Remain grounded and calm'), isTrue);
      expect(psychosisGuidance.contains('Validate feelings of confusion or distress without validating unverified perceptions'), isTrue);

      final eatingGuidance = PsychologicalCompanionPrompt.buildConditionGuidelines(
        [ConditionType.eatingDisorders],
      );
      expect(eatingGuidance.contains('Strictly never mention calorie targets, weight, body shape, or diet plans'), isTrue);
    });

    test('buildUserContext strictly honors user consent and privacy settings', () {
      final profile = PsychologicalProfileModel(
        conditions: const [
          UserConditionEntry(
            condition: ConditionType.socialAnxiety,
            status: DiagnosticStatus.selfIdentifiedExploring,
          ),
        ],
        symptomsAndExperiences: 'Trembling in public speaking',
        shareWithAiCompanion: false, // Consent disabled
        updatedAt: DateTime.now(),
      );

      final context = PsychologicalCompanionPrompt.buildUserContext(
        profile: profile,
        journey: null,
        languageCode: 'en',
      );

      // When consent is false, profile information must NOT be leaked
      expect(context.contains('Social Anxiety Disorder'), isFalse);
      expect(context.contains('Trembling in public speaking'), isFalse);
    });

    test('buildUserContext injects profile and journey context when consent is true', () {
      final profile = PsychologicalProfileModel(
        conditions: const [
          UserConditionEntry(
            condition: ConditionType.generalizedAnxiety,
            status: DiagnosticStatus.currentlyBeingEvaluated,
            note: 'Morning panic peaks',
          ),
        ],
        symptomsAndExperiences: 'Frequent tension headaches',
        personalGoals: 'Calm the body without fighting thoughts',
        notesForAiCompanion: 'Be direct, no fluff',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime.now(),
      );

      const activity = JourneyActivity(
        id: 'act_1',
        phase: JourneyPhase.phase1SelfDiscovery,
        title: 'Triad Exploration',
        purpose: 'Test purpose',
        shortExplanation: 'Explanation',
        guidedInstructions: ['Step 1'],
        reflectionQuestions: ['Question 1'],
        isCompleted: true,
        personalNotes: 'Felt my stomach drop',
      );

      final journey = JourneyStateModel(
        activePhase: JourneyPhase.phase1SelfDiscovery,
        activities: [activity],
        updatedAt: DateTime.now(),
      );

      final contextAr = PsychologicalCompanionPrompt.buildUserContext(
        profile: profile,
        journey: journey,
        languageCode: 'ar',
      );

      expect(contextAr.contains('تحدث بلهجة تونسية دافئة'), isTrue);
      expect(contextAr.contains('Generalized Anxiety Disorder (GAD)'), isTrue);
      expect(contextAr.contains('Morning panic peaks'), isTrue);
      expect(contextAr.contains('Frequent tension headaches'), isTrue);
      expect(contextAr.contains('Calm the body without fighting thoughts'), isTrue);
      expect(contextAr.contains('Be direct, no fluff'), isTrue);
      expect(contextAr.contains('Triad Exploration'), isTrue);
      expect(contextAr.contains('Felt my stomach drop'), isTrue);
    });

    test('buildUserContext strictly omits profile context when allowAiPersonalization is false even if shareWithAiCompanion is true', () {
      final profile = PsychologicalProfileModel(
        conditions: const [
          UserConditionEntry(
            condition: ConditionType.generalizedAnxiety,
            status: DiagnosticStatus.currentlyBeingEvaluated,
            note: 'Morning panic peaks',
          ),
        ],
        symptomsAndExperiences: 'Frequent tension headaches',
        personalGoals: 'Calm the body without fighting thoughts',
        notesForAiCompanion: 'Be direct, no fluff',
        shareWithAiCompanion: true,
        allowAiPersonalization: false,
        updatedAt: DateTime.now(),
      );

      final context = PsychologicalCompanionPrompt.buildUserContext(
        profile: profile,
        journey: null,
        languageCode: 'en',
      );

      expect(context.contains('Generalized Anxiety Disorder (GAD)'), isFalse);
      expect(context.contains('Morning panic peaks'), isFalse);
      expect(context.contains('Frequent tension headaches'), isFalse);
      expect(context.contains('Calm the body without fighting thoughts'), isFalse);
      expect(context.contains('USER PSYCHOLOGICAL PROFILE'), isFalse);
    });
  });
}

