import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../controllers/mind_trace_controller.dart';
import '../../domain/mind_trace_model.dart';
import '../../domain/thought_trace_investigation.dart';
import 'trace_investigation_sheet.dart';

/// Editorial detail inspector for an individual Thought Trace entry.
///
/// Displays the full thought quotation, emotional markers, somatic/cognitive metrics,
/// contextual triggers, behavioral coping, and prominent Socratic inquiry action.
class ThoughtTraceDetailSheet extends ConsumerWidget {
  const ThoughtTraceDetailSheet({
    super.key,
    required this.trace,
    this.onEdit,
  });

  final MindTraceModel trace;
  final VoidCallback? onEdit;

  static Future<void> show(
    BuildContext context, {
    required MindTraceModel trace,
    VoidCallback? onEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ThoughtTraceDetailSheet(trace: trace, onEdit: onEdit),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    final bg = tokens.surface;
    final border = tokens.border;
    final textPrimary = tokens.textPrimary;
    final textSecondary = tokens.textSecondary;

    // Format time display
    final hour = trace.createdAt.hour.toString().padLeft(2, '0');
    final minute = trace.createdAt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.cardRadius)),
        border: Border.all(color: border, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header: Date, Time & Management Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.isArabic
                            ? 'أثر الفكرة المسجل'
                            : (strings.isFrench
                                ? 'EMPREINTE DE PENSÉE'
                                : 'THOUGHT TRACE RECORD'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: tokens.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trace.dateKey} • $timeStr',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, size: 20),
                          tooltip: strings.isArabic
                              ? 'تعديل'
                              : (strings.isFrench ? 'Modifier' : 'Edit'),
                          color: tokens.accent,
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            Navigator.pop(context);
                            onEdit!();
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        tooltip: strings.isArabic
                            ? 'حذف'
                            : (strings.isFrench ? 'Supprimer' : 'Delete'),
                        color: textSecondary,
                        visualDensity: VisualDensity.compact,
                        onPressed: () async {
                          HapticFeedback.heavyImpact();
                          await ref
                              .read(mindTraceControllerProvider.notifier)
                              .deleteCheckIn(trace.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Quotation Card: Thought in Serif Italic
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.surfaceSecondary,
                  borderRadius: BorderRadius.circular(tokens.cardRadius),
                  border: Border.all(
                    color: tokens.accent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tokens.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          strings.isArabic
                              ? 'نص الفكرة المسجل'
                              : (strings.isFrench
                                  ? 'PENSÉE CONSIGNÉE'
                                  : 'CAPTURED THOUGHT'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '“${trace.thoughtPreview}”',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Mood Intensity & Emotion Badges
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: tokens.accentSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: tokens.accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${trace.overallMood.toUpperCase()} • ${trace.moodIntensity}/10',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: tokens.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (trace.isInvestigated)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tokens.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: tokens.accent.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.psychology_outlined,
                              size: 13, color: tokens.accent),
                          const SizedBox(width: 5),
                          Text(
                            strings.isArabic ? 'تم الاستكشاف' : (strings.isFrench ? 'EXPLORÉ' : 'EXPLORED'),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              if (trace.selectedEmotions.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: trace.selectedEmotions.map((emotion) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: tokens.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border, width: 0.8),
                      ),
                      child: Text(
                        emotion,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),

              // Prominent Action: "Investigate This Thought"
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    TraceInvestigationSheet.show(context, trace);
                  },
                  icon: Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: isDark ? tokens.background : Colors.white,
                  ),
                  label: Text(
                    strings.investigateThoughtBtn.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: isDark ? tokens.background : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: isDark ? tokens.background : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Context & Coping Section (Situation & Behavioral Response)
              if ((trace.situation != null && trace.situation!.trim().isNotEmpty) ||
                  (trace.behavioralResponse != null && trace.behavioralResponse!.trim().isNotEmpty)) ...[
                Text(
                  strings.isArabic ? 'السياق والاستجابة' : (strings.isFrench ? 'CONTEXTE & RÉPONSE' : 'CONTEXT & BEHAVIORAL COPING'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                if (trace.situation != null && trace.situation!.trim().isNotEmpty)
                  _buildContextBlock(
                    label: strings.isArabic
                        ? 'الموقف / المحفز'
                        : (strings.isFrench
                            ? 'SITUATION / DÉCLENCHEUR'
                            : 'SITUATION / TRIGGER'),
                    content: trace.situation!.trim(),
                    surfaceSecondary: tokens.surfaceSecondary,
                    radius: tokens.buttonRadius,
                    border: border,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                if (trace.behavioralResponse != null && trace.behavioralResponse!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildContextBlock(
                    label: strings.isArabic
                        ? 'السلوك / الاستجابة'
                        : (strings.isFrench
                            ? 'RÉPONSE COMPORTEMENTALE'
                            : 'BEHAVIORAL RESPONSE'),
                    content: trace.behavioralResponse!.trim(),
                    surfaceSecondary: tokens.surfaceSecondary,
                    radius: tokens.buttonRadius,
                    border: border,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
                const SizedBox(height: 16),
              ],

              // Somatic & Cognitive Indicators (Sleep, Energy, Tension, Clarity)
              Text(
                strings.isArabic ? 'المؤشرات الجسدية والذهنية' : (strings.isFrench ? 'INDICATEURS CORPORELS & COGNITIFS' : 'BODY & MIND INDICATORS'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tokens.surfaceSecondary,
                  borderRadius: BorderRadius.circular(tokens.cardRadius),
                  border: Border.all(color: border, width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricSnippet(
                      'ENERGY',
                      trace.energyLevel != null ? '${trace.energyLevel}/10' : '--',
                      textPrimary,
                      textSecondary,
                    ),
                    _metricSnippet(
                      'TENSION',
                      trace.physicalTension != null ? '${trace.physicalTension}/10' : '--',
                      textPrimary,
                      textSecondary,
                    ),
                    _metricSnippet(
                      'SLEEP',
                      trace.sleepHours != null ? '${trace.sleepHours}h' : '--',
                      textPrimary,
                      textSecondary,
                    ),
                    if (trace.racingThoughts != null)
                      _metricSnippet(
                        'RACING',
                        '${trace.racingThoughts}/10',
                        textPrimary,
                        textSecondary,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Socratic Investigation Answers (if previously answered)
              if (trace.investigationAnswers.isNotEmpty) ...[
                Text(
                  strings.isArabic ? 'نتائج الفحص السقراطي' : (strings.isFrench ? 'INVESTIGATION SOCRATIQUE' : 'SOCRATIC DECONSTRUCTION FINDINGS'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: tokens.accent,
                  ),
                ),
                const SizedBox(height: 8),
                ...trace.investigationAnswers.entries.map((entry) {
                  final q = ThoughtTraceInvestigation.questions
                      .cast<ThoughtTraceInvestigationQuestion?>()
                      .firstWhere((item) => item?.id == entry.key, orElse: () => null);
                  final questionTitle = q?.question ?? entry.key;

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.surfaceSecondary,
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          questionTitle,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 13,
                            color: textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // AI Observation (if available)
              if (trace.aiReflection != null && trace.aiReflection!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.accentSoft,
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                    border: Border.all(
                      color: tokens.accent.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded,
                              size: 14, color: tokens.accent),
                          const SizedBox(width: 6),
                          Text(
                            strings.isArabic ? 'ملاحظة المساعد الذكي' : (strings.isFrench ? 'Observation réflexive de l’IA' : 'AI REFLECTIVE OBSERVATION'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: tokens.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        trace.aiReflection!,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Personal Journal Notes
              if (trace.journalText != null && trace.journalText!.trim().isNotEmpty) ...[
                Text(
                  strings.isArabic ? 'يومياتك وملاحظاتك' : (strings.isFrench ? 'Journal personnel' : 'PERSONAL JOURNAL NOTES'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.surfaceSecondary,
                    borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    trace.journalText!.trim(),
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextBlock({
    required String label,
    required String content,
    required Color surfaceSecondary,
    required double radius,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceSecondary,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 12.5,
              color: textPrimary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricSnippet(
      String label, String value, Color textPrimary, Color textSecondary) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}
