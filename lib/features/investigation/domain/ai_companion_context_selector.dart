import '../../insights/data/pattern_awareness_service.dart';
import '../../insights/domain/personal_baseline_model.dart';
import '../../journal/domain/journal_memory_model.dart';
import '../../journey/domain/journey_state_model.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../profile/domain/psychological_profile_model.dart';

/// Context selection and personalization engine for the AI Companion.
///
/// Principles (Step 3.1 & Session 05):
/// 1. Strict user consent: If [PsychologicalProfileModel.shareWithAiCompanion] or
///    [PsychologicalProfileModel.allowAiPersonalization] is false, NO profile,
///    trace, or baseline data is injected.
/// 2. Context minimalism & Data Integrity: Only transmits relevant, un-identifying
///    psychological context. Calculates each baseline metric independently.
/// 3. Zero Fabrication: Never manufactures missing data or interprets missing
///    observations as normal.
/// 4. Privacy & Raw Journal Protection: Raw journal texts are NEVER passed to the AI.
/// 5. Non-clinical Guardrails: Communicates statistical shifts as observations,
///    never diagnoses or relapse predictions.
class AiCompanionContextSelector {
  /// Builds a sanitized, privacy-compliant contextual prompt snippet.
  static String buildContext({
    required PsychologicalProfileModel? profile,
    required MindTraceModel? latestTrace,
    List<MindTraceModel>? historicalTraces,
    required JourneyStateModel? journey,
    List<JournalMemoryModel>? compressedMemories,
    bool forceDisablePersonalization = false,
  }) {
    // 1. Consent Gate: Strict enforcement of user privacy
    final hasConsent = profile != null &&
        profile.shareWithAiCompanion &&
        profile.allowAiPersonalization;

    if (forceDisablePersonalization || !hasConsent) {
      return '';
    }

    final buffer = StringBuffer();

    // 2. Profile Context (explicitly shared by user)
    if (!profile.isEmpty) {
      buffer.writeln('USER PROFILE CONTEXT (Explicitly shared by user):');

      if (profile.preferredName.trim().isNotEmpty) {
        buffer.writeln('• Preferred Name: ${profile.preferredName.trim()}');
      }

      if (profile.conditions.isNotEmpty) {
        buffer.writeln('• Selected Experiences & Conditions:');
        for (final entry in profile.conditions) {
          buffer.writeln(
            '  - ${entry.condition.defaultDisplayName()} [Status: ${entry.status.defaultDisplayName()}]'
            '${entry.note.isNotEmpty ? ' (Context: ${entry.note})' : ''}',
          );
        }
      }

      if (profile.selectedSymptoms.isNotEmpty) {
        buffer.writeln('• Current Symptoms & Difficulties: ${profile.selectedSymptoms.join(", ")}');
      } else if (profile.symptomsAndExperiences.trim().isNotEmpty) {
        buffer.writeln('• Current Difficulties: ${profile.symptomsAndExperiences.trim()}');
      }

      if (profile.selectedGoals.isNotEmpty) {
        buffer.writeln('• Personal Goals: ${profile.selectedGoals.join(", ")}'
            '${profile.customGoal.isNotEmpty ? ", ${profile.customGoal}" : ""}');
      } else if (profile.personalGoals.trim().isNotEmpty) {
        buffer.writeln('• Personal Goals: ${profile.personalGoals.trim()}');
      }

      if (profile.personalContext.trim().isNotEmpty) {
        buffer.writeln('• What user wants companion to understand: "${profile.personalContext.trim()}"');
      } else if (profile.notesForAiCompanion.trim().isNotEmpty) {
        buffer.writeln('• Message to companion: "${profile.notesForAiCompanion.trim()}"');
      }

      buffer.writeln('• Communication Preferences:');
      buffer.writeln('  - Tone: ${profile.communicationTone}');
      buffer.writeln('  - Response Length: ${profile.responseLength}');
      if (profile.distressPreferences.isNotEmpty) {
        buffer.writeln('  - Distress Preference: ${profile.distressPreferences.join(", ")}');
      }
      if (profile.dislikedApproaches.isNotEmpty) {
        buffer.writeln('  - Disliked Styles: ${profile.dislikedApproaches.join(", ")}');
      }

      if (profile.customAiDirectives.trim().isNotEmpty) {
        buffer.writeln('• Custom User Directives: "${profile.customAiDirectives.trim()}"');
      }
    }

    // 3. Daily Mind Trace Context (Latest Check-in: Aggregated indicators only)
    if (latestTrace != null && latestTrace.isCompleted) {
      buffer.writeln('\nDAILY MIND TRACE (Recent Check-in):');
      buffer.writeln('• Overall Mood: ${latestTrace.overallMood} (Intensity: ${latestTrace.moodIntensity}/10)');
      if (latestTrace.selectedEmotions.isNotEmpty) {
        buffer.writeln('• Emotions Recorded: ${latestTrace.selectedEmotions.join(", ")}');
      }
      if (latestTrace.energyLevel != null && latestTrace.energyLevel! >= 1 && latestTrace.energyLevel! <= 10) {
        buffer.writeln('• Energy Level: ${latestTrace.energyLevel}/10');
      }
      if (latestTrace.sleepHours != null && latestTrace.sleepHours! >= 0) {
        buffer.writeln('• Sleep Duration: ${latestTrace.sleepHours} hours');
      }
      if (latestTrace.physicalTension != null && latestTrace.physicalTension! >= 0) {
        buffer.writeln('• Physical Tension: ${latestTrace.physicalTension}/10');
      }
      if (latestTrace.anxietyLevel != null && latestTrace.anxietyLevel! >= 0) {
        buffer.writeln('• Anxiety Level: ${latestTrace.anxietyLevel}/10');
      }
      // Note: Raw journalText is strictly excluded to protect personal reflections.
    }

    // 4. Personal Baseline & Longitudinal Pattern Context
    if (historicalTraces != null && historicalTraces.isNotEmpty) {
      final baseline = PersonalBaseline.fromTraces(historicalTraces);

      if (!baseline.hasSufficientData) {
        buffer.writeln('\nPERSONAL BASELINE STATUS:');
        buffer.writeln('• Status: Calibrating (${baseline.totalRecordedDays}/3 days observed).');
        buffer.writeln('• Constraint: Insufficient longitudinal data. Do not make claims about the user\'s usual baseline, normal levels, or recurring patterns.');
      } else {
        final baselineClassification = baseline.hasEstablishedBaseline
            ? 'Established Longitudinal Baseline (>= 14 distinct days)'
            : 'Preliminary Observations (Calibrating toward 14-day established baseline)';
        buffer.writeln('\nPERSONAL BASELINE (Self-Reported ${baseline.totalRecordedDays}-Day History):');
        buffer.writeln('• Observation Depth: $baselineClassification (${baseline.totalRecordedDays} logged days)');

        // Sleep metric (independent)
        if (baseline.hasSleepData && baseline.averageSleepHours != null) {
          final medSleep = baseline.medianSleepHours ?? baseline.averageSleepHours!;
          buffer.writeln('• Sleep: Average ${baseline.averageSleepHours!.toStringAsFixed(1)}h, Median ${medSleep.toStringAsFixed(1)}h (${baseline.sleepObservationCount} nights recorded)');
        } else if (baseline.sleepObservationCount == 0) {
          buffer.writeln('• Sleep: Not tracked (0 recorded entries). Do not make claims about sleep patterns or assume typical sleep.');
        } else {
          buffer.writeln('• Sleep: Calibrating (${baseline.sleepObservationCount}/3 nights recorded). Insufficient data to determine baseline.');
        }

        // Energy metric (independent)
        if (baseline.hasEnergyData && baseline.averageEnergyLevel != null) {
          final medEnergy = baseline.medianEnergyLevel ?? baseline.averageEnergyLevel!;
          buffer.writeln('• Energy Level: Average ${baseline.averageEnergyLevel!.toStringAsFixed(1)}/10, Median ${medEnergy.toStringAsFixed(1)}/10 (${baseline.energyObservationCount} entries recorded)');
        } else if (baseline.energyObservationCount == 0) {
          buffer.writeln('• Energy Level: Not tracked (0 recorded entries). Do not make claims about typical energy.');
        } else {
          buffer.writeln('• Energy Level: Calibrating (${baseline.energyObservationCount}/3 entries recorded). Insufficient data to determine baseline.');
        }

        // Mood Intensity metric (independent)
        if (baseline.hasMoodData && baseline.averageMoodIntensity != null) {
          final medMood = baseline.medianMoodIntensity ?? baseline.averageMoodIntensity!;
          buffer.writeln('• Mood Intensity: Average ${baseline.averageMoodIntensity!.toStringAsFixed(1)}/10, Median ${medMood.toStringAsFixed(1)}/10 (${baseline.moodObservationCount} entries recorded)');
        }

        // Anxiety / Stress metric (independent)
        if (baseline.hasAnxietyData && baseline.averageAnxietyLevel != null) {
          buffer.writeln('• Anxiety / Stress: Average ${baseline.averageAnxietyLevel!.toStringAsFixed(1)}/10 (${baseline.anxietyObservationCount} entries recorded)');
        }

        // Physical Tension metric (independent)
        if (baseline.hasTensionData && baseline.averageTensionLevel != null) {
          buffer.writeln('• Physical Tension: Average ${baseline.averageTensionLevel!.toStringAsFixed(1)}/10 (${baseline.tensionObservationCount} entries recorded)');
        }

        // Frequently Logged Triggers
        if (baseline.recurringTriggers.isNotEmpty) {
          buffer.writeln('• Frequently Logged Triggers: ${baseline.recurringTriggers.join(", ")}');
        }

        // Meaningful Divergences
        final divergences = PatternAwarenessService.detectDivergences(
          traces: historicalTraces,
          baseline: baseline,
        );

        if (divergences.isNotEmpty) {
          buffer.writeln('• Notable Multi-Day Shifts in Recent Data:');
          for (final div in divergences) {
            buffer.writeln('  - ${div.title} (${div.timeWindow}): ${div.baselineComparison}');
            buffer.writeln('    Observations: ${div.contributingObservations.join("; ")}');
          }
          buffer.writeln('• Mandatory Rule: Frame any shift strictly as a self-reported difference in logged data, never as a clinical diagnosis, episode confirmation, or relapse prediction. Always incorporate uncertainty and ask how the user feels.');
        } else {
          buffer.writeln('• Recent Patterns: Consistent with available baseline observations.');
        }
      }
    }

    // 5. Psychological Journey Context
    if (journey != null) {
      buffer.writeln('\nPSYCHOLOGICAL JOURNEY:');
      buffer.writeln('• Active Phase: Phase ${journey.activePhase.phaseNumber} (${journey.activePhase.defaultTitle()})');
      final completed = journey.activities.where((a) => a.isCompleted).toList();
      if (completed.isNotEmpty) {
        buffer.writeln('• Completed Exploration Activities:');
        for (final act in completed.take(2)) {
          buffer.writeln('  - "${act.title}"');
        }
      }
    }

    // 6. Compressed Journal Memory (Compact historical context & recurring themes)
    // Critical (Step 3.2): Strictly confirmed memories only. Unreviewed, rejected,
    // and archived memories are completely excluded from AI Companion context.
    if (compressedMemories != null && compressedMemories.isNotEmpty) {
      final activeMemories = compressedMemories
          .where((m) =>
              m.confirmationStatus == MemoryConfirmationStatus.confirmed &&
              !m.isArchived)
          .take(4)
          .toList();

      if (activeMemories.isNotEmpty) {
        buffer.writeln('\nCOMPRESSED JOURNAL MEMORY (Self-Reported Themes & Context):');
        for (final mem in activeMemories) {
          buffer.writeln('• [User-Confirmed] ${mem.summary} (${mem.observationCount} observations)');
        }
        buffer.writeln('• Memory Safety Rule: Treat user-stated items as personal reflections. Treat tentative hypotheses with curiosity and uncertainty, never as established causes, objective facts, or clinical diagnoses.');
      }
    }

    return buffer.toString().trim();
  }
}
