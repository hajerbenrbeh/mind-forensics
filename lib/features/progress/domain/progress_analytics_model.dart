import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../investigation/domain/case_model.dart';
import '../../journey/domain/journey_activity.dart';
import '../../mind_trace/domain/mind_trace_model.dart';

/// Available time windows for filtering psychological progress.
enum ProgressTimeWindow {
  sevenDays,
  thirtyDays,
  ninetyDays,
  allTime;

  int? get durationInDays {
    switch (this) {
      case ProgressTimeWindow.sevenDays:
        return 7;
      case ProgressTimeWindow.thirtyDays:
        return 30;
      case ProgressTimeWindow.ninetyDays:
        return 90;
      case ProgressTimeWindow.allTime:
        return null;
    }
  }

  String label(AppStrings strings) {
    switch (this) {
      case ProgressTimeWindow.sevenDays:
        return strings.isArabic ? '7 أيام' : (strings.isFrench ? '7 JOURS' : '7 DAYS');
      case ProgressTimeWindow.thirtyDays:
        return strings.isArabic ? '30 يوماً' : (strings.isFrench ? '30 JOURS' : '30 DAYS');
      case ProgressTimeWindow.ninetyDays:
        return strings.isArabic ? '90 يوماً' : (strings.isFrench ? '90 JOURS' : '90 DAYS');
      case ProgressTimeWindow.allTime:
        return strings.isArabic ? 'كامل السجل' : (strings.isFrench ? 'TOUT LE TEMPS' : 'ALL TIME');
    }
  }

  String formattedDateRange(DateTime now, AppStrings strings) {
    if (this == ProgressTimeWindow.allTime) {
      return strings.isArabic
          ? 'كامل السجل التاريخي المسجل'
          : (strings.isFrench ? 'Historique complet enregistré' : 'All recorded entries');
    }
    final days = durationInDays!;
    final startDate = now.subtract(Duration(days: days));
    final months = strings.isArabic
        ? [
            'جانفي', 'فيفري', 'مارس', 'أفريل', 'ماي', 'جوان',
            'جويلية', 'أوت', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
          ]
        : (strings.isFrench
            ? [
                'Janv', 'Févr', 'Mars', 'Avr', 'Mai', 'Juin',
                'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'
              ]
            : [
                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
              ]);

    final startStr = '${months[startDate.month - 1]} ${startDate.day}';
    final endStr = '${months[now.month - 1]} ${now.day}, ${now.year}';
    return '$startStr — $endStr';
  }
}

/// Source category for user reflections in the archive.
enum ReflectionSourceType {
  dailyTrace,
  investigation,
  journeyActivity;

  String label(AppStrings strings) {
    switch (this) {
      case ReflectionSourceType.dailyTrace:
        return strings.isArabic ? 'أثر يومي' : (strings.isFrench ? 'Trace quotidienne' : 'Daily Trace');
      case ReflectionSourceType.investigation:
        return strings.isArabic ? 'استنتاج فكري' : (strings.isFrench ? 'Recadrage cognitif' : 'Case Reframe');
      case ReflectionSourceType.journeyActivity:
        return strings.isArabic ? 'تمرين مسار' : (strings.isFrench ? 'Activité du parcours' : 'Journey Exercise');
    }
  }

  IconData get icon {
    switch (this) {
      case ReflectionSourceType.dailyTrace:
        return Icons.auto_stories_outlined;
      case ReflectionSourceType.investigation:
        return Icons.psychology_outlined;
      case ReflectionSourceType.journeyActivity:
        return Icons.explore_outlined;
    }
  }
}

/// A single user-written reflection gathered from across the application.
class SavedReflectionItem {
  const SavedReflectionItem({
    required this.id,
    required this.text,
    required this.date,
    required this.sourceType,
    required this.sourceTitle,
    this.originalTrace,
    this.originalCase,
    this.originalActivity,
  });

  final String id;
  final String text;
  final DateTime date;
  final ReflectionSourceType sourceType;
  final String sourceTitle;
  final MindTraceModel? originalTrace;
  final CaseModel? originalCase;
  final JourneyActivity? originalActivity;

  String get formattedDate {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Cumulative milestone honoring continuous self-awareness without streaks.
class ProgressMilestoneItem {
  const ProgressMilestoneItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isUnlocked,
    required this.currentValue,
    required this.targetValue,
    this.symbolName = 'Star',
  });

  final String id;
  final String title;
  final String description;
  final String category; // 'Attunement', 'Reflection', 'Exploration', 'Diversity'
  final bool isUnlocked;
  final int currentValue;
  final int targetValue;
  final String symbolName;

  double get progressRatio =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 1.0;
}

/// Transparent, local heuristic insight for self-exploration.
class PersonalInsightItem {
  const PersonalInsightItem({
    required this.id,
    required this.title,
    required this.description,
    required this.caveat,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final String caveat;
  final IconData icon;
}

/// Aggregated, derived progress analytics model computed dynamically.
class ProgressAnalyticsModel {
  const ProgressAnalyticsModel({
    required this.timeWindow,
    required this.totalEntries,
    required this.uniqueDaysCount,
    required this.totalEmotionSelections,
    required this.emotionFrequencies,
    required this.emotionalVarietyCount,
    required this.averageIntensity,
    required this.minIntensity,
    required this.maxIntensity,
    required this.intensityTimeline,
    this.averageEnergy,
    this.averageSleepDuration,
    this.averageSleepQuality,
    this.averagePhysicalTension,
    this.sleepTensionObservation,
    required this.chronologicalTraces,
    required this.allReflections,
    required this.milestones,
    required this.insights,
    required this.journeyActivitiesExplored,
    required this.totalJourneyActivities,
    required this.completedCasesCount,
  });

  final ProgressTimeWindow timeWindow;
  final int totalEntries;
  final int uniqueDaysCount;
  final int totalEmotionSelections;
  final Map<String, int> emotionFrequencies;
  final int emotionalVarietyCount;
  final double averageIntensity;
  final int minIntensity;
  final int maxIntensity;
  final List<({DateTime date, int intensity, String mood})> intensityTimeline;

  final double? averageEnergy;
  final double? averageSleepDuration;
  final double? averageSleepQuality;
  final double? averagePhysicalTension;
  final String? sleepTensionObservation;

  final List<MindTraceModel> chronologicalTraces;
  final List<SavedReflectionItem> allReflections;
  final List<ProgressMilestoneItem> milestones;
  final List<PersonalInsightItem> insights;

  final int journeyActivitiesExplored;
  final int totalJourneyActivities;
  final int completedCasesCount;

  bool get isEmpty => totalEntries == 0;
}

