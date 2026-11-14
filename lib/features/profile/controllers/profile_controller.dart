import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/secure_key_manager.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/local_profile_repository.dart';
import '../domain/condition_type.dart';
import '../domain/diagnostic_status.dart';
import '../domain/psychological_profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final keyManager = ref.watch(secureKeyManagerProvider);
  return LocalProfileRepository(keyManager: keyManager);
});

class ProfileNotifier extends AsyncNotifier<PsychologicalProfileModel> {
  @override
  Future<PsychologicalProfileModel> build() async {
    final repo = ref.watch(profileRepositoryProvider);
    final userId = ref.watch(authControllerProvider.select((s) => s.user?.id));
    final codename = ref.watch(authControllerProvider.select((s) => s.user?.codename));

    final profile = await repo.getProfile(userId: userId);

    // Pre-populate preferredName from auth codename if not yet set
    if (profile.preferredName.isEmpty &&
        codename != null &&
        codename.isNotEmpty) {
      return profile.copyWith(preferredName: codename);
    }

    return profile;
  }

  String? get _currentUserId => ref.read(authControllerProvider).user?.id;

  // 1. About Me
  Future<void> updateAboutMe({
    String? preferredName,
    String? ageRange,
    String? biologicalSex,
    String? preferredLanguage,
    String? personalIntroduction,
    String? additionalContext,
  }) async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final updated = current.copyWith(
      preferredName: preferredName,
      ageRange: ageRange,
      biologicalSex: biologicalSex,
      preferredLanguage: preferredLanguage,
      personalIntroduction: personalIntroduction,
      additionalContext: additionalContext,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(profileRepositoryProvider).saveProfile(updated, userId: _currentUserId);
  }

  Future<void> updateMentalHealthBackground(String background) async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final updated = current.copyWith(
      mentalHealthBackground: background,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(profileRepositoryProvider).saveProfile(updated, userId: _currentUserId);
  }

  Future<void> updateProfessionalSupport(String support) async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final updated = current.copyWith(
      professionalSupport: support,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(profileRepositoryProvider).saveProfile(updated, userId: _currentUserId);
  }

  Future<void> updateOnboardingStep(int step) async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final updated = current.copyWith(
      onboardingStep: step,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(profileRepositoryProvider).saveProfile(updated, userId: _currentUserId);
  }

  // 2. Conditions & Experiences
  Future<void> toggleCondition(
    ConditionType condition, {
    DiagnosticStatus status = DiagnosticStatus.selfIdentifiedExploring,
  }) async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final exists = current.hasCondition(condition);

    List<UserConditionEntry> updatedList;
    if (exists) {
      updatedList = current.conditions.where((c) => c.condition != condition).toList();
    } else {
      updatedList = [
        ...current.conditions,
        UserConditionEntry(condition: condition, status: status),
      ];
    }

    final updated = current.copyWith(
      conditions: updatedList,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(profileRepositoryProvider).saveProfile(updated, userId: _currentUserId);
  }

  Future<void> updateConditionStatus(
    ConditionType condition,
    DiagnosticStatus status, {
    String? note,
  }) async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final updatedList = current.conditions.map((entry) {
      if (entry.condition == condition) {
        return entry.copyWith(
          status: status,
          note: note ?? entry.note,
        );
      }
      return entry;
    }).toList();

    final updated = current.copyWith(
      conditions: updatedList,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(profileRepositoryProvider).saveProfile(updated, userId: _currentUserId);
  }

  Future<void> removeCondition(ConditionType condition) async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final updatedList = current.conditions.where((c) => c.condition != condition).toList();
    final updated = current.copyWith(
      conditions: updatedList,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(profileRepositoryProvider).saveProfile(updated, userId: _currentUserId);
  }

  // 3. Symptoms and Difficulties
  Future<void> updateSymptoms({
    List<String>? selectedSymptoms,
    String? symptomNotes,
  }) async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final updated = current.copyWith(
      selectedSymptoms: selectedSymptoms,
      symptomNotes: symptomNotes,
      symptomsAndExperiences: (selectedSymptoms ?? current.selectedSymptoms).join(', '),
      currentDifficulties: symptomNotes ?? current.symptomNotes,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(profileRepositoryProvider).saveProfile(updated, userId: _currentUserId);
  }

