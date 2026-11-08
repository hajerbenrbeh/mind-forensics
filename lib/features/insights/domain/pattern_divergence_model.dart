import 'package:flutter/foundation.dart';

enum DivergenceCategory {
  elevatedActivation,
  lowActivation,
  elevatedTension,
  sleepDisruption,
  generalVariation,
}

/// Distinguishes the scope and nature of an observed difference.
enum ObservationType {
  /// A difference observed in a single metric (e.g. sleep duration shifted, energy shifted).
  individualMetricShift,

  /// A co-occurring difference across two or more metrics (e.g. reduced sleep co-occurring with elevated energy).
  combinedMetricShift,

  /// A repeated pattern sustained across multiple check-ins (e.g. tension elevated across multiple distinct days).
  longitudinalPattern,
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
    this.observationType = ObservationType.individualMetricShift,
    required this.detectedAt,
  });

  final String id;
  final DivergenceCategory category;
  final ObservationType observationType;
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

