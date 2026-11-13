import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../controllers/journey_controller.dart';
import '../domain/journey_activity.dart';

/// Detailed view for an individual psychological journey activity.
///
/// Fully satisfies the user specification:
/// 1. Title
/// 2. Purpose
/// 3. Short explanation
/// 4. Guided instructions
/// 5. Reflection questions (with interactive answer inputs)
/// 6. Completion status
/// 7. Optional personal notes
class JourneyActivityDetailScreen extends ConsumerStatefulWidget {
  const JourneyActivityDetailScreen({
    super.key,
    required this.activity,
  });

  final JourneyActivity activity;

  @override
  ConsumerState<JourneyActivityDetailScreen> createState() =>
      _JourneyActivityDetailScreenState();
}

class _JourneyActivityDetailScreenState
    extends ConsumerState<JourneyActivityDetailScreen> {
  late TextEditingController _notesController;
  final Map<int, TextEditingController> _questionControllers = {};
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _notesController =
        TextEditingController(text: widget.activity.personalNotes);
    _isCompleted = widget.activity.isCompleted;

    for (var i = 0; i < widget.activity.reflectionQuestions.length; i++) {
      final qKey = 'q_$i';
      final initialAnswer = widget.activity.reflectionAnswers[qKey] ?? '';
      _questionControllers[i] = TextEditingController(text: initialAnswer);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final c in _questionControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveReflection() async {
    HapticFeedback.mediumImpact();
    final answers = <String, String>{};
    for (final entry in _questionControllers.entries) {
      final text = entry.value.text.trim();
      if (text.isNotEmpty) {
        answers['q_${entry.key}'] = text;
      }
    }

    await ref.read(journeyControllerProvider.notifier).saveActivityReflection(
          activityId: widget.activity.id,
          personalNotes: _notesController.text.trim(),
          reflectionAnswers: answers,
          markCompleted: _isCompleted,
        );

    if (mounted) {
      final strings = ref.read(appStringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? LabColors.nightSurface
              : LabColors.daylightSurface,
          content: Text(
            strings.reflectionSavedSnackbar,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? LabColors.nightTextPrimary
                  : LabColors.daylightTextPrimary,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? LabColors.nightBorder
                  : LabColors.daylightBorder,
            ),
          ),
        ),
      );
    }
  }

  void _toggleCompleted() {
    HapticFeedback.selectionClick();
    setState(() => _isCompleted = !_isCompleted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);

    final bg =
        isDark ? LabColors.nightBackground : LabColors.daylightBackground;
    final surfaceColor =
        isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final borderColor =
        isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary =
        isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary =
        isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          strings.phaseTitle(widget.activity.phase).toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1.0,
            color: textSecondary,
          ),
        ),
        actions: const [
          SupportButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Status and Phase indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.tokens.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Text(
                    'PHASE ${widget.activity.phase.phaseNumber}',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: textSecondary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _toggleCompleted,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isCompleted
                          ? context.tokens.accentSoft
                          : context.tokens.surfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isCompleted
                            ? context.tokens.accent
                            : borderColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 13,
                          color: _isCompleted
                              ? LabColors.sageGreenGlow
                              : textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isCompleted
                              ? strings.activityCompletedBadge
                              : strings.activityInProgressBadge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _isCompleted
                                ? LabColors.sageGreenGlow
                                : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 1. Title
            Text(
              widget.activity.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 12),

            // 2. Purpose Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.isArabic ? 'الهدف السريري من النشاط' : (strings.isFrench ? 'Objectif clinique' : 'CLINICAL PURPOSE'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: LabColors.sageGreenGlow,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.activity.purpose,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. Short Explanation
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.tokens.surfaceSecondary,
                borderRadius: BorderRadius.circular(context.tokens.cardRadius),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Text(
                widget.activity.shortExplanation,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  height: 1.45,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 4. Guided Instructions
            Text(
              strings.guidedInstructionsTitle.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            ...widget.activity.guidedInstructions.asMap().entries.map((entry) {
              final stepIndex = entry.key + 1;
              final instruction = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFFE4E4E7),
                          border: Border.all(color: borderColor, width: 0.8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$stepIndex',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          instruction,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // 5. Reflection Questions
            Text(
              strings.reflectionQuestionsTitle.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            ...widget.activity.reflectionQuestions.asMap().entries.map((entry) {
              final qIndex = entry.key;
              final question = entry.value;
              final controller = _questionControllers[qIndex]!;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            size: 15,
                            color: LabColors.warmBeige,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              question,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: controller,
                        maxLines: 3,
                        style: TextStyle(fontSize: 12.5, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: strings.isArabic
                              ? 'دوّن تأملك الصادق هنا...'
                              : (strings.isFrench
                                  ? 'Notez votre observation...'
                                  : 'Write your honest reflection...'),
                          hintStyle: TextStyle(
                            fontSize: 11.5,
                            color: textSecondary.withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: context.tokens.surfaceSecondary,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: borderColor, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: borderColor, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: context.tokens.accent, width: 1.2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            // 7. Optional Personal Notes
            Text(
              strings.personalNotesLabel.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: TextStyle(fontSize: 12.5, color: textPrimary),
              decoration: InputDecoration(
                hintText: strings.isArabic
                    ? 'أي ملاحظات إضافية، أفكار خطر ببالك، أو استنتاجات تود تذكرها...'
                    : (strings.isFrench
                        ? 'Remarques additionnelles ou prises de conscience...'
                        : 'Any additional personal notes, takeaways, or insights...'),
                hintStyle: TextStyle(
                  fontSize: 11.5,
                  color: textSecondary.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: context.tokens.surfaceSecondary,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.tokens.accent, width: 1.2),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            BouncingWidget(
              onTap: _saveReflection,
              child: Container(
                width: double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  color: context.tokens.accent,
                  borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
                ),
                alignment: Alignment.center,
                child: Text(
                  strings.saveReflectionBtn,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isDark ? context.tokens.background : Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: _isCompleted
                      ? LabColors.sageGreenGlow
                      : textSecondary,
                  visualDensity: VisualDensity.compact,
                ),
                icon: Icon(
                  _isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 15,
                ),
                label: Text(
                  _isCompleted
                      ? strings.activityCompletedBadge
                      : strings.markAsCompletedBtn,
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  _toggleCompleted();
                  _saveReflection();
                },
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

