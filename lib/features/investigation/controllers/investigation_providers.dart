import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/security/secure_key_manager.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../journal/controllers/journal_memory_controller.dart';
import '../data/direct_gemini_investigator_service.dart';
import '../data/local_case_repository.dart';
import '../data/mock_investigator_service.dart';
import '../domain/case_model.dart';
import '../domain/case_repository.dart';
import '../domain/case_stage.dart';
import '../domain/conversation_mode.dart';
import '../domain/forensic_chain.dart';
import '../domain/hypothesis.dart';
import '../domain/investigator_service.dart';
import '../domain/label_type.dart';
import '../domain/session_dialogue_compressor.dart';
import '../domain/session_memory_window.dart';
import '../domain/statement.dart';

/// Public API key configured for Mind Forensics demo/testing.
/// For production builds, supply via `--dart-define=GEMINI_API_KEY=your_key`.
const String kPublicGeminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: 'DEV_MOCK_GEMINI_KEY',
);

/// Sentinel key representing development mock mode.
const String kDevMockGeminiKey = 'DEV_MOCK_GEMINI_KEY';

/// Configuration state for the AI Investigator Engine.
class AiConfigState {
  const AiConfigState({
    this.apiKey = kPublicGeminiApiKey,
    this.useLiveAi = true,
    this.modelName = 'gemini-3.5-flash',
  });

  final String apiKey;
  final bool useLiveAi;
  final String modelName;

  bool get isMockKey => apiKey.trim() == kDevMockGeminiKey || apiKey.trim().isEmpty;

  bool get isLiveActive => useLiveAi && apiKey.trim().isNotEmpty && !isMockKey;

  AiConfigState copyWith({
    String? apiKey,
    bool? useLiveAi,
    String? modelName,
  }) {
    return AiConfigState(
      apiKey: apiKey ?? this.apiKey,
      useLiveAi: useLiveAi ?? this.useLiveAi,
      modelName: modelName ?? this.modelName,
    );
  }
}

class AiConfigNotifier extends Notifier<AiConfigState> {
  static const String _prefUseLive = 'mf_use_live_gemini';

  @override
  AiConfigState build() {
    _loadFromSecureStorage();
    return const AiConfigState();
  }

  Future<void> _loadFromSecureStorage() async {
    final keyManager = ref.read(secureKeyManagerProvider);
    final prefs = await SharedPreferences.getInstance();
    var secureKey = await keyManager.getGeminiApiKey();
    if (secureKey.isEmpty && kPublicGeminiApiKey != kDevMockGeminiKey && kPublicGeminiApiKey.isNotEmpty) {
      await keyManager.saveGeminiApiKey(kPublicGeminiApiKey);
      secureKey = kPublicGeminiApiKey;
    }
    if (!ref.mounted) return;
    final effectiveKey = secureKey.isNotEmpty ? secureKey : kPublicGeminiApiKey;
    final useLive = prefs.getBool(_prefUseLive) ?? true;
    state = AiConfigState(
      apiKey: effectiveKey,
      useLiveAi: useLive,
      modelName: 'gemini-3.5-flash',
    );
  }

  Future<void> toggleLiveMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefUseLive, enabled);
    if (!ref.mounted) return;
    state = state.copyWith(useLiveAi: enabled);
  }

  Future<void> setApiKey(String key) async {
    final keyManager = ref.read(secureKeyManagerProvider);
    final clean = key.trim();
    await keyManager.saveGeminiApiKey(clean);
    if (!ref.mounted) return;
    state = state.copyWith(
      apiKey: clean.isNotEmpty ? clean : kPublicGeminiApiKey,
      useLiveAi: true,
    );
  }

  Future<void> clearApiKey() async {
    final keyManager = ref.read(secureKeyManagerProvider);
    final prefs = await SharedPreferences.getInstance();
    await keyManager.clearGeminiApiKey();
    await prefs.setBool(_prefUseLive, false);
    if (!ref.mounted) return;
    state = const AiConfigState(
      apiKey: '',
      useLiveAi: false,
    );
  }
}

final aiConfigProvider =
    NotifierProvider<AiConfigNotifier, AiConfigState>(AiConfigNotifier.new);

/// Provider for Case persistence with user-level isolation.
final caseRepositoryProvider = Provider<CaseRepository>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.user?.id));
  final keyManager = ref.watch(secureKeyManagerProvider);
  return LocalCaseRepository(
    userId: userId,
    keyManager: keyManager,
  );
});

/// Provider for loading all saved sessions/conversations.
final savedCasesProvider = FutureProvider<List<CaseModel>>((ref) async {
  final repo = ref.watch(caseRepositoryProvider);
  return repo.getAllCases();
});

/// Selected conversation mode in the AI Companion Hub.
final currentConversationModeProvider =
    NotifierProvider<CurrentConversationModeNotifier, ConversationMode>(
        CurrentConversationModeNotifier.new);

class CurrentConversationModeNotifier extends Notifier<ConversationMode> {
  @override
  ConversationMode build() => ConversationMode.exploreThought;

  void setMode(ConversationMode mode) {
    state = mode;
  }
}

