import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/security/secure_key_manager.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/local_journey_repository.dart';
import '../domain/journey_activity.dart';
import '../domain/journey_phase.dart';
import '../domain/journey_state_model.dart';

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.user?.id));
  final keyManager = ref.watch(secureKeyManagerProvider);
  return LocalJourneyRepository(
    userId: userId,
    keyManager: keyManager,
  );
});

class JourneyNotifier extends AsyncNotifier<JourneyStateModel> {
  @override
  Future<JourneyStateModel> build() async {
    final repo = ref.watch(journeyRepositoryProvider);
    return repo.getJourneyState();
  }

  Future<void> setActivePhase(JourneyPhase phase) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      activePhase: phase,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(journeyRepositoryProvider).saveJourneyState(updated);
  }

  Future<void> toggleActivityCompleted(String activityId, {bool? forceCompleted}) async {
    final current = state.value;
    if (current == null) return;

    final updatedActivities = current.activities.map((act) {
      if (act.id == activityId) {
        final nextStatus = forceCompleted ?? !act.isCompleted;
        return act.copyWith(
          isCompleted: nextStatus,
          completedAt: nextStatus ? DateTime.now() : null,
        );
      }
      return act;
    }).toList();

    final updated = current.copyWith(
      activities: updatedActivities,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(journeyRepositoryProvider).saveJourneyState(updated);
  }

  Future<void> saveActivityReflection({
    required String activityId,
    String? personalNotes,
    Map<String, String>? reflectionAnswers,
    bool markCompleted = true,
  }) async {
    final current = state.value;
    if (current == null) return;

    final updatedActivities = current.activities.map((act) {
      if (act.id == activityId) {
        return act.copyWith(
          personalNotes: personalNotes ?? act.personalNotes,
          reflectionAnswers: reflectionAnswers ?? act.reflectionAnswers,
          isCompleted: markCompleted ? true : act.isCompleted,
          completedAt: markCompleted ? (act.completedAt ?? DateTime.now()) : act.completedAt,
        );
      }
      return act;
    }).toList();

    final updated = current.copyWith(
      activities: updatedActivities,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(journeyRepositoryProvider).saveJourneyState(updated);
  }

  Future<void> addCustomDiscovery({
    required String title,
    required String notes,
    String? category,
  }) async {
    if (state.value == null) {
      await future;
    }
    final current = state.value;
    if (current == null) return;

    final now = DateTime.now();
    final newActivity = JourneyActivity(
      id: 'disc_${now.millisecondsSinceEpoch}',
      phase: current.activePhase,
      title: title.trim(),
      purpose: category ?? 'Personal Discovery',
      shortExplanation: category != null ? 'Category: $category' : 'User reflection note',
      guidedInstructions: const [],
      reflectionQuestions: const [],
      isCompleted: true,
      completedAt: now,
      personalNotes: notes.trim(),
    );

    final updated = current.copyWith(
      activities: [newActivity, ...current.activities],
      updatedAt: now,
    );

    state = AsyncValue.data(updated);
    await ref.read(journeyRepositoryProvider).saveJourneyState(updated);
  }

  Future<void> deleteDiscovery(String activityId) async {
    if (state.value == null) {
      await future;
    }
    final current = state.value;
    if (current == null) return;

    final updatedActivities =
        current.activities.where((a) => a.id != activityId).toList();

    final updated = current.copyWith(
      activities: updatedActivities,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await ref.read(journeyRepositoryProvider).saveJourneyState(updated);
  }

  Future<void> resetJourney() async {
    await ref.read(journeyRepositoryProvider).resetJourneyProgress();
    final fresh = await ref.read(journeyRepositoryProvider).getJourneyState();
    state = AsyncValue.data(fresh);
  }
}

final journeyControllerProvider =
    AsyncNotifierProvider<JourneyNotifier, JourneyStateModel>(
  JourneyNotifier.new,
);
