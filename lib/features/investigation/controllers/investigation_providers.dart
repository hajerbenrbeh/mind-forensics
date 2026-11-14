import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/safety/crisis_keywords.dart';
import '../../../core/security/secure_key_manager.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../journal/controllers/journal_memory_controller.dart';
import '../data/direct_gemini_investigator_service.dart';
import '../data/direct_groq_investigator_service.dart';
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

/// Public Gemini API key configured at build time via `--dart-define=GEMINI_API_KEY=...`.
const String kPublicGeminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: 'DEV_MOCK_GEMINI_KEY',
);

/// Public Groq free-tier API key configured at build time via `--dart-define=GROQ_API_KEY=...`.
const String kPublicGroqApiKey = String.fromEnvironment(
  'GROQ_API_KEY',
  defaultValue: '',
);

/// Optional backend proxy endpoint (`--dart-define=AI_PROXY_URL=https://...`) so public APKs
/// never embed raw provider secret keys directly in client binaries.
const String kPublicAiProxyUrl = String.fromEnvironment(
  'AI_PROXY_URL',
  defaultValue: '',
);

/// Sentinel key representing development mock mode.
const String kDevMockGeminiKey = 'DEV_MOCK_GEMINI_KEY';

/// Supported live AI inference providers.
enum AiEngineProvider {
  groq,
  gemini,
}

/// Configuration state for the AI Investigator Engine.
class AiConfigState {
  const AiConfigState({
    this.provider = _defaultProvider,
    this.apiKey = kPublicGeminiApiKey,
    this.groqApiKey = kPublicGroqApiKey,
    this.proxyUrl = kPublicAiProxyUrl,
    this.useLiveAi = true,
    this.modelName = _defaultModel,
  });

  static const AiEngineProvider _defaultProvider =
      (kPublicGroqApiKey != '' || kPublicAiProxyUrl != '')
          ? AiEngineProvider.groq
          : AiEngineProvider.gemini;

  static const String _defaultModel =
      (kPublicGroqApiKey != '' || kPublicAiProxyUrl != '')
          ? DirectGroqInvestigatorService.defaultModel
          : 'gemini-3.5-flash';

  final AiEngineProvider provider;
  final String apiKey;
  final String groqApiKey;
  final String proxyUrl;
  final bool useLiveAi;
  final String modelName;

  /// Active key for whichever provider is selected.
  String get activeApiKey =>
      provider == AiEngineProvider.groq ? groqApiKey : apiKey;

  bool get hasProxy => proxyUrl.trim().isNotEmpty;

  bool get isMockKey {
    if (provider == AiEngineProvider.groq) {
      if (hasProxy) return false;
      final clean = groqApiKey.trim();
      return clean.isEmpty || clean == kDevMockGeminiKey;
    }
    final clean = apiKey.trim();
    return clean == kDevMockGeminiKey || clean.isEmpty;
  }

  bool get isLiveActive => useLiveAi && !isMockKey;

  String get defaultModelForProvider => provider == AiEngineProvider.groq
      ? DirectGroqInvestigatorService.defaultModel
      : 'gemini-3.5-flash';

  AiConfigState copyWith({
    AiEngineProvider? provider,
    String? apiKey,
    String? groqApiKey,
    String? proxyUrl,
    bool? useLiveAi,
    String? modelName,
  }) {
    return AiConfigState(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      groqApiKey: groqApiKey ?? this.groqApiKey,
      proxyUrl: proxyUrl ?? this.proxyUrl,
      useLiveAi: useLiveAi ?? this.useLiveAi,
      modelName: modelName ?? this.modelName,
    );
  }
}

class AiConfigNotifier extends Notifier<AiConfigState> {
  static const String _prefUseLive = 'mf_use_live_gemini';
  static const String _prefProvider = 'mf_ai_provider';

  @override
  AiConfigState build() {
    _loadFromSecureStorage();
    return const AiConfigState();
  }