/// Provider for the AI Investigator.
///
/// Automatically routes to [DirectGeminiInvestigatorService] when a valid Gemini
/// API key is active, or seamlessly falls back to [MockInvestigatorService] ($0.00).
final investigatorServiceProvider = Provider<InvestigatorService>((ref) {
  final config = ref.watch(aiConfigProvider);
  if (config.isLiveActive) {
    return DirectGeminiInvestigatorService(
      apiKey: config.apiKey,
      modelName: config.modelName,
    );
  }
  return MockInvestigatorService();
});

/// State controller for an active Flash Case / AI Companion session (Riverpod 3 Notifier).
class ActiveCaseController extends Notifier<AsyncValue<CaseModel?>> {
  Future<CaseModel?>? _hydrationFuture;

  @override
  AsyncValue<CaseModel?> build() {
    _hydrationFuture = _hydrateActiveCase();
    return const AsyncValue.data(null);
  }

  Future<CaseModel?> _hydrateActiveCase() async {
    try {
      final repo = ref.read(caseRepositoryProvider);
      final cases = await repo.getAllCases();
      final activeCases = cases.where((c) => !c.isCompleted).toList();
      if (activeCases.isNotEmpty && (state.value == null || state.value!.isCompleted)) {
        state = AsyncValue.data(activeCases.first);
        return activeCases.first;
      }
    } catch (_) {}
    return state.value;
  }

  /// Ensures active session hydration is fully resolved before checking if a case exists.
  Future<CaseModel?> ensureHydrated() async {
    if (_hydrationFuture != null) {
      await _hydrationFuture;
    }
    return state.value;
  }

  /// Sets or resumes an existing case.
  void resumeCase(CaseModel caseModel) {
    state = AsyncValue.data(caseModel);
  }

  /// Clears the active case from the session.
  void resetActiveCase() {
    state = const AsyncValue.data(null);
  }

