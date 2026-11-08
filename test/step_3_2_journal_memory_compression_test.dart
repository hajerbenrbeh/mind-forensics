import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/investigation/domain/ai_companion_context_selector.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/journal/controllers/journal_memory_controller.dart';
import 'package:mind_forensics/features/journal/data/journal_memory_compression_service.dart';
import 'package:mind_forensics/features/journal/data/local_journal_memory_repository.dart';
import 'package:mind_forensics/features/journal/domain/journal_memory_model.dart';
import 'package:mind_forensics/features/journal/presentation/widgets/journal_memory_sheet.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Step 3.2: Journal Memory Compression Engine Tests', () {
    const service = JournalMemoryCompressionService();

    test('1. Empty journal history produces zero compressed memories without errors', () {
      final memories = service.compress(traces: [], cases: []);
      expect(memories, isEmpty);
    });

    test('2. Single-entry information is classified as userStatedContext, NEVER as recurringTheme', () {
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 'trace_single',
          date: now,
          createdAt: now,
          updatedAt: now,
          situation: 'Sudden tight deadline at work today',
          overallMood: 'anxious',
          moodIntensity: 7,
        ),
      ];

      final memories = service.compress(traces: traces);
      expect(memories, isNotEmpty);

      // Must be user-stated context with exactly 1 observation
      final item = memories.first;
      expect(item.category, equals(JournalMemoryCategory.userStatedContext));
      expect(item.observationCount, equals(1));
      expect(item.evidenceStatus, equals(MemoryEvidenceStatus.userExplicit));
      expect(item.summary, contains('Sudden tight deadline at work today'));

      // Strict requirement: zero recurring themes generated from a single event
      expect(
        memories.any((m) => m.category == JournalMemoryCategory.recurringTheme),
        isFalse,
      );
    });

    test('3. Repeated themes across >= 2 distinct dates are synthesized into recurringTheme', () {
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 't1',
          date: now,
          createdAt: now,
          updatedAt: now,
          situation: 'Work project deadline pressure',
          overallMood: 'anxious',
          moodIntensity: 7,
        ),
        MindTraceModel(
          id: 't2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          situation: 'Work project deadline pressure',
          overallMood: 'overwhelmed',
          moodIntensity: 8,
        ),
        MindTraceModel(
          id: 't3',
          date: now.subtract(const Duration(days: 3)),
          createdAt: now,
          updatedAt: now,
          situation: 'Work project deadline pressure',
          overallMood: 'tired',
          moodIntensity: 6,
        ),
      ];

      final memories = service.compress(traces: traces);
      final recurring = memories.where((m) => m.category == JournalMemoryCategory.recurringTheme).toList();

      expect(recurring, isNotEmpty);
      final theme = recurring.first;
      expect(theme.observationCount, equals(3));
      expect(theme.sourceEntryIds, containsAll(['trace:t1', 'trace:t2', 'trace:t3']));
      expect(theme.evidenceStatus, equals(MemoryEvidenceStatus.recurringReported));
      expect(theme.summary, contains('Recurring topic reported across 3 entries'));
      expect(theme.summary, contains('Work project deadline pressure'));
    });

    test('4. Accurate source-entry references link every memory to its origin entries', () {
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 'trace_alpha',
          date: now,
          createdAt: now,
          updatedAt: now,
          selectedEmotions: ['frustrated'],
          moodIntensity: 6,
        ),
        MindTraceModel(
          id: 'trace_beta',
          date: now.subtract(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
          selectedEmotions: ['frustrated'],
          moodIntensity: 7,
        ),
      ];

      final memories = service.compress(traces: traces);
      final emotionMemories = memories.where((m) => m.category == JournalMemoryCategory.emotionalContext).toList();

      expect(emotionMemories, isNotEmpty);
      final emotionMemory = emotionMemories.first;
      expect(emotionMemory.sourceEntryIds, equals(['trace:trace_alpha', 'trace:trace_beta']));
      expect(emotionMemory.observationCount, equals(2));
      expect(emotionMemory.summary, contains('feeling "frustrated" across 2 recorded check-ins'));
    });

    test('5. Duplicate prevention: similar normalized themes update existing memory rather than duplicating', () {
      final now = DateTime.now();
      final tracesDay1 = [
        MindTraceModel(
          id: 't1',
          date: now.subtract(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
          situation: 'Difficulty sleeping due to racing thoughts',
          overallMood: 'restless',
        ),
        MindTraceModel(
          id: 't2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          situation: 'Difficulty sleeping due to racing thoughts',
          overallMood: 'tired',
        ),
      ];

      final initialMemories = service.compress(traces: tracesDay1);
      expect(initialMemories.where((m) => m.category == JournalMemoryCategory.recurringTheme).length, equals(1));

      // Day 3 check-in with the exact same recurring theme
      final tracesDay3 = [
        ...tracesDay1,
        MindTraceModel(
          id: 't3',
          date: now,
          createdAt: now,
          updatedAt: now,
          situation: 'Difficulty sleeping due to racing thoughts',
          overallMood: 'exhausted',
        ),
      ];

      final updatedMemories = service.compress(
        traces: tracesDay3,
        existingMemories: initialMemories,
      );

      final recurring = updatedMemories.where((m) => m.category == JournalMemoryCategory.recurringTheme).toList();
      // Must not create duplicate items
      expect(recurring.length, equals(1));
      expect(recurring.first.observationCount, equals(3));
      expect(recurring.first.sourceEntryIds, containsAll(['trace:t1', 'trace:t2', 'trace:t3']));
    });

    test('6. Coping experiences: behavioral responses are captured accurately', () {
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 't_cope',
          date: now,
          createdAt: now,
          updatedAt: now,
          behavioralResponse: 'Went for a 20-minute walk without phone',
          overallMood: 'calm',
        ),
      ];

      final memories = service.compress(traces: traces);
      final coping = memories.where((m) => m.category == JournalMemoryCategory.copingExperience).toList();

      expect(coping, isNotEmpty);
      expect(coping.first.summary, contains('Went for a 20-minute walk without phone'));
      expect(coping.first.sourceEntryIds, contains('trace:t_cope'));
    });

    test('7. Completed case conclusions are captured as explicit userStatedContext', () {
      final now = DateTime.now();
      final cases = [
        CaseModel(
          id: 'case_101',
          caseNumber: 'SESSION 01',
          title: 'Work Email Reaction',
          createdAt: now,
          updatedAt: now,
          currentStage: CaseStage.conclusion,
          incidentDescription: 'Received short email from boss',
          userConclusion: 'A short reply is about their busy day, not my performance.',
          isCompleted: true,
        ),
      ];

      final memories = service.compress(traces: [], cases: cases);
      final caseMemories = memories.where((m) => m.category == JournalMemoryCategory.userStatedContext).toList();

      expect(caseMemories, isNotEmpty);
      expect(caseMemories.first.summary, contains('A short reply is about their busy day, not my performance.'));
      expect(caseMemories.first.sourceEntryIds, contains('case:case_101'));
    });

    test('8. Preservation of uncertainty: tentative observations are explicitly marked as hypotheses', () {
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 'short_1',
          date: now,
          createdAt: now,
          updatedAt: now,
          sleepHours: 4.5,
          physicalTension: 8,
        ),
        MindTraceModel(
          id: 'short_2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 5.0,
          physicalTension: 9,
        ),
      ];

      final memories = service.compress(traces: traces);
      final tentative = memories.where((m) => m.category == JournalMemoryCategory.tentativeObservation).toList();

      expect(tentative, isNotEmpty);
      final obs = tentative.first;
      expect(obs.evidenceStatus, equals(MemoryEvidenceStatus.tentativeHypothesis));
      expect(obs.summary, contains('Potential observation: Lower sleep duration co-occurred with elevated physical tension'));
      expect(obs.summary, contains('Framed as a tentative reflection, not a causal rule.'));
      // Must not diagnose or make certainty claims
      expect(obs.summary, isNot(contains('proves')));
      expect(obs.summary, isNot(contains('insomnia')));
    });

    test('9. Memory updates after journal edits preserve user confirmation status', () {
      final now = DateTime.now();
      final traceInitial = MindTraceModel(
        id: 't_edit',
        date: now,
        createdAt: now,
        updatedAt: now,
        behavioralResponse: 'Called my sister to talk through feelings',
      );

      final initialMemories = service.compress(traces: [traceInitial]);
      expect(initialMemories, isNotEmpty);

      // User affirms/confirms this memory
      final confirmedMemory = initialMemories.first.copyWith(
        confirmationStatus: MemoryConfirmationStatus.confirmed,
      );

      // Re-compression with confirmed memory must keep user confirmation intact
      final recompressed = service.compress(
        traces: [traceInitial],
        existingMemories: [confirmedMemory],
      );

      expect(recompressed.first.isConfirmed, isTrue);
      expect(recompressed.first.confirmationStatus, equals(MemoryConfirmationStatus.confirmed));
    });

    test('10. Memory invalidation after journal deletion removes dependent memories', () {
      final now = DateTime.now();
      final initialMemory = JournalMemoryModel(
        id: 'mem_1',
        category: JournalMemoryCategory.userStatedContext,
        summary: 'User stated context from deleted entry',
        sourceEntryIds: ['trace_to_delete'],
        observationCount: 1,
        firstObservedDate: now,
        lastObservedDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final pruned = service.pruneAfterDeletion(
        deletedEntryId: 'trace_to_delete',
        existingMemories: [initialMemory],
      );

      // Since all sources are gone, memory must be completely pruned
      expect(pruned, isEmpty);
    });

    test('11. Recurring theme demotes or prunes when source count drops below 2 after entry deletion', () {
      final now = DateTime.now();
      final recurringMemory = JournalMemoryModel(
        id: 'rec_1',
        category: JournalMemoryCategory.recurringTheme,
        summary: 'Recurring topic reported across 2 entries: "Work pressure"',
        sourceEntryIds: ['entry_1', 'entry_2'],
        observationCount: 2,
        evidenceStatus: MemoryEvidenceStatus.recurringReported,
        firstObservedDate: now.subtract(const Duration(days: 1)),
        lastObservedDate: now,
        createdAt: now,
        updatedAt: now,
      );

      // Delete entry_1 -> remaining source is only 1 entry
      final pruned = service.pruneAfterDeletion(
        deletedEntryId: 'entry_1',
        existingMemories: [recurringMemory],
      );

      // Must be pruned because recurring requires >= 2 distinct sources
      expect(pruned, isEmpty);
    });
  });

  group('Step 3.2: AI Companion Context Selector Integration & Privacy Gates', () {
    test('12. Consent disabled strictly omits all compressed memories from AI context', () {
      final now = DateTime.now();
      final memories = [
        JournalMemoryModel(
          id: 'm1',
          category: JournalMemoryCategory.recurringTheme,
          summary: 'Recurring topic reported across 3 entries: "Sleep disruption"',
          sourceEntryIds: ['trace:t1', 'trace:t2', 'trace:t3'],
          observationCount: 3,
          confirmationStatus: MemoryConfirmationStatus.confirmed,
          firstObservedDate: now,
          lastObservedDate: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Consent disabled via shareWithAiCompanion = false
      final profileNoShare = PsychologicalProfileModel(
        preferredName: 'Nadia',
        shareWithAiCompanion: false,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      final contextNoShare = AiCompanionContextSelector.buildContext(
        profile: profileNoShare,
        latestTrace: null,
        historicalTraces: null,
        journey: null,
        compressedMemories: memories,
      );

      expect(contextNoShare, isEmpty);

      // Consent disabled via allowAiPersonalization = false
      final profileNoPers = PsychologicalProfileModel(
        preferredName: 'Nadia',
        shareWithAiCompanion: true,
        allowAiPersonalization: false,
        updatedAt: DateTime(2026, 1, 1),
      );

      final contextNoPers = AiCompanionContextSelector.buildContext(
        profile: profileNoPers,
        latestTrace: null,
        historicalTraces: null,
        journey: null,
        compressedMemories: memories,
      );

      expect(contextNoPers, isEmpty);

      // Missing/null profile strictly omits memories
      final contextNoProfile = AiCompanionContextSelector.buildContext(
        profile: null,
        latestTrace: null,
        historicalTraces: null,
        journey: null,
        compressedMemories: memories,
      );

      expect(contextNoProfile, isEmpty);
    });

    test('13. Strictly confirmed memories are included while unreviewed, rejected, and archived are excluded', () {
      final now = DateTime.now();
      final memories = [
        JournalMemoryModel(
          id: 'm_confirmed',
          category: JournalMemoryCategory.copingExperience,
          summary: 'Self-reported coping response: "Deep diaphragmatic breathing"',
          sourceEntryIds: ['trace:t1'],
          observationCount: 1,
          confirmationStatus: MemoryConfirmationStatus.confirmed,
          firstObservedDate: now,
          lastObservedDate: now,
          createdAt: now,
          updatedAt: now,
        ),
        JournalMemoryModel(
          id: 'm_unreviewed',
          category: JournalMemoryCategory.recurringTheme,
          summary: 'Recurring topic reported across 2 entries: "Managing work priorities"',
          sourceEntryIds: ['trace:t1', 'trace:t2'],
          observationCount: 2,
          confirmationStatus: MemoryConfirmationStatus.unreviewed,
          evidenceStatus: MemoryEvidenceStatus.recurringReported,
          firstObservedDate: now,
          lastObservedDate: now,
          createdAt: now,
          updatedAt: now,
        ),
        JournalMemoryModel(
          id: 'm_rejected',
          category: JournalMemoryCategory.userStatedContext,
          summary: 'User stated context: "Rejected item"',
          sourceEntryIds: ['case:c1'],
          observationCount: 1,
          confirmationStatus: MemoryConfirmationStatus.rejected,
          firstObservedDate: now,
          lastObservedDate: now,
          createdAt: now,
          updatedAt: now,
        ),
        JournalMemoryModel(
          id: 'm_archived',
          category: JournalMemoryCategory.copingExperience,
          summary: 'Archived coping experience',
          sourceEntryIds: ['trace:t3'],
          observationCount: 1,
          confirmationStatus: MemoryConfirmationStatus.confirmed,
          isArchived: true,
          firstObservedDate: now,
          lastObservedDate: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final profileWithConsent = PsychologicalProfileModel(
        preferredName: 'Sami',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      final context = AiCompanionContextSelector.buildContext(
        profile: profileWithConsent,
        latestTrace: null,
        historicalTraces: null,
        journey: null,
        compressedMemories: memories,
      );

      // 1. Confirmed memory is included
      expect(context, contains('COMPRESSED JOURNAL MEMORY (Self-Reported Themes & Context):'));
      expect(context, contains('• [User-Confirmed] Self-reported coping response: "Deep diaphragmatic breathing" (1 observations)'));

      // 2. Unreviewed memory is excluded
      expect(context, isNot(contains('Managing work priorities')));

      // 3. Rejected memory is excluded
      expect(context, isNot(contains('Rejected item')));

      // 4. Archived memory is excluded
      expect(context, isNot(contains('Archived coping experience')));
    });

    test('14. Prompt length defense: Context selector caps injected memories to at most 4 confirmed items', () {
      final now = DateTime.now();
      final manyMemories = List.generate(
        10,
        (i) => JournalMemoryModel(
          id: 'm_$i',
          category: JournalMemoryCategory.recurringTheme,
          summary: 'Theme number $i',
          sourceEntryIds: ['trace:t_$i'],
          observationCount: i + 1,
          confirmationStatus: MemoryConfirmationStatus.confirmed,
          firstObservedDate: now,
          lastObservedDate: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final profile = PsychologicalProfileModel(
        preferredName: 'Sami',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      final context = AiCompanionContextSelector.buildContext(
        profile: profile,
        latestTrace: null,
        historicalTraces: null,
        journey: null,
        compressedMemories: manyMemories,
      );

      // Should contain at most 4 items
      final lines = context.split('\n').where((l) => l.startsWith('• [User-Confirmed]')).toList();
      expect(lines.length, equals(4));
    });
  });

  group('Step 3.2: Sovereign Local Memory Repository & UI Widget Tests', () {
    test('16. LocalJournalMemoryRepository isolates storage by userId and supports CRUD', () async {
      final repoUserA = LocalJournalMemoryRepository(userId: 'user_alpha');
      final repoUserB = LocalJournalMemoryRepository(userId: 'user_beta');

      final now = DateTime.now();
      final memoryA = JournalMemoryModel(
        id: 'mem_a1',
        userId: 'user_alpha',
        category: JournalMemoryCategory.userStatedContext,
        summary: 'Alpha personal context',
        sourceEntryIds: ['s1'],
        firstObservedDate: now,
        lastObservedDate: now,
        createdAt: now,
        updatedAt: now,
      );

      await repoUserA.saveMemory(memoryA);

      final allA = await repoUserA.getAllMemories();
      expect(allA.length, equals(1));
      expect(allA.first.summary, equals('Alpha personal context'));

      // User B must have zero memories (sovereign local isolation)
      final allB = await repoUserB.getAllMemories();
      expect(allB, isEmpty);

      // Delete memory
      await repoUserA.deleteMemory('mem_a1');
      final afterDelete = await repoUserA.getAllMemories();
      expect(afterDelete, isEmpty);
    });

    testWidgets('17. JournalMemorySheet renders header, items, and supports Confirm/Dismiss actions', (tester) async {
      final now = DateTime.now();
      final mockMemory = JournalMemoryModel(
        id: 'mem_widget_1',
        category: JournalMemoryCategory.recurringTheme,
        summary: 'Work deadline pressure noted across entries',
        sourceEntryIds: ['t1', 't2'],
        observationCount: 2,
        firstObservedDate: now,
        lastObservedDate: now,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            journalMemoryControllerProvider.overrideWith(
              () => _TestJournalMemoryNotifier([mockMemory]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: JournalMemorySheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header and Card
      expect(find.text('MEMORY VAULT'), findsOneWidget);
      expect(find.text('Work deadline pressure noted across entries'), findsOneWidget);
      expect(find.text('RECURRING THEME'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
    });
  });

  group('Step 3.2 Regression Suite: Cross-domain Bulk Deletion, Persistent Suppression & Source Namespacing', () {
    test('18. Bulk deletion of Mind Traces removes trace memories while preserving Case conclusions', () async {
      const compression = JournalMemoryCompressionService();
      final now = DateTime.now();

      final traces = [
        MindTraceModel(
          id: 'tr_1',
          userId: 'u1',
          date: now.subtract(const Duration(days: 2)),
          overallMood: 'Stressed',
          moodIntensity: 8,
          situation: 'Work backlog accumulation',
          selectedEmotions: ['anxious'],
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        MindTraceModel(
          id: 'tr_2',
          userId: 'u1',
          date: now.subtract(const Duration(days: 1)),
          overallMood: 'Overwhelmed',
          moodIntensity: 8,
          situation: 'Work backlog accumulation',
          selectedEmotions: ['anxious'],
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final cases = [
        CaseModel(
          id: 'case_1',
          userId: 'u1',
          caseNumber: 'CASE-101',
          incidentDescription: 'Project deadline pressure',
          title: 'Project Deadline Investigation',
          currentStage: CaseStage.conclusion,
          isCompleted: true,
          userConclusion: 'I realize I overestimate the threat of missing internal deadlines',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Initial compression with both traces and cases
      final initialMemories = compression.compress(
        traces: traces,
        cases: cases,
        userId: 'u1',
      );

      expect(initialMemories.any((m) => m.sourceEntryIds.any((s) => s.startsWith('trace:'))), isTrue);
      expect(initialMemories.any((m) => m.sourceEntryIds.any((s) => s.startsWith('case:'))), isTrue);

      // Bulk clear traces: pass traces as empty list while keeping cases
      final afterClearingTraces = compression.compress(
        traces: const [],
        cases: cases,
        existingMemories: initialMemories,
        userId: 'u1',
      );

      // Trace memories must be gone; Case memory must be preserved
      expect(afterClearingTraces.any((m) => m.sourceEntryIds.any((s) => s.startsWith('trace:'))), isFalse);
      expect(afterClearingTraces.any((m) => m.summary.contains('I realize I overestimate')), isTrue);
    });

    test('19. Bulk deletion of Cases removes case memories while preserving Mind Trace themes', () async {
      const compression = JournalMemoryCompressionService();
      final now = DateTime.now();

      final traces = [
        MindTraceModel(
          id: 'tr_1',
          userId: 'u1',
          date: now.subtract(const Duration(days: 2)),
          overallMood: 'Anxious',
          moodIntensity: 7,
          situation: 'Family gathering discussion',
          selectedEmotions: ['tense'],
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        MindTraceModel(
          id: 'tr_2',
          userId: 'u1',
          date: now.subtract(const Duration(days: 1)),
          overallMood: 'Anxious',
          moodIntensity: 7,
          situation: 'Family gathering discussion',
          selectedEmotions: ['tense'],
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final cases = [
        CaseModel(
          id: 'case_2',
          userId: 'u1',
          caseNumber: 'CASE-102',
          incidentDescription: 'Communication dispute with family',
          title: 'Communication Breakdown',
          currentStage: CaseStage.conclusion,
          isCompleted: true,
          userConclusion: 'Pausing before responding prevents emotional escalation',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final initialMemories = compression.compress(
        traces: traces,
        cases: cases,
        userId: 'u1',
      );

      // Bulk clear cases: pass cases as empty list while keeping traces
      final afterClearingCases = compression.compress(
        traces: traces,
        cases: const [],
        existingMemories: initialMemories,
        userId: 'u1',
      );

      // Case memories must be gone; Trace recurring theme must be preserved
      expect(afterClearingCases.any((m) => m.sourceEntryIds.any((s) => s.startsWith('case:'))), isFalse);
      expect(afterClearingCases.any((m) => m.summary.contains('Family gathering discussion')), isTrue);
    });

    test('20. Persistent suppression: deleted memory does not reappear upon recalculation', () async {
      const compression = JournalMemoryCompressionService();
      final repo = LocalJournalMemoryRepository(userId: 'test_suppress_user');
      final now = DateTime.now();

      final traces = [
        MindTraceModel(
          id: 't_sup1',
          userId: 'test_suppress_user',
          date: now.subtract(const Duration(days: 2)),
          overallMood: 'Anxious',
          moodIntensity: 6,
          situation: 'Exam preparation stress',
          selectedEmotions: ['anxious'],
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        MindTraceModel(
          id: 't_sup2',
          userId: 'test_suppress_user',
          date: now.subtract(const Duration(days: 1)),
          overallMood: 'Anxious',
          moodIntensity: 6,
          situation: 'Exam preparation stress',
          selectedEmotions: ['anxious'],
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      // 1. Initial compression generates recurring theme
      final initial = compression.compress(
        traces: traces,
        userId: 'test_suppress_user',
      );
      final examTheme = initial.firstWhere((m) => m.summary.contains('Exam preparation stress'));
      await repo.saveAllMemories(initial);

      // 2. User deletes memory: key is suppressed and memory removed from repo
      final dedupKey = JournalMemoryCompressionService.generateDedupKey(
        examTheme.category,
        examTheme.summary,
      );
      await repo.suppressKey(dedupKey);
      await repo.deleteMemory(examTheme.id);

      final memoriesAfterDelete = await repo.getAllMemories();
      expect(memoriesAfterDelete.any((m) => m.id == examTheme.id), isFalse);

      // 3. User logs a NEW trace or recalculation runs with the SAME history
      final suppressedKeys = await repo.getSuppressedKeys();
      expect(suppressedKeys, contains(dedupKey));

      final recalculated = compression.compress(
        traces: traces,
        existingMemories: memoriesAfterDelete,
        userId: 'test_suppress_user',
        suppressedKeys: suppressedKeys,
      );

      // The deleted memory MUST NOT be recreated!
      expect(recalculated.any((m) => m.summary.contains('Exam preparation stress')), isFalse);

      // 4. Materially different new observation CAN still be extracted
      final tracesWithNewTheme = [
        ...traces,
        MindTraceModel(
          id: 't_new1',
          userId: 'test_suppress_user',
          date: now,
          overallMood: 'Calm',
          moodIntensity: 3,
          situation: 'Morning outdoor jogging',
          selectedEmotions: ['peaceful'],
          behavioralResponse: 'Morning outdoor jogging',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final recalculatedWithNew = compression.compress(
        traces: tracesWithNewTheme,
        existingMemories: recalculated,
        userId: 'test_suppress_user',
        suppressedKeys: suppressedKeys,
      );

      expect(recalculatedWithNew.any((m) => m.summary.contains('Morning outdoor jogging')), isTrue);
    });

    test('21. Namespaced identifiers: trace and case with identical raw ID do not collide', () {
      const compression = JournalMemoryCompressionService();
      final now = DateTime.now();
      const sharedRawId = 'shared_uuid_123';

      final traces = [
        MindTraceModel(
          id: sharedRawId,
          userId: 'u1',
          date: now,
          overallMood: 'Neutral',
          moodIntensity: 5,
          behavioralResponse: 'Took a short walk',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final cases = [
        CaseModel(
          id: sharedRawId,
          userId: 'u1',
          caseNumber: 'CASE-99',
          incidentDescription: 'Direct confrontation incident',
          title: 'Conflict Case',
          currentStage: CaseStage.conclusion,
          isCompleted: true,
          userConclusion: 'Clarified expectations directly',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final memories = compression.compress(
        traces: traces,
        cases: cases,
        userId: 'u1',
      );

      final traceMem = memories.firstWhere((m) => m.summary.contains('Took a short walk'));
      final caseMem = memories.firstWhere((m) => m.summary.contains('Clarified expectations'));

      expect(traceMem.sourceEntryIds, contains('trace:$sharedRawId'));
      expect(caseMem.sourceEntryIds, contains('case:$sharedRawId'));

      // Deleting the trace must prune only the trace memory
      final prunedTrace = compression.pruneAfterDeletion(
        deletedEntryId: 'trace:$sharedRawId',
        existingMemories: memories,
      );

      expect(prunedTrace.any((m) => m.id == traceMem.id), isFalse);
      expect(prunedTrace.any((m) => m.id == caseMem.id), isTrue);
    });
  });
}

class _TestJournalMemoryNotifier extends AsyncNotifier<List<JournalMemoryModel>>
    implements JournalMemoryNotifier {
  _TestJournalMemoryNotifier(this._initial);
  final List<JournalMemoryModel> _initial;

  @override
  Future<List<JournalMemoryModel>> build() async => _initial;

  @override
  Future<void> confirmMemory(String id) async {
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((m) => m.id == id ? m.copyWith(confirmationStatus: MemoryConfirmationStatus.confirmed) : m).toList(),
    );
  }

  @override
  Future<void> rejectMemory(String id) async {
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((m) => m.id == id ? m.copyWith(confirmationStatus: MemoryConfirmationStatus.rejected) : m).toList(),
    );
  }

  @override
  Future<void> deleteMemory(String id) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((m) => m.id != id).toList());
  }

  @override
  Future<void> clearAll() async {
    state = const AsyncValue.data([]);
  }

  @override
  Future<void> handleEntryDeleted(String entryId) async {}

  @override
  Future<List<JournalMemoryModel>> recalculateMemories({
    List<MindTraceModel>? traces,
    List<CaseModel>? cases,
  }) async => state.value ?? [];
}

