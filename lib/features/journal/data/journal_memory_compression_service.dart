import 'package:uuid/uuid.dart';
import '../../investigation/domain/case_model.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../domain/journal_memory_model.dart';

/// Deterministic, on-device engine for compressing journal entries and forensic cases
/// into long-term psychological context and recurring themes.
///
/// Principles (Step 3.2):
/// 1. 100% Offline & Deterministic: Never calls external LLMs to summarize raw notes.
/// 2. Empirical Grounding: Every memory item links directly to its source entries via namespaced IDs (`trace:<id>`, `case:<id>`).
/// 3. Non-Diagnostic Guardrails: Expresses themes as self-reported patterns, never clinical diagnoses.
/// 4. User Sovereignty: Preserves confirmation and rejection statuses across recalculations.
/// 5. Persistent Suppression: Deleting a memory persistently suppresses its deduplication key from automatic recreation.
class JournalMemoryCompressionService {
  const JournalMemoryCompressionService();

  /// Matches a stored source ID against a target deleted ID, handling both
  /// raw and namespaced (`trace:<id>`, `case:<id>`) variants safely.
  static bool matchesSourceId(String storedSourceId, String targetId) {
    if (storedSourceId == targetId) return true;
    if (storedSourceId == 'trace:$targetId' || storedSourceId == 'case:$targetId') return true;
    if (targetId == 'trace:$storedSourceId' || targetId == 'case:$storedSourceId') return true;
    return false;
  }

  /// Compresses a collection of [MindTraceModel] and [CaseModel] entries into a
  /// compact, privacy-safe set of memories, reconciling with any existing memories.
  List<JournalMemoryModel> compress({
    required List<MindTraceModel> traces,
    List<CaseModel> cases = const [],
    List<JournalMemoryModel> existingMemories = const [],
    String userId = 'local_user',
    Set<String> suppressedKeys = const {},
  }) {
    if (traces.isEmpty && cases.isEmpty) {
      return [];
    }

    final memories = <JournalMemoryModel>[];
    final existingByKey = <String, JournalMemoryModel>{};
    for (final em in existingMemories) {
      existingByKey[generateDedupKey(em.category, em.summary)] = em;
    }

    // -------------------------------------------------------------------------
    // 1. User-Stated Context (Explicit situations, goals, and case conclusions)
    // -------------------------------------------------------------------------
    _extractUserStatedContext(
      traces: traces,
      cases: cases,
      memories: memories,
      existingByKey: existingByKey,
      userId: userId,
      suppressedKeys: suppressedKeys,
    );

    // -------------------------------------------------------------------------
    // 2. Recurring Themes (Topics appearing across >= 2 distinct dates)
    // -------------------------------------------------------------------------
    _extractRecurringThemes(
      traces: traces,
      cases: cases,
      memories: memories,
      existingByKey: existingByKey,
      userId: userId,
      suppressedKeys: suppressedKeys,
    );

    // -------------------------------------------------------------------------
    // 3. Emotional Context (Repeated self-reported feelings in user's own words)
    // -------------------------------------------------------------------------
    _extractEmotionalContext(
      traces: traces,
      memories: memories,
      existingByKey: existingByKey,
      userId: userId,
      suppressedKeys: suppressedKeys,
    );

    // -------------------------------------------------------------------------
    // 4. Coping Strategies & Helpful Experiences
    // -------------------------------------------------------------------------
    _extractCopingExperiences(
      traces: traces,
      cases: cases,
      memories: memories,
      existingByKey: existingByKey,
      userId: userId,
      suppressedKeys: suppressedKeys,
    );

    // -------------------------------------------------------------------------
    // 5. Tentative Observations (Empirical co-occurrences framed as hypotheses)
    // -------------------------------------------------------------------------
    _extractTentativeObservations(
      traces: traces,
      memories: memories,
      existingByKey: existingByKey,
      userId: userId,
      suppressedKeys: suppressedKeys,
    );

    // Sort: Confirmed first, then highest observation count, newest last-observed date
    memories.sort((a, b) {
      if (a.isConfirmed && !b.isConfirmed) return -1;
      if (!a.isConfirmed && b.isConfirmed) return 1;
      if (a.observationCount != b.observationCount) {
        return b.observationCount.compareTo(a.observationCount);
      }
      return b.lastObservedDate.compareTo(a.lastObservedDate);
    });

    return memories;
  }

