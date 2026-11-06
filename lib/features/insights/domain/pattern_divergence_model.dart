import 'package:flutter/foundation.dart';

enum DivergenceCategory {
  elevatedActivation,
  lowActivation,
  elevatedTension,
  sleepDisruption,
  generalVariation,
}

/// An evidence-based pattern observation comparing recent entries to the user's baseline.
///
/// Mandated clinical boundaries (Part 7.2 & AGENTS.md):
/// 1. Explains which observations contributed with direct citations.
/// 2. Shows the relevant time period.
/// 3. Compares observations against the user's personal baseline.
/// 4. Communicates uncertainty explicitly.
/// 5. Asks whether the user recognizes this change.
/// 6. Suggests reviewing their personal support / early-warning plan.
/// 7. Encourages professional assessment when appropriate.
/// 8. NEVER labels as confirmed manic, hypomanic, or depressive episodes.
/// 9. NEVER predicts relapse.
/// 10. NEVER infers medical diagnoses from symptoms.
@immutable
class PatternDivergence {
  const PatternDivergence({
    required this.id,
    required this.category,
    required this.title,
    required this.timeWindow,
    required this.contributingObservations,
    required this.baselineComparison,
    required this.uncertaintyStatement,
    required this.userCheckInQuestion,
    required this.supportPlanPrompt,
    this.therapistPrompt,
    required this.detectedAt,
  });

  final String id;
  final DivergenceCategory category;
  final String title;
  final String timeWindow;
  final List<String> contributingObservations;
  final String baselineComparison;
  final String uncertaintyStatement;
  final String userCheckInQuestion;
  final String supportPlanPrompt;
  final String? therapistPrompt;
  final DateTime detectedAt;
}

