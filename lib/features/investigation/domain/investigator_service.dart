import '../../journal/domain/journal_memory_model.dart';
import '../../journey/domain/journey_state_model.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../profile/domain/psychological_profile_model.dart';
import 'case_model.dart';
import 'conversation_mode.dart';
import 'hypothesis.dart';
import 'statement.dart';

/// Abstract service defining interactions with the Psychological Companion AI.
///
/// Section 4 & 11:
/// - Rigorous in method, gentle in tone.
/// - Never diagnoses, always speaks in hypotheses and questions.
/// - Trilingual: Supports English ('en'), Français ('fr'), and authentic Tunisian Arabic ('ar').
abstract class InvestigatorService {
  /// Generates the next investigative question or observation based on current statements.
  Future<String> getNextQuestion({
    required CaseModel currentCase,
    required List<Statement> conversationHistory,
    bool includePastCaseSummaries = true,
    String? languageCode,
    PsychologicalProfileModel? profile,
    JourneyStateModel? journey,
    ConversationMode? conversationMode,
    MindTraceModel? latestTrace,
    List<MindTraceModel>? historicalTraces,
    List<JournalMemoryModel>? compressedMemories,
    String? sessionSummary,
  });

  /// Proposes several candidate hypotheses based on evidence gathered.
  /// Section 2: "Always several, never one verdict."
  Future<List<Hypothesis>> generateHypotheses({
    required CaseModel currentCase,
    String? languageCode,
    PsychologicalProfileModel? profile,
  });

  /// Cross-examines a selected hypothesis to test its validity.
  Future<List<String>> generateCrossExaminationQuestions({
    required CaseModel currentCase,
    required Hypothesis hypothesis,
    String? languageCode,
    PsychologicalProfileModel? profile,
  });

  /// Produces the structured findings summary.
  Future<String> summarizeFindings({
    required CaseModel currentCase,
    String? languageCode,
    PsychologicalProfileModel? profile,
  });
}