  /// Invalidate and update existing memories after a source entry has been deleted.
  List<JournalMemoryModel> pruneAfterDeletion({
    required String deletedEntryId,
    required List<JournalMemoryModel> existingMemories,
  }) {
    final updated = <JournalMemoryModel>[];

    for (final memory in existingMemories) {
      final hasDeletedSource = memory.sourceEntryIds.any((id) => matchesSourceId(id, deletedEntryId));
      if (!hasDeletedSource) {
        updated.add(memory);
        continue;
      }

      final remainingSources = memory.sourceEntryIds
          .where((id) => !matchesSourceId(id, deletedEntryId))
          .toList();

      // If all source entries are gone, prune this memory completely
      if (remainingSources.isEmpty) {
        continue;
      }

      // If a recurring theme drops to only 1 source, demote or prune
      if (memory.category == JournalMemoryCategory.recurringTheme && remainingSources.length < 2) {
        // Demoted or pruned to preserve recurring semantics
        continue;
      }

      updated.add(
        memory.copyWith(
          sourceEntryIds: remainingSources,
          observationCount: remainingSources.length,
          updatedAt: DateTime.now(),
        ),
      );
    }

    return updated;
  }

  // ===========================================================================
  // PRIVATE EXTRACTION PASSES
  // ===========================================================================

  void _extractUserStatedContext({
    required List<MindTraceModel> traces,
    required List<CaseModel> cases,
    required List<JournalMemoryModel> memories,
    required Map<String, JournalMemoryModel> existingByKey,
    required String userId,
    required Set<String> suppressedKeys,
  }) {
    // A. Completed case conclusions (user's explicit self-directed takeaways)
    for (final c in cases) {
      if (c.userConclusion != null && c.userConclusion!.trim().isNotEmpty) {
        final conclusion = c.userConclusion!.trim();
        final summary = 'User conclusion from "${c.title}": "$conclusion"';
        _addOrMergeMemory(
          category: JournalMemoryCategory.userStatedContext,
          summary: summary,
          sourceId: 'case:${c.id}',
          observedDate: c.updatedAt,
          evidenceStatus: MemoryEvidenceStatus.userExplicit,
          memories: memories,
          existingByKey: existingByKey,
          userId: userId,
          suppressedKeys: suppressedKeys,
        );
      }
    }

    // B. Explicit situations described by user in check-ins
    final situationGroups = <String, List<MindTraceModel>>{};
    for (final t in traces) {
      final s = t.situation?.trim();
      if (s != null && s.isNotEmpty && s.length >= 5) {
        final key = normalizeText(s);
        situationGroups.putIfAbsent(key, () => []).add(t);
      }
    }

    // Keep single notable situations as user-stated context
    for (final entry in situationGroups.entries) {
      if (entry.value.length == 1) {
        final trace = entry.value.first;
        final summary = 'Logged situation context: "${trace.situation!.trim()}"';
        _addOrMergeMemory(
          category: JournalMemoryCategory.userStatedContext,
          summary: summary,
          sourceId: 'trace:${trace.id}',
          observedDate: trace.date,
          evidenceStatus: MemoryEvidenceStatus.userExplicit,
          memories: memories,
          existingByKey: existingByKey,
          userId: userId,
          suppressedKeys: suppressedKeys,
        );
      }
    }
  }

  void _extractRecurringThemes({
    required List<MindTraceModel> traces,
    required List<CaseModel> cases,
    required List<JournalMemoryModel> memories,
    required Map<String, JournalMemoryModel> existingByKey,
    required String userId,
    required Set<String> suppressedKeys,
  }) {
    // 1. Group repeated situations/triggers across distinct dates
    final themeMap = <String, List<({String id, DateTime date, String text})>>{};

    for (final t in traces) {
      final sit = t.situation?.trim();
      if (sit != null && sit.length >= 4) {
        final norm = normalizeText(sit);
        themeMap.putIfAbsent(norm, () => []).add((id: 'trace:${t.id}', date: t.date, text: sit));
      }
    }

    for (final c in cases) {
      final trig = c.chain?.trigger.trim() ?? '';
      if (trig.length >= 4) {
        final norm = normalizeText(trig);
        themeMap.putIfAbsent(norm, () => []).add((id: 'case:${c.id}', date: c.createdAt, text: trig));
      }
    }

    for (final entry in themeMap.entries) {
      final occurrences = entry.value;
      // Strict rule: MUST span at least 2 distinct calendar days to be classified as recurring
      final distinctDates = occurrences.map((o) => '${o.date.year}-${o.date.month}-${o.date.day}').toSet();
      if (distinctDates.length >= 2) {
        final sampleText = occurrences.first.text;
        final sourceIds = occurrences.map((o) => o.id).toSet().toList();
        final firstDate = occurrences.map((o) => o.date).reduce((a, b) => a.isBefore(b) ? a : b);
        final lastDate = occurrences.map((o) => o.date).reduce((a, b) => a.isAfter(b) ? a : b);

        final summary = 'Recurring topic reported across ${distinctDates.length} entries: "$sampleText"';
        _createOrUpdateAggregatedMemory(
          category: JournalMemoryCategory.recurringTheme,
          summary: summary,
          sourceIds: sourceIds,
          firstDate: firstDate,
          lastDate: lastDate,
          observationCount: distinctDates.length,
          evidenceStatus: MemoryEvidenceStatus.recurringReported,
          memories: memories,
          existingByKey: existingByKey,
          userId: userId,
          suppressedKeys: suppressedKeys,
        );
      }
    }
  }

