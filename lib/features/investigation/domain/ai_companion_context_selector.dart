import '../../journey/domain/journey_state_model.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../profile/domain/psychological_profile_model.dart';

/// Context selection and personalization engine for the AI Companion.
///
/// Principles (Session 05 Part 6):
/// 1. Strict user consent: if [PsychologicalProfileModel.shareWithAiCompanion] is false,
///    no profile data is injected.
/// 2. Context minimalism: Only passes relevant, un-identifying psychological context.
/// 3. Transparent provenance: Clearly distinguishes user-reported data from AI analysis.
class AiCompanionContextSelector {
  /// Builds a sanitized, privacy-compliant contextual prompt snippet.
  static String buildContext({
    required PsychologicalProfileModel? profile,
    required MindTraceModel? latestTrace,
    required JourneyStateModel? journey,
    bool forceDisablePersonalization = false,
  }) {
    if (forceDisablePersonalization) {
      return '';
    }

    final buffer = StringBuffer();

    // 1. Profile Context (strictly gated by shareWithAiCompanion)
    final hasConsent = profile != null && profile.shareWithAiCompanion && !profile.isEmpty;
    if (hasConsent) {
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

    // 2. Daily Mind Trace Context (Recent 24-48 hours)
    if (latestTrace != null && latestTrace.isCompleted) {
      buffer.writeln('\nDAILY MIND TRACE (Recent Check-in):');
      buffer.writeln('• Overall Mood: ${latestTrace.overallMood} (Intensity: ${latestTrace.moodIntensity}/10)');
      if (latestTrace.selectedEmotions.isNotEmpty) {
        buffer.writeln('• Emotions Recorded: ${latestTrace.selectedEmotions.join(", ")}');
      }
      if (latestTrace.energyLevel > 0) {
        buffer.writeln('• Energy Level: ${latestTrace.energyLevel}/10');
      }
      if (latestTrace.sleepHours != null && latestTrace.sleepHours! > 0) {
        buffer.writeln('• Sleep Duration: ${latestTrace.sleepHours} hours');
      }
      if (latestTrace.physicalTension != null && latestTrace.physicalTension! > 0) {
        buffer.writeln('• Physical Tension: ${latestTrace.physicalTension}/10');
      }
      if (latestTrace.journalText != null && latestTrace.journalText!.trim().isNotEmpty) {
        final journalSnippet = latestTrace.journalText!.trim();
        final truncated = journalSnippet.length > 200
            ? '${journalSnippet.substring(0, 200)}...'
            : journalSnippet;
        buffer.writeln('• Today\'s Written Reflection: "$truncated"');
      }
    }

    // 3. Journey Context
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

    return buffer.toString().trim();
  }
}
