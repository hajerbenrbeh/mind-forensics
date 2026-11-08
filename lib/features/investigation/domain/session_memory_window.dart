import 'statement.dart';

/// Represents a partitioned conversational session:
/// - [verbatimStatements]: The recent reciprocal statements kept verbatim.
/// - [olderStatements]: Statements that have moved outside the verbatim window.
/// - [sessionSummary]: The deterministically recomputed summary of older statements.
class SessionMemoryWindow {
  const SessionMemoryWindow({
    required this.olderStatements,
    required this.verbatimStatements,
    this.sessionSummary,
  });

  /// Chronologically earlier statements that have rolled out of the verbatim window.
  final List<Statement> olderStatements;

  /// Recent statements preserved verbatim for immediate conversational reciprocity.
  final List<Statement> verbatimStatements;

  /// Deterministically recomputed summary of [olderStatements].
  final String? sessionSummary;

  /// Whether there is historical context that has rolled out of the verbatim window.
  bool get hasOlderContext =>
      olderStatements.isNotEmpty &&
      sessionSummary != null &&
      sessionSummary!.trim().isNotEmpty;

  /// Total count of all statements represented across the window.
  int get totalStatementCount => olderStatements.length + verbatimStatements.length;
}

/// Boundary manager enforcing conversational turn-pair reciprocity and contiguous block preservation.
///
/// Invariant: A partition boundary must never separate directly connected conversational exchanges.
class SessionMemoryWindowManager {
  /// Default nominal verbatim window size.
  static const int kDefaultNominalWindowSize = 6;

  /// Computes the split boundary index within [statements].
  ///
  /// Statements with index `< boundary` belong to [olderStatements].
  /// Statements with index `>= boundary` belong to [verbatimStatements].
  ///
  /// Guarantees:
  /// - Nominal size of [nominalSize] is a target baseline, not a hard cap.
  /// - Contiguous blocks from the same speaker are preserved intact.
  /// - Connected User <-> Investigator exchanges are kept together.
  /// - Never discards, duplicates, or reorders statements.
  static int computeBoundaryIndex(
    List<Statement> statements, {
    int nominalSize = kDefaultNominalWindowSize,
  }) {
    final n = statements.length;
    if (n <= nominalSize) {
      return 0;
    }

    // 1. Initial proposed boundary
    int boundary = n - nominalSize;

    // 2. If the boundary lands inside a contiguous block of messages from the same speaker,
    // move backward to the start of that speaker's contiguous block.
    while (boundary > 0 &&
        statements[boundary - 1].speaker == statements[boundary].speaker) {
      boundary--;
    }

    // 3. Turn-pair reciprocal coherence:
    // If the statement at boundary is a direct response to the preceding statement
    // (i.e. different speaker), move boundary backward to include the prompting statement.
    if (boundary > 0) {
      final currentSpeaker = statements[boundary].speaker;
      final previousSpeaker = statements[boundary - 1].speaker;

      if (currentSpeaker != previousSpeaker) {
        boundary--;

        // If the prompting statement was itself part of a contiguous speaker block,
        // move backward to include that entire contiguous block.
        while (boundary > 0 &&
            statements[boundary - 1].speaker == statements[boundary].speaker) {
          boundary--;
        }
      }
    }

    return boundary.clamp(0, n);
  }

  /// Partitions [statements] into a [SessionMemoryWindow].
  static SessionMemoryWindow partition(
    List<Statement> statements, {
    int nominalSize = kDefaultNominalWindowSize,
    String? existingSummary,
  }) {
    if (statements.isEmpty) {
      return const SessionMemoryWindow(
        olderStatements: [],
        verbatimStatements: [],
        sessionSummary: null,
      );
    }

    final boundary = computeBoundaryIndex(statements, nominalSize: nominalSize);

    if (boundary == 0) {
      return SessionMemoryWindow(
        olderStatements: const [],
        verbatimStatements: List.unmodifiable(statements),
        sessionSummary: null,
      );
    }

    final older = statements.sublist(0, boundary);
    final verbatim = statements.sublist(boundary);

    return SessionMemoryWindow(
      olderStatements: List.unmodifiable(older),
      verbatimStatements: List.unmodifiable(verbatim),
      sessionSummary: existingSummary,
    );
  }
}