  void _extractEmotionalContext({
    required List<MindTraceModel> traces,
    required List<JournalMemoryModel> memories,
    required Map<String, JournalMemoryModel> existingByKey,
    required String userId,
    required Set<String> suppressedKeys,
  }) {
    final emotionMap = <String, List<({String id, DateTime date})>>{};

    for (final t in traces) {
      for (final emotion in t.selectedEmotions) {
        final trimmed = emotion.trim().toLowerCase();
        if (trimmed.isNotEmpty) {
          emotionMap.putIfAbsent(trimmed, () => []).add((id: 'trace:${t.id}', date: t.date));
        }
      }
    }

    for (final entry in emotionMap.entries) {
      final occurrences = entry.value;
      final distinctDates = occurrences.map((o) => '${o.date.year}-${o.date.month}-${o.date.day}').toSet();

      // Only emotional experiences reported across >= 2 distinct days are synthesized
      if (distinctDates.length >= 2) {
        final emotionName = entry.key;
        final sourceIds = occurrences.map((o) => o.id).toSet().toList();
        final firstDate = occurrences.map((o) => o.date).reduce((a, b) => a.isBefore(b) ? a : b);
        final lastDate = occurrences.map((o) => o.date).reduce((a, b) => a.isAfter(b) ? a : b);

        final summary = 'Self-reported feeling "$emotionName" across ${distinctDates.length} recorded check-ins';
        _createOrUpdateAggregatedMemory(
          category: JournalMemoryCategory.emotionalContext,
          summary: summary,
          sourceIds: sourceIds,
          firstDate: firstDate,
          lastDate: lastDate,
          observationCount: distinctDates.length,
          evidenceStatus: MemoryEvidenceStatus.recurringReported,
          memories: memories,
          existingByKey: existingByKey,
          userId: userId,
          suppressedKeys: suppressedKeys,
        );
      }
    }
  }

  void _extractCopingExperiences({
    required List<MindTraceModel> traces,
    required List<CaseModel> cases,
    required List<JournalMemoryModel> memories,
    required Map<String, JournalMemoryModel> existingByKey,
    required String userId,
    required Set<String> suppressedKeys,
  }) {
    for (final t in traces) {
      final resp = t.behavioralResponse?.trim();
      if (resp != null && resp.isNotEmpty && resp.length >= 4) {
        final summary = 'Self-reported coping response: "$resp"';
        _addOrMergeMemory(
          category: JournalMemoryCategory.copingExperience,
          summary: summary,
          sourceId: 'trace:${t.id}',
          observedDate: t.date,
          evidenceStatus: MemoryEvidenceStatus.userExplicit,
          memories: memories,
          existingByKey: existingByKey,
          userId: userId,
          suppressedKeys: suppressedKeys,
        );
      }
    }

    for (final c in cases) {
      final beh = c.chain?.behavior.trim();
      if (beh != null && beh.isNotEmpty && beh.length >= 4) {
        final summary = 'Observed behavioral reaction in situation: "$beh"';
        _addOrMergeMemory(
          category: JournalMemoryCategory.copingExperience,
          summary: summary,
          sourceId: 'case:${c.id}',
          observedDate: c.createdAt,
          evidenceStatus: MemoryEvidenceStatus.userExplicit,
          memories: memories,
          existingByKey: existingByKey,
          userId: userId,
          suppressedKeys: suppressedKeys,
        );
      }
    }
  }

