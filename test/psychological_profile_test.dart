import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/profile/data/local_profile_repository.dart';
import 'package:mind_forensics/features/profile/domain/condition_type.dart';
import 'package:mind_forensics/features/profile/domain/diagnostic_status.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PsychologicalProfile Domain & Serialization Tests', () {
    test('ConditionType and DiagnosticStatus defaults and enum mapping', () {
      expect(ConditionType.ocd.defaultDisplayName(),
          'OCD (Obsessive-Compulsive Disorder)');
      expect(ConditionType.fromString('bipolarI'), ConditionType.bipolarI);
      expect(
          ConditionType.fromString('unknown_val'), ConditionType.stillExploring);

      expect(DiagnosticStatus.professionallyDiagnosed.defaultDisplayName(),
          'Professionally Diagnosed');
      expect(DiagnosticStatus.fromString('selfIdentifiedExploring'),
          DiagnosticStatus.selfIdentifiedExploring);
      expect(DiagnosticStatus.fromString('invalid'),
          DiagnosticStatus.selfIdentifiedExploring);
    });

    test('UserConditionEntry serializes to and from JSON accurately', () {
      const entry = UserConditionEntry(
        condition: ConditionType.ocd,
        status: DiagnosticStatus.professionallyDiagnosed,
        note: 'Harm OCD themes',
      );

      final json = entry.toJson();
      final restored = UserConditionEntry.fromJson(json);

      expect(restored.condition, ConditionType.ocd);
      expect(restored.status, DiagnosticStatus.professionallyDiagnosed);
      expect(restored.note, 'Harm OCD themes');
    });

    test('PsychologicalProfileModel serializes full profile including optional fields',
        () {
      final now = DateTime.now();
      final profile = PsychologicalProfileModel(
        conditions: const [
          UserConditionEntry(
            condition: ConditionType.adhd,
            status: DiagnosticStatus.selfIdentifiedExploring,
            note: 'Focus issues',
          ),
          UserConditionEntry(
            condition: ConditionType.generalizedAnxiety,
            status: DiagnosticStatus.currentlyBeingEvaluated,
          ),
        ],
        symptomsAndExperiences: 'Racing thoughts, somatic tension in chest',
        duration: 'Past 2 years',
        currentDifficulties: 'Procrastination and social avoidance',
        personalTriggers: 'Unclear deadlines, sudden loud noises',
        currentTreatment: 'Bi-weekly therapy',
        personalGoals: 'Learn to separate thoughts from emotions',
        notesForAiCompanion: 'Ask one question at a time',
        customAiDirectives: 'Keep replies concise and grounding',
        shareWithAiCompanion: true,
        updatedAt: now,
      );

      expect(profile.isEmpty, isFalse);
      expect(profile.hasCondition(ConditionType.adhd), isTrue);
      expect(profile.hasCondition(ConditionType.depression), isFalse);

      final entry = profile.getEntry(ConditionType.adhd);
      expect(entry?.note, 'Focus issues');

      final json = profile.toJson();
      final restored = PsychologicalProfileModel.fromJson(json);

      expect(restored.conditions.length, 2);
      expect(restored.symptomsAndExperiences,
          'Racing thoughts, somatic tension in chest');
      expect(restored.duration, 'Past 2 years');
      expect(restored.personalTriggers,
          'Unclear deadlines, sudden loud noises');
      expect(restored.notesForAiCompanion, 'Ask one question at a time');
      expect(restored.customAiDirectives, 'Keep replies concise and grounding');
      expect(restored.shareWithAiCompanion, isTrue);
    });

    test('LocalProfileRepository saves and hydrates profile using SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalProfileRepository();

      // Initial read returns empty profile
      final initial = await repo.getProfile();
      expect(initial.isEmpty, isTrue);

      // Save updated profile
      final profile = PsychologicalProfileModel(
        conditions: const [
          UserConditionEntry(
            condition: ConditionType.ptsd,
            status: DiagnosticStatus.professionallyDiagnosed,
          ),
        ],
        symptomsAndExperiences: 'Hypervigilance in crowded spaces',
        updatedAt: DateTime.now(),
      );

      await repo.saveProfile(profile);

      // Re-read returns persisted data
      final loaded = await repo.getProfile();
      expect(loaded.hasCondition(ConditionType.ptsd), isTrue);
      expect(loaded.symptomsAndExperiences, 'Hypervigilance in crowded spaces');

      // Clear profile
      await repo.clearProfile();
      final cleared = await repo.getProfile();
      expect(cleared.isEmpty, isTrue);
    });
  });
}

