import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../auth/controllers/auth_controller.dart';
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
import '../domain/statement.dart';

/// Public API key configured for Mind Forensics demo/testing.
/// For production builds, supply via `--dart-define=GEMINI_API_KEY=your_key`.
const String kPublicGeminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: 'DEV_MOCK_GEMINI_KEY',
);

/// Configuration state for the AI Investigator Engine.
class AiConfigState {
  const AiConfigState({
    this.apiKey = kPublicGeminiApiKey,
    this.useLiveAi = true,
    this.modelName = 'gemini-3.1-flash-lite',
  });

  final String apiKey;
  final bool useLiveAi;
  final String modelName;

  bool get isLiveActive => useLiveAi && apiKey.trim().isNotEmpty;
}

class AiConfigNotifier extends Notifier<AiConfigState> {
  static const String _prefUseLive = 'mf_use_live_gemini';

  @override
  AiConfigState build() {
    _loadFromPrefs();
    return const AiConfigState();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Guarantee live AI mode is active out-of-the-box with the public key.
    // Overwrite any legacy disabled preference so live Gemini is always active.
    if (prefs.containsKey(_prefUseLive) && !(prefs.getBool(_prefUseLive) ?? true)) {
      await prefs.setBool(_prefUseLive, true);
    }
    state = const AiConfigState(
      apiKey: kPublicGeminiApiKey,
      useLiveAi: true,
      modelName: 'gemini-3.1-flash-lite',
    );
  }

  Future<void> toggleLiveMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefUseLive, enabled);
    state = AiConfigState(
      apiKey: kPublicGeminiApiKey,
      useLiveAi: enabled,
    );
  }

  Future<void> setApiKey(String key) async {
    // Kept for backward-compatibility if invoked programmatically
    state = AiConfigState(
      apiKey: key.trim().isNotEmpty ? key.trim() : kPublicGeminiApiKey,
      useLiveAi: true,
    );
  }

  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefUseLive, false);
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
  final authState = ref.watch(authControllerProvider);
  return LocalCaseRepository(userId: authState.user?.id);
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
  @override
  AsyncValue<CaseModel?> build() {
    return const AsyncValue.data(null);
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
    state = const AsyncValue.loading();
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

      await repo.saveCase(newCase);
      state = AsyncValue.data(newCase);
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
    ref.invalidate(savedCasesProvider);
  }

  /// Deletes all cases and resets the active session.
  Future<void> deleteAllCases() async {
    final repo = ref.read(caseRepositoryProvider);
    await repo.deleteAllCases();
    state = const AsyncValue.data(null);
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

  /// Adds a statement with its forensic label.
  Future<void> addStatement(String text, StatementSpeaker speaker, {LabelType? label}) async {
    final current = state.value;
    if (current == null) return;

    final newStatement = Statement(
      id: const Uuid().v4(),
      text: text,
      speaker: speaker,
      label: label,
      timestamp: DateTime.now(),
    );

    final updatedStatements = [...current.statements, newStatement];
    final updated = current.copyWith(
      statements: updatedStatements,
      updatedAt: DateTime.now(),
    );

    await ref.read(caseRepositoryProvider).saveCase(updated);
    state = AsyncValue.data(updated);
    ref.invalidate(savedCasesProvider);
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
    ref.invalidate(savedCasesProvider);
  }
}

final activeCaseControllerProvider =
    NotifierProvider<ActiveCaseController, AsyncValue<CaseModel?>>(ActiveCaseController.new);