  void _extractTentativeObservations({
    required List<MindTraceModel> traces,
    required List<JournalMemoryModel> memories,
    required Map<String, JournalMemoryModel> existingByKey,
    required String userId,
    required Set<String> suppressedKeys,
  }) {
    // Non-causal correlational hypothesis: co-occurrence of sleep <= 5.5h with high physical tension >= 7
    final shortSleepHighTension = traces.where((t) {
      final sleep = t.sleepHours;
      final tension = t.physicalTension;
      return sleep != null && sleep <= 5.5 && tension != null && tension >= 7;
    }).toList();

    if (shortSleepHighTension.length >= 2) {
      final sourceIds = shortSleepHighTension.map((t) => 'trace:${t.id}').toList();
      final firstDate = shortSleepHighTension.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
      final lastDate = shortSleepHighTension.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b);

      const summary = 'Potential observation: Lower sleep duration co-occurred with elevated physical tension across multiple entries. Framed as a tentative reflection, not a causal rule.';
      _createOrUpdateAggregatedMemory(
        category: JournalMemoryCategory.tentativeObservation,
        summary: summary,
        sourceIds: sourceIds,
        firstDate: firstDate,
        lastDate: lastDate,
        observationCount: shortSleepHighTension.length,
        evidenceStatus: MemoryEvidenceStatus.tentativeHypothesis,
        memories: memories,
        existingByKey: existingByKey,
        userId: userId,
        suppressedKeys: suppressedKeys,
      );
    }
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  void _addOrMergeMemory({
    required JournalMemoryCategory category,
    required String summary,
    required String sourceId,
    required DateTime observedDate,
    required MemoryEvidenceStatus evidenceStatus,
    required List<JournalMemoryModel> memories,
    required Map<String, JournalMemoryModel> existingByKey,
    required String userId,
    required Set<String> suppressedKeys,
  }) {
    final key = generateDedupKey(category, summary);
    if (suppressedKeys.contains(key)) {
      return;
    }
    final existing = existingByKey[key];

    if (existing != null) {
      final updatedSources = existing.sourceEntryIds.any((s) => matchesSourceId(s, sourceId))
          ? existing.sourceEntryIds
          : [...existing.sourceEntryIds, sourceId];
      final firstDate = existing.firstObservedDate.isBefore(observedDate)
          ? existing.firstObservedDate
          : observedDate;
      final lastDate = existing.lastObservedDate.isAfter(observedDate)
          ? existing.lastObservedDate
          : observedDate;

      memories.add(
        existing.copyWith(
          sourceEntryIds: updatedSources,
          observationCount: updatedSources.length,
          firstObservedDate: firstDate,
          lastObservedDate: lastDate,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      memories.add(
        JournalMemoryModel(
          id: const Uuid().v4(),
          userId: userId,
          category: category,
          summary: summary,
          sourceEntryIds: [sourceId],
          observationCount: 1,
          evidenceStatus: evidenceStatus,
          confirmationStatus: MemoryConfirmationStatus.unreviewed,
          firstObservedDate: observedDate,
          lastObservedDate: observedDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  void _createOrUpdateAggregatedMemory({
    required JournalMemoryCategory category,
    required String summary,
    required List<String> sourceIds,
    required DateTime firstDate,
    required DateTime lastDate,
    required int observationCount,
    required MemoryEvidenceStatus evidenceStatus,
    required List<JournalMemoryModel> memories,
    required Map<String, JournalMemoryModel> existingByKey,
    required String userId,
    required Set<String> suppressedKeys,
  }) {
    final key = generateDedupKey(category, summary);
    if (suppressedKeys.contains(key)) {
      return;
    }
    final existing = existingByKey[key];

    if (existing != null) {
      // Preserve user confirmation status (confirmed or rejected)
      memories.add(
        existing.copyWith(
          sourceEntryIds: sourceIds,
          observationCount: observationCount,
          firstObservedDate: firstDate,
          lastObservedDate: lastDate,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      memories.add(
        JournalMemoryModel(
          id: const Uuid().v4(),
          userId: userId,
          category: category,
          summary: summary,
          sourceEntryIds: sourceIds,
          observationCount: observationCount,
          evidenceStatus: evidenceStatus,
          confirmationStatus: MemoryConfirmationStatus.unreviewed,
          firstObservedDate: firstDate,
          lastObservedDate: lastDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  static String generateDedupKey(JournalMemoryCategory category, String summary) {
    return '${category.name}:${normalizeText(summary)}';
  }

  static String normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
