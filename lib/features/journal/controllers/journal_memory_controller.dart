import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/security/secure_key_manager.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/case_model.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../data/journal_memory_compression_service.dart';
import '../data/local_journal_memory_repository.dart';
import '../domain/journal_memory_model.dart';

final journalMemoryRepositoryProvider = Provider<JournalMemoryRepository>((ref) {
  final authUser = ref.watch(authControllerProvider).user;
  final keyManager = ref.watch(secureKeyManagerProvider);
  return LocalJournalMemoryRepository(
    userId: authUser?.id,
    keyManager: keyManager,
  );
});

final journalMemoryCompressionServiceProvider = Provider<JournalMemoryCompressionService>((ref) {
  return const JournalMemoryCompressionService();
});

class JournalMemoryNotifier extends AsyncNotifier<List<JournalMemoryModel>> {
  @override
  Future<List<JournalMemoryModel>> build() async {
    final repo = ref.watch(journalMemoryRepositoryProvider);
    return repo.getAllMemories();
  }

  /// Recomputes and updates compressed memories from the latest traces and cases.
  Future<List<JournalMemoryModel>> recalculateMemories({
    List<MindTraceModel>? traces,
    List<CaseModel>? cases,
  }) async {
    final repo = ref.read(journalMemoryRepositoryProvider);
    final compression = ref.read(journalMemoryCompressionServiceProvider);
    final authUser = ref.read(authControllerProvider).user;

    final effectiveTraces = traces ?? (ref.read(mindTraceControllerProvider).value ?? []);
    final effectiveCases = cases ?? (await ref.read(caseRepositoryProvider).getAllCases());
    final currentMemories = state.value ?? await repo.getAllMemories();
    final suppressedKeys = await repo.getSuppressedKeys();

    final compressed = compression.compress(
      traces: effectiveTraces,
      cases: effectiveCases,
      existingMemories: currentMemories,
      userId: authUser?.id ?? 'local_user',
      suppressedKeys: suppressedKeys,
    );

    await repo.saveAllMemories(compressed);
    if (!ref.mounted) return compressed;
    state = AsyncValue.data(compressed);
    return compressed;
  }

  /// Prunes or updates memories after an entry is deleted.
  Future<void> handleEntryDeleted(String entryId) async {
    final repo = ref.read(journalMemoryRepositoryProvider);
    final compression = ref.read(journalMemoryCompressionServiceProvider);
    final current = state.value ?? await repo.getAllMemories();

    final pruned = compression.pruneAfterDeletion(
      deletedEntryId: entryId,
      existingMemories: current,
    );

    await repo.saveAllMemories(pruned);
    if (!ref.mounted) return;
    state = AsyncValue.data(pruned);
  }

  /// Marks a memory as affirmed and confirmed by the user.
  Future<void> confirmMemory(String id) async {
    final repo = ref.read(journalMemoryRepositoryProvider);
    final current = state.value ?? [];
    final updated = current.map((m) {
      if (m.id == id) {
        return m.copyWith(
          confirmationStatus: MemoryConfirmationStatus.confirmed,
          updatedAt: DateTime.now(),
        );
      }
      return m;
    }).toList();

    await repo.saveAllMemories(updated);
    if (!ref.mounted) return;
    state = AsyncValue.data(updated);
  }

  /// Marks a memory as rejected by the user.
  /// Rejected memories are permanently suppressed from AI Companion context.
  Future<void> rejectMemory(String id) async {
    final repo = ref.read(journalMemoryRepositoryProvider);
    final current = state.value ?? [];
    final updated = current.map((m) {
      if (m.id == id) {
        return m.copyWith(
          confirmationStatus: MemoryConfirmationStatus.rejected,
          updatedAt: DateTime.now(),
        );
      }
      return m;
    }).toList();

    await repo.saveAllMemories(updated);
    if (!ref.mounted) return;
    state = AsyncValue.data(updated);
  }

  /// Permanently removes a memory from local sovereign storage and suppresses its key
  /// so it cannot be automatically recreated on future recalculation passes.
  Future<void> deleteMemory(String id) async {
    final repo = ref.read(journalMemoryRepositoryProvider);
    final current = state.value ?? await repo.getAllMemories();
    final toDelete = current.where((m) => m.id == id).firstOrNull;
    if (toDelete != null) {
      final key = JournalMemoryCompressionService.generateDedupKey(
        toDelete.category,
        toDelete.summary,
      );
      await repo.suppressKey(key);
    }
    await repo.deleteMemory(id);
    if (!ref.mounted) return;
    final updated = current.where((m) => m.id != id).toList();
    state = AsyncValue.data(updated);
  }

  /// Clears all stored memories and any persisted suppression keys.
  Future<void> clearAll() async {
    final repo = ref.read(journalMemoryRepositoryProvider);
    await repo.clearAllMemories();
    await repo.clearSuppressedKeys();
    if (!ref.mounted) return;
    state = const AsyncValue.data([]);
  }
}

final journalMemoryControllerProvider =
    AsyncNotifierProvider<JournalMemoryNotifier, List<JournalMemoryModel>>(
  JournalMemoryNotifier.new,
);