  // 4. Personal Goals
  Future<void> updateGoals({
    List<String>? selectedGoals,
    String? customGoal,
  }) async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final goalsList = selectedGoals ?? current.selectedGoals;
    final allGoalsString = [
      ...goalsList,
      if (customGoal != null && customGoal.trim().isNotEmpty) customGoal.trim(),
    ].join(', ');

    final updated = current.copyWith(
      selectedGoals: goalsList,
      customGoal: customGoal,
      personalGoals: allGoalsString,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(profileRepositoryProvider).saveProfile(updated, userId: _currentUserId);
  }

  // 5. Personal Context
  Future<void> updatePersonalContext(String contextText) async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final updated = current.copyWith(
      personalContext: contextText.trim(),
      notesForAiCompanion: contextText.trim(),
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(profileRepositoryProvider).saveProfile(updated, userId: _currentUserId);
  }

  // 6. Communication Preferences
  Future<void> updateCommunicationPreferences({
    String? communicationTone,
    String? responseLength,
    List<String>? distressPreferences,
    List<String>? dislikedApproaches,
  }) async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final updated = current.copyWith(
      communicationTone: communicationTone,
      communicationPreference: communicationTone ?? current.communicationPreference,
      responseLength: responseLength,
      distressPreferences: distressPreferences,
      dislikedApproaches: dislikedApproaches,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(profileRepositoryProvider).saveProfile(updated, userId: _currentUserId);
  }

  // 7. Privacy & AI Consent
  Future<void> setShareWithAiCompanion(bool allow) async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final updated = current.copyWith(
      shareWithAiCompanion: allow,
      consentVersion: PsychologicalProfileModel.kCurrentConsentVersion,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(profileRepositoryProvider).saveProfile(updated, userId: _currentUserId);
  }

  Future<void> setAiPersonalization(bool allow) async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final updated = current.copyWith(
      allowAiPersonalization: allow,
      consentVersion: PsychologicalProfileModel.kCurrentConsentVersion,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(profileRepositoryProvider).saveProfile(updated, userId: _currentUserId);
  }

  // Clear free-text notes only (preserves conditions, goals, and settings)
  Future<void> clearProfileNotes() async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final updated = current.copyWith(
      personalIntroduction: '',
      additionalContext: '',
      symptomNotes: '',
      currentDifficulties: '',
      personalContext: '',
      notesForAiCompanion: '',
      personalTriggers: '',
      customAiDirectives: '',
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(profileRepositoryProvider).saveProfile(updated, userId: _currentUserId);
  }

  // Complete profile reset
  Future<void> clearProfile() async {
    final fresh = PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    state = AsyncValue.data(fresh);
    await ref.read(profileRepositoryProvider).clearProfile(userId: _currentUserId);
  }

  // Full save
  Future<void> saveFullProfile(PsychologicalProfileModel profile) async {
    final effective = profile.copyWith(userId: _currentUserId ?? profile.userId);
    state = AsyncValue.data(effective);
    await ref.read(profileRepositoryProvider).saveProfile(effective, userId: _currentUserId);
  }

  // Backward compatibility updateDetails
  Future<void> updateDetails({
    String? symptomsAndExperiences,
    String? duration,
    String? currentDifficulties,
    String? personalTriggers,
    String? currentTreatment,
    String? personalGoals,
    String? notesForAiCompanion,
    bool? shareWithAiCompanion,
    bool? allowAiPersonalization,
  }) async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final updated = current.copyWith(
      symptomsAndExperiences: symptomsAndExperiences,
      duration: duration,
      currentDifficulties: currentDifficulties,
      personalTriggers: personalTriggers,
      currentTreatment: currentTreatment,
      personalGoals: personalGoals,
      notesForAiCompanion: notesForAiCompanion,
      personalContext: notesForAiCompanion ?? current.personalContext,
      shareWithAiCompanion: shareWithAiCompanion ?? current.shareWithAiCompanion,
      allowAiPersonalization: allowAiPersonalization ?? current.allowAiPersonalization,
      consentVersion: (shareWithAiCompanion != null || allowAiPersonalization != null)
          ? PsychologicalProfileModel.kCurrentConsentVersion
          : current.consentVersion,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(profileRepositoryProvider).saveProfile(updated, userId: _currentUserId);
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileNotifier, PsychologicalProfileModel>(
  ProfileNotifier.new,
);