  Future<void> _loadFromSecureStorage() async {
    final keyManager = ref.read(secureKeyManagerProvider);
    final prefs = await SharedPreferences.getInstance();

    var secureGemini = await keyManager.getGeminiApiKey();
    if (secureGemini.isEmpty &&
        kPublicGeminiApiKey != kDevMockGeminiKey &&
        kPublicGeminiApiKey.isNotEmpty) {
      await keyManager.saveGeminiApiKey(kPublicGeminiApiKey);
      secureGemini = kPublicGeminiApiKey;
    }

    var secureGroq = await keyManager.getGroqApiKey();
    if (secureGroq.isEmpty && kPublicGroqApiKey.isNotEmpty) {
      await keyManager.saveGroqApiKey(kPublicGroqApiKey);
      secureGroq = kPublicGroqApiKey;
    }

    if (!ref.mounted) return;

    final savedProvider = prefs.getString(_prefProvider);
    final AiEngineProvider effectiveProvider;
    if (savedProvider == AiEngineProvider.groq.name) {
      effectiveProvider = AiEngineProvider.groq;
    } else if (savedProvider == AiEngineProvider.gemini.name) {
      effectiveProvider = AiEngineProvider.gemini;
    } else {
      effectiveProvider = (secureGroq.isNotEmpty || kPublicAiProxyUrl.isNotEmpty)
          ? AiEngineProvider.groq
          : AiEngineProvider.gemini;
    }

    final effectiveGemini =
        secureGemini.isNotEmpty ? secureGemini : kPublicGeminiApiKey;
    final effectiveGroq =
        secureGroq.isNotEmpty ? secureGroq : kPublicGroqApiKey;
    final useLive = prefs.getBool(_prefUseLive) ?? true;

    state = AiConfigState(
      provider: effectiveProvider,
      apiKey: effectiveGemini,
      groqApiKey: effectiveGroq,
      proxyUrl: kPublicAiProxyUrl,
      useLiveAi: useLive,
      modelName: effectiveProvider == AiEngineProvider.groq
          ? DirectGroqInvestigatorService.defaultModel
          : 'gemini-3.5-flash',
    );
  }

