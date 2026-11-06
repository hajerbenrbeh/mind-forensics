import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../data/local_profile_repository.dart';
import '../domain/condition_type.dart';
import '../domain/diagnostic_status.dart';
import '../domain/psychological_profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return LocalProfileRepository();
});

class ProfileNotifier extends AsyncNotifier<PsychologicalProfileModel> {
  @override
  Future<PsychologicalProfileModel> build() async {
    final repo = ref.watch(profileRepositoryProvider);
    final authUser = ref.watch(authControllerProvider).user;
    final userId = authUser?.id;

    final profile = await repo.getProfile(userId: userId);

    // Pre-populate preferredName from auth codename if not yet set
    if (profile.preferredName.isEmpty &&
        authUser != null &&
        authUser.codename.isNotEmpty) {
      return profile.copyWith(preferredName: authUser.codename);
    }

    return profile;
  }

  String? get _currentUserId => ref.read(authControllerProvider).user?.id;

  // 1. About Me
  Future<void> updateAboutMe({
    String? preferredName,
    String? ageRange,
    String? preferredLanguage,
    String? personalIntroduction,
    String? additionalContext,
  }) async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final updated = current.copyWith(
      preferredName: preferredName,
      ageRange: ageRange,
      preferredLanguage: preferredLanguage,
      personalIntroduction: personalIntroduction,
      additionalContext: additionalContext,
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

  // 7. Privacy & AI Personalization
  Future<void> setAiPersonalization(bool allow) async {
    final current = state.value ?? PsychologicalProfileModel.empty(userId: _currentUserId ?? 'local_user');
    final updated = current.copyWith(
      allowAiPersonalization: allow,
      shareWithAiCompanion: allow,
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
      shareWithAiCompanion: shareWithAiCompanion,
      allowAiPersonalization: shareWithAiCompanion ?? current.allowAiPersonalization,
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