  /// Changes the active conversation mode.
  Future<void> setConversationMode(ConversationMode mode) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(
      conversationMode: mode,
      updatedAt: DateTime.now(),
    );
    await ref.read(caseRepositoryProvider).saveCase(updated);
    state = AsyncValue.data(updated);
    ref.invalidate(savedCasesProvider);
  }

  /// Starts a fresh Flash Case / AI Companion session.
  Future<CaseModel> startNewCase(
    String initialIncident, {
    ConversationMode? mode,
  }) async {
    try {
      final repo = ref.read(caseRepositoryProvider);
      final caseNumber = await repo.getNextCaseNumber();
      final now = DateTime.now();
      final authState = ref.read(authControllerProvider);
      final ConversationMode activeMode =
          mode ?? ref.read(currentConversationModeProvider);

      final isBlankSession = initialIncident.trim().isEmpty ||
          initialIncident == 'Unopened Case' ||
          initialIncident == 'Unopened Session' ||
          initialIncident == 'Active Deconstruction';

      final initialStatements = <Statement>[];
      if (isBlankSession) {
        initialStatements.add(
          Statement(
            id: const Uuid().v4(),
            text: activeMode.openingQuestion,
            speaker: StatementSpeaker.investigator,
            timestamp: now,
          ),
        );
      } else {
        initialStatements.add(
          Statement(
            id: const Uuid().v4(),
            text: initialIncident,
            speaker: StatementSpeaker.user,
            label: LabelType.assumption,
            timestamp: now,
          ),
        );
      }

      final newCase = CaseModel(
        id: const Uuid().v4(),
        userId: authState.user?.id ?? 'local_user',
        caseNumber: caseNumber,
        title: isBlankSession
            ? activeMode.displayName
            : (initialIncident.length > 30
                ? '${initialIncident.substring(0, 30)}...'
                : initialIncident),
        conversationMode: activeMode,
        createdAt: now,
        updatedAt: now,
        currentStage: CaseStage.incident,
        incidentDescription: isBlankSession ? '' : initialIncident,
        statements: initialStatements,
      );

      // Immediately present the new session to the UI without blocking for disk write
      state = AsyncValue.data(newCase);

      await repo.saveCase(newCase);
      ref.invalidate(savedCasesProvider);
      return newCase;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Renames a case and refreshes state if it is currently active.
  Future<void> renameCase(String id, String newTitle) async {
    final repo = ref.read(caseRepositoryProvider);
    await repo.renameCase(id, newTitle);
    final current = state.value;
    if (current != null && current.id == id) {
      state = AsyncValue.data(
        current.copyWith(title: newTitle.trim(), updatedAt: DateTime.now()),
      );
    }
    ref.invalidate(savedCasesProvider);
  }

  /// Deletes a case and clears the active session if currently open.
  Future<void> deleteCase(String id) async {
    final repo = ref.read(caseRepositoryProvider);
    await repo.deleteCase(id);
    final current = state.value;
    if (current != null && current.id == id) {
      state = const AsyncValue.data(null);
    }
    ref.read(journalMemoryControllerProvider.notifier).handleEntryDeleted('case:$id');
    ref.invalidate(savedCasesProvider);
  }

  /// Deletes all cases and resets the active session.
  Future<void> deleteAllCases() async {
    final repo = ref.read(caseRepositoryProvider);
    await repo.deleteAllCases();
    state = const AsyncValue.data(null);
    // Correct bulk deletion: clears case memories by recompressing with an empty case list,
    // reloading and preserving valid trace-derived memories.
    await ref
        .read(journalMemoryControllerProvider.notifier)
        .recalculateMemories(cases: const []);
    ref.invalidate(savedCasesProvider);
  }

  /// Updates the incident text on the active case.
  Future<void> updateIncident(String incidentText) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      incidentDescription: incidentText,
      title: incidentText.trim().isNotEmpty
          ? (incidentText.length > 30 ? '${incidentText.substring(0, 30)}...' : incidentText)
          : current.title,
      updatedAt: DateTime.now(),
    );

    await ref.read(caseRepositoryProvider).saveCase(updated);
    state = AsyncValue.data(updated);
    ref.invalidate(savedCasesProvider);
  }

  /// Advances or moves the case to a specific stage.
  Future<void> advanceStage(CaseStage nextStage) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      currentStage: nextStage,
      updatedAt: DateTime.now(),
    );

    await ref.read(caseRepositoryProvider).saveCase(updated);
    state = AsyncValue.data(updated);
    ref.invalidate(savedCasesProvider);
  }

  /// Adds a statement with its forensic label, recomputing session summary deterministically.
  Future<void> addStatement(
    String text,
    StatementSpeaker speaker, {
    LabelType? label,
    bool isSafetyStatement = false,
  }) async {
    final current = state.value;
    if (current == null) return;
    if (current.isPausedForSafety && !isSafetyStatement) {
      // Normal dialogue actions cannot bypass a paused case
      return;
    }

    final newStatement = Statement(
      id: const Uuid().v4(),
      text: text,
      speaker: speaker,
      label: label,
      timestamp: DateTime.now(),
    );

    final updatedStatements = [...current.statements, newStatement];

    // Partition memory window and recompute structured session summary if older turns exist
    final window = SessionMemoryWindowManager.partition(updatedStatements);
    String? newSummary = current.sessionSummary;
    if (window.olderStatements.isNotEmpty) {
      newSummary = SessionDialogueCompressor.recomputeSummary(
        olderStatements: window.olderStatements,
        currentCase: current.copyWith(statements: updatedStatements),
      );
    }

    final updated = current.copyWith(
      statements: updatedStatements,
      sessionSummary: newSummary,
      updatedAt: DateTime.now(),
    );

    await ref.read(caseRepositoryProvider).saveCase(updated);
    state = AsyncValue.data(updated);
    ref.invalidate(savedCasesProvider);
  }

  /// Pauses the active case for safety with fail-closed persistence guarantees.
  Future<bool> pauseCaseForSafety() async {
    final current = state.value;
    if (current == null) return false;
    try {
      final paused = current.copyWith(
        isPausedForSafety: true,
        updatedAt: DateTime.now(),
      );
      await ref.read(caseRepositoryProvider).saveCase(paused);
      state = AsyncValue.data(paused);
      ref.invalidate(savedCasesProvider);
      return true;
    } catch (_) {
      // Fail closed: return false on persistence failure
      return false;
    }
  }

  /// Records the forensic chain (Trigger -> Thought -> Emotion -> Behavior).
  Future<void> recordChain(ForensicChain chain) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      chain: chain,
      emotionTags: chain.emotion.isNotEmpty ? [chain.emotion] : current.emotionTags,
      updatedAt: DateTime.now(),
    );

    await ref.read(caseRepositoryProvider).saveCase(updated);
    state = AsyncValue.data(updated);
    ref.invalidate(savedCasesProvider);
  }

  /// Persists the generated hypotheses to the case.
  Future<void> saveHypotheses(List<Hypothesis> hypotheses) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      hypotheses: hypotheses,
      updatedAt: DateTime.now(),
    );

    await ref.read(caseRepositoryProvider).saveCase(updated);
    state = AsyncValue.data(updated);
    ref.invalidate(savedCasesProvider);
  }

  /// Persists the findings summary to the case.
  Future<void> saveFindings(String findings) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      findingsSummary: findings,
      updatedAt: DateTime.now(),
    );

    await ref.read(caseRepositoryProvider).saveCase(updated);
    state = AsyncValue.data(updated);
    ref.invalidate(savedCasesProvider);
  }

  /// Saves the user's final conclusion and marks the case as completed.
  Future<void> saveConclusion(String conclusion) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      userConclusion: conclusion,
      isCompleted: true,
      currentStage: CaseStage.conclusion,
      updatedAt: DateTime.now(),
    );

    await ref.read(caseRepositoryProvider).saveCase(updated);
    state = AsyncValue.data(updated);
    ref.read(journalMemoryControllerProvider.notifier).recalculateMemories();
    ref.invalidate(savedCasesProvider);
  }
}

final activeCaseControllerProvider =
    NotifierProvider<ActiveCaseController, AsyncValue<CaseModel?>>(ActiveCaseController.new);
