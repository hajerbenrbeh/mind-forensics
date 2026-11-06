import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/locale_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../journey/controllers/journey_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../data/local_mind_trace_repository.dart';
import '../data/mind_trace_ai_service.dart';
import '../domain/mind_trace_model.dart';
import '../domain/trace_milestone.dart';

final mindTraceRepositoryProvider = Provider<MindTraceRepository>((ref) {
  final authUser = ref.watch(authControllerProvider).user;
  return LocalMindTraceRepository(userId: authUser?.id);
});

final mindTraceAiServiceProvider = Provider<MindTraceAiService>((ref) {
  final aiConfig = ref.watch(aiConfigProvider);
  return MindTraceAiService(
    apiKey: aiConfig.apiKey,
  );
});

class MindTraceNotifier extends AsyncNotifier<List<MindTraceModel>> {
  @override
  Future<List<MindTraceModel>> build() async {
    final repo = ref.watch(mindTraceRepositoryProvider);
    return repo.getAllTraces();
  }

  Future<void> recordCheckIn(
    MindTraceModel trace, {
    bool generateAi = true,
  }) async {
    final repo = ref.read(mindTraceRepositoryProvider);
    var toSave = trace;

    // Optional: generate AI reflection if enabled and not already provided
    if (generateAi && (toSave.aiReflection == null || toSave.aiReflection!.isEmpty)) {
      final aiService = ref.read(mindTraceAiServiceProvider);
      final profile = ref.read(profileControllerProvider).value;
      final locale = ref.read(localeControllerProvider);
      final journeyState = ref.read(journeyControllerProvider).value;

      final currentList = state.value ?? [];
      final reflection = await aiService.generateDailyReflection(
        currentTrace: toSave,
        history: currentList,
        profile: profile,
        languageCode: locale.languageCode,
        availableActivities: journeyState?.activities,
      );

      toSave = toSave.copyWith(
        aiReflection: reflection,
        updatedAt: DateTime.now(),
      );
    }

    await repo.saveTrace(toSave);
    final fresh = await repo.getAllTraces();
    state = AsyncValue.data(fresh);
  }

  Future<void> updateCheckIn(MindTraceModel trace) async {
    final repo = ref.read(mindTraceRepositoryProvider);
    await repo.saveTrace(trace.copyWith(updatedAt: DateTime.now()));
    final fresh = await repo.getAllTraces();
    state = AsyncValue.data(fresh);
  }

  Future<void> deleteCheckIn(String id) async {
    final repo = ref.read(mindTraceRepositoryProvider);
    await repo.deleteTrace(id);
    final fresh = await repo.getAllTraces();
    state = AsyncValue.data(fresh);
  }

  Future<void> clearAllTraces() async {
    final repo = ref.read(mindTraceRepositoryProvider);
    await repo.clearAllTraces();
    state = const AsyncValue.data([]);
  }
}

final mindTraceControllerProvider =
    AsyncNotifierProvider<MindTraceNotifier, List<MindTraceModel>>(
  MindTraceNotifier.new,
);

/// Computed provider for today's active trace (if recorded)
final todayTraceProvider = Provider<MindTraceModel?>((ref) {
  final traces = ref.watch(mindTraceControllerProvider).value ?? [];
  if (traces.isEmpty) return null;

  final now = DateTime.now();
  final todayKey =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  for (final t in traces) {
    if (t.dateKey == todayKey) return t;
  }
  return null;
});

/// Computed provider for unlocked milestones
final unlockedMilestonesProvider = Provider<List<TraceMilestone>>((ref) {
  final traces = ref.watch(mindTraceControllerProvider).value ?? [];
  final reflectionsCount = traces
      .where((t) => t.journalText != null && t.journalText!.trim().isNotEmpty)
      .length;

  return TraceMilestone.allMilestones
      .where((m) => m.isUnlocked(traces.length, reflectionsCount))
      .toList();
});