  Future<void> setProvider(AiEngineProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefProvider, provider.name);
    if (!ref.mounted) return;
    state = state.copyWith(
      provider: provider,
      modelName: provider == AiEngineProvider.groq
          ? DirectGroqInvestigatorService.defaultModel
          : 'gemini-3.5-flash',
    );
  }

  Future<void> toggleLiveMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefUseLive, enabled);
    if (!ref.mounted) return;
    state = state.copyWith(useLiveAi: enabled);
  }

  Future<void> setApiKey(String key, {AiEngineProvider? provider}) async {
    final target = provider ?? state.provider;
    final keyManager = ref.read(secureKeyManagerProvider);
    final prefs = await SharedPreferences.getInstance();
    final clean = key.trim();
    await prefs.setString(_prefProvider, target.name);

    if (target == AiEngineProvider.groq) {
      await keyManager.saveGroqApiKey(clean);
      if (!ref.mounted) return;
      state = state.copyWith(
        provider: target,
        groqApiKey: clean.isNotEmpty ? clean : kPublicGroqApiKey,
        useLiveAi: true,
        modelName: DirectGroqInvestigatorService.defaultModel,
      );
    } else {
      await keyManager.saveGeminiApiKey(clean);
      if (!ref.mounted) return;
      state = state.copyWith(
        provider: target,
        apiKey: clean.isNotEmpty ? clean : kPublicGeminiApiKey,
        useLiveAi: true,
        modelName: 'gemini-3.5-flash',
      );
    }
  }

  Future<void> clearApiKey({AiEngineProvider? provider}) async {
    final target = provider ?? state.provider;
    final keyManager = ref.read(secureKeyManagerProvider);
    final prefs = await SharedPreferences.getInstance();
    if (target == AiEngineProvider.groq) {
      await keyManager.clearGroqApiKey();
      await prefs.setBool(_prefUseLive, false);
      if (!ref.mounted) return;
      state = state.copyWith(
        groqApiKey: '',
        useLiveAi: false,
      );
    } else {
      await keyManager.clearGeminiApiKey();
      await prefs.setBool(_prefUseLive, false);
      if (!ref.mounted) return;
      state = state.copyWith(
        apiKey: '',
        useLiveAi: false,
      );
    }
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
/// Routes to [DirectGroqInvestigatorService] or [DirectGeminiInvestigatorService]
/// when live inference is active, or falls back to [MockInvestigatorService] (\$0.00).
final investigatorServiceProvider = Provider<InvestigatorService>((ref) {
  final config = ref.watch(aiConfigProvider);
  if (config.isLiveActive) {
    if (config.provider == AiEngineProvider.groq) {
      return DirectGroqInvestigatorService(
        apiKey: config.groqApiKey,
        modelName: config.modelName,
        proxyUrl: config.proxyUrl,
      );
    }
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
        var activeCase = activeCases.first;
        if (!activeCase.isPausedForSafety && _hasCriticalSafetyStatement(activeCase)) {
          activeCase = activeCase.copyWith(
            isPausedForSafety: true,
            updatedAt: DateTime.now(),
          );
          try {
            await repo.saveCase(activeCase);
          } catch (e) {
            debugPrint(
                'Safety Warning: Failed to heal safety pause to disk on hydration: ${e.runtimeType}');
          }
        }
        state = AsyncValue.data(activeCase);
        return activeCase;
      }
    } catch (_) {}
    return state.value;
  }

  /// Determines offline if an active case contains un-paused statements requiring immediate safety interruption.
  ///
  /// Only considers: immediateMedicalEmergency, imminentIntentOrCrisis, and accidentalIngestionAlert.
  /// Never considers ordinary intrusive thoughts, fear of losing control, or general distress.
  bool _hasCriticalSafetyStatement(CaseModel caseModel) {
    for (final statement in caseModel.statements) {
      if (statement.speaker != StatementSpeaker.user) continue;
      final classification = CrisisKeywords.classifyText(statement.text);
      if (classification == SafetyClassification.immediateMedicalEmergency ||
          classification == SafetyClassification.imminentIntentOrCrisis ||
          classification == SafetyClassification.accidentalIngestionAlert) {
        return true;
      }
    }
    return false;
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
    var toResume = caseModel;
    if (!toResume.isPausedForSafety && _hasCriticalSafetyStatement(toResume)) {
      toResume = toResume.copyWith(
        isPausedForSafety: true,
        updatedAt: DateTime.now(),
      );
    }
    state = AsyncValue.data(toResume);
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

    if (isSafetyStatement) {
      // Ensure in-memory state reflects safety statement immediately (fail-closed in volatile memory)
      state = AsyncValue.data(updated);
    }

    await ref.read(caseRepositoryProvider).saveCase(updated);
    if (!isSafetyStatement) {
      state = AsyncValue.data(updated);
    }
    ref.invalidate(savedCasesProvider);
  }

  /// Pauses the active case for safety with fail-closed persistence guarantees.
  Future<bool> pauseCaseForSafety() async {
    final current = state.value;
    if (current == null) return false;
    final paused = current.copyWith(
      isPausedForSafety: true,
      updatedAt: DateTime.now(),
    );
    // Fail-closed in memory immediately: ensure runtime never routes subsequent messages to AI
    state = AsyncValue.data(paused);
    try {
      await ref.read(caseRepositoryProvider).saveCase(paused);
      ref.invalidate(savedCasesProvider);
      return true;
    } catch (e) {
      // Fail closed: return false on persistence failure, logging safe diagnostic info without sensitive content
      debugPrint('Safety Warning: Failed to persist safety pause to repository: ${e.runtimeType}');
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
