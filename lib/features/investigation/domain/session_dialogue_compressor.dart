import '../../../core/safety/crisis_keywords.dart';
import 'case_model.dart';
import 'label_type.dart';
import 'statement.dart';

/// Three objective inquiry-resolution classifications for older dialogue inquiries.
///
/// Deterministic compression cannot semantically verify whether a natural-language
/// response adequately resolves a cognitive distortion. These classifications
/// provide objective truth without premature semantic assumptions.
enum InquiryResolutionState {
  /// An investigator inquiry was posed, but no subsequent user response exists in the case.
  noSubsequentResponse,

  /// A subsequent user statement exists, but deterministic compression cannot establish
  /// whether it fully resolves the inquiry.
  responseRecordedUndetermined,

  /// An existing structured case field (user conclusion, findings, or forensic chain)
  /// explicitly establishes a finalized resolution.
  explicitlyResolved;

  String get labelText {
    switch (this) {
      case InquiryResolutionState.noSubsequentResponse:
        return 'No subsequent user response recorded';
      case InquiryResolutionState.responseRecordedUndetermined:
        return 'Response recorded — resolution undetermined';
      case InquiryResolutionState.explicitlyResolved:
        return 'Explicitly resolved via Case Conclusion / Structured Findings';
    }
  }
}

/// Recorded inquiry extracted from older dialogue turns.
class OlderInquiryRecord {
  const OlderInquiryRecord({
    required this.inquiryText,
    required this.turnIndex,
    this.subsequentUserText,
    this.subsequentUserTurnIndex,
    required this.resolutionState,
  });

  final String inquiryText;
  final int turnIndex;
  final String? subsequentUserText;
  final int? subsequentUserTurnIndex;
  final InquiryResolutionState resolutionState;
}

/// Deterministic, sovereign local compressor for dialogue turns outside the verbatim window.
///
/// Strictly enforces:
/// - Deterministic recomputation from original statements (no telephone-game drift).
/// - Speaker attribution (User stated vs Investigator noted).
/// - Epistemic classification integrity: "User-Labelled Facts [F]", never app-verified facts.
/// - Assumptions and Interpretations preserved without promotion.
/// - Hypotheses and counter-evidence (`whatDoesNotFit`) attributed to candidate hypotheses.
/// - Three-state objective inquiry tracking.
/// - Unresolved safety signals explicitly preserved.
/// - Zero psychiatric diagnoses.
class SessionDialogueCompressor {
  /// Recomputes the structured session summary from [olderStatements] and [currentCase].
  static String? recomputeSummary({
    required List<Statement> olderStatements,
    required CaseModel currentCase,
  }) {
    if (olderStatements.isEmpty) return null;

    final buffer = StringBuffer();
    buffer.writeln('SESSION PROGRESSION & CONTEXT (${currentCase.caseNumber}):');

    // 1. Initiating Incident
    final incident = currentCase.incidentDescription.trim();
    if (incident.isNotEmpty) {
      buffer.writeln('• Initiating Incident:');
      buffer.writeln('  - User reported: "$incident"');
    } else {
      final firstUserStatement = olderStatements.firstWhere(
        (s) => s.speaker == StatementSpeaker.user,
        orElse: () => olderStatements.first,
      );
      buffer.writeln('• Initiating Incident:');
      buffer.writeln('  - Initial report: "${firstUserStatement.text.trim()}"');
    }

    // 2. User-Labelled Facts [F] (Classified by user as observable, NOT application-verified)
    final facts = olderStatements
        .where((s) => s.label == LabelType.fact && s.text.trim().isNotEmpty)
        .toList();
    if (facts.isNotEmpty) {
      buffer.writeln('\n• User-Labelled Facts [F] (Classified by user as observable):');
      for (final s in facts) {
        final speakerPrefix = s.speaker == StatementSpeaker.user
            ? 'User stated'
            : 'Investigator noted';
        final turnIndex = olderStatements.indexOf(s) + 1;
        buffer.writeln('  - $speakerPrefix: "${s.text.trim()}" (Turn $turnIndex)');
      }
    }

    // 3. Unverified Assumptions [A] (Reported by user as unverified thoughts)
    final assumptions = olderStatements
        .where((s) => s.label == LabelType.assumption && s.text.trim().isNotEmpty)
        .toList();
    if (assumptions.isNotEmpty) {
      buffer.writeln('\n• Unverified Assumptions [A] (Reported by user as unverified thoughts):');
      for (final s in assumptions) {
        final speakerPrefix = s.speaker == StatementSpeaker.user
            ? 'User stated'
            : 'Investigator noted';
        final turnIndex = olderStatements.indexOf(s) + 1;
        buffer.writeln('  - $speakerPrefix: "${s.text.trim()}" (Turn $turnIndex)');
      }
    }

    // 4. Subjective Interpretations [I] (Personal meaning attributed by user)
    final interpretations = olderStatements
        .where((s) => s.label == LabelType.interpretation && s.text.trim().isNotEmpty)
        .toList();
    if (interpretations.isNotEmpty) {
      buffer.writeln('\n• Subjective Interpretations [I] (Personal meaning attributed by user):');
      for (final s in interpretations) {
        final speakerPrefix = s.speaker == StatementSpeaker.user
            ? 'User stated'
            : 'Investigator noted';
        final turnIndex = olderStatements.indexOf(s) + 1;
        buffer.writeln('  - $speakerPrefix: "${s.text.trim()}" (Turn $turnIndex)');
      }
    }

    // 5. Inquiries Posed in Earlier Turns (Three-state tracking)
    final inquiries = _extractInquiries(olderStatements, currentCase);
    if (inquiries.isNotEmpty) {
      buffer.writeln('\n• Inquiries Posed in Earlier Turns:');
      for (final inq in inquiries) {
        buffer.writeln('  - Inquiry: "${inq.inquiryText}" (Turn ${inq.turnIndex})');
        if (inq.subsequentUserText != null &&
            inq.resolutionState == InquiryResolutionState.responseRecordedUndetermined) {
          buffer.writeln(
              '    Subsequent User Statement: "${inq.subsequentUserText}" (Turn ${inq.subsequentUserTurnIndex})');
        }
        buffer.writeln('    Status: ${inq.resolutionState.labelText}');
      }
    }

    // 6. Candidate Hypotheses Explored (Recorded Counter-Evidence)
    if (currentCase.hypotheses.isNotEmpty) {
      buffer.writeln('\n• Candidate Hypotheses Explored (Recorded Counter-Evidence):');
      for (final h in currentCase.hypotheses) {
        buffer.writeln('  - "${h.title}": ${h.explanation}');
        if (h.whatDoesNotFit.trim().isNotEmpty) {
          buffer.writeln('    * Recorded Counter-Evidence: ${h.whatDoesNotFit.trim()}');
        }
      }
    }

    // 7. Safety Context (Elevated distress signals preserved)
    final hasDistress = olderStatements.any(
      (s) => CrisisKeywords.evaluateText(s.text) > 0,
    );
    if (hasDistress) {
      buffer.writeln('\n• Safety Context:');
      buffer.writeln(
          '  - Elevated distress noted in earlier turns. Maintain compassionate, non-rushed pacing.');
    }

    // 8. Active Conversational Focus
    buffer.writeln('\n• Active Conversational Focus:');
    buffer.writeln('  - Current Mode: ${currentCase.conversationMode.displayName}');
    buffer.writeln('  - Active Stage: ${currentCase.currentStage.title}');

    return buffer.toString().trim();
  }

