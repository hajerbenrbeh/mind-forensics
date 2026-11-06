import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/local_journey_repository.dart';
import '../domain/journey_phase.dart';
import '../domain/journey_state_model.dart';

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  final authUser = ref.watch(authControllerProvider).user;
  return LocalJourneyRepository(userId: authUser?.id);
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