  /// Extracts investigator inquiries ending with '?' or '؟' and classifies their resolution.
  static List<OlderInquiryRecord> _extractInquiries(
    List<Statement> olderStatements,
    CaseModel currentCase,
  ) {
    final results = <OlderInquiryRecord>[];
    final allStatements = currentCase.statements;

    final hasExplicitCaseResolution = (currentCase.userConclusion != null &&
            currentCase.userConclusion!.trim().isNotEmpty) ||
        (currentCase.findingsSummary != null &&
            currentCase.findingsSummary!.trim().isNotEmpty) ||
        currentCase.chain != null;

    for (int i = 0; i < olderStatements.length; i++) {
      final s = olderStatements[i];
      if (s.speaker != StatementSpeaker.investigator) continue;

      final text = s.text.trim();
      final isQuestion = text.endsWith('?') || text.endsWith('؟');
      if (!isQuestion) continue;

      // Locate subsequent user statement across all statements
      final globalIndex = allStatements.indexWhere((stmt) => stmt.id == s.id);
      Statement? subsequentUserStatement;
      int? subsequentUserTurn;

      if (globalIndex != -1) {
        for (int j = globalIndex + 1; j < allStatements.length; j++) {
          if (allStatements[j].speaker == StatementSpeaker.user) {
            subsequentUserStatement = allStatements[j];
            subsequentUserTurn = j + 1;
            break;
          }
        }
      }

      InquiryResolutionState state;
      if (hasExplicitCaseResolution) {
        state = InquiryResolutionState.explicitlyResolved;
      } else if (subsequentUserStatement != null) {
        state = InquiryResolutionState.responseRecordedUndetermined;
      } else {
        state = InquiryResolutionState.noSubsequentResponse;
      }

      results.add(
        OlderInquiryRecord(
          inquiryText: text,
          turnIndex: i + 1,
          subsequentUserText: subsequentUserStatement?.text.trim(),
          subsequentUserTurnIndex: subsequentUserTurn,
          resolutionState: state,
        ),
      );
    }

    return results;
  }
}

