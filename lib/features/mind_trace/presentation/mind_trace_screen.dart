import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/fingerprint_thread_signature.dart';
import '../controllers/mind_trace_controller.dart';
import '../domain/emotion_descriptors.dart';
import '../domain/mind_trace_model.dart';
import 'widgets/daily_mind_trace_stepper.dart';
import 'widgets/pattern_discovery_view.dart';
import 'widgets/thought_trace_detail_sheet.dart';
import 'widgets/thought_trace_timeline_view.dart';

/// The central Daily Mind Trace Screen.
///
/// Features:
/// - Three tabs: [Daily Check-in | The Thought Trace | Patterns & Milestones]
/// - Opening poetic greeting: "Every day leaves a trace. What does yours look like today?"
/// - 5-Step interactive check-in wizard (Emotions, Intensity, Mind, Body, Reflection)
/// - Dedicated completion celebration screen
/// - Editorial chronological Thought Trace archive
/// - Vercel Luxury Dark & Master Burgundy aesthetic, 0 emojis, hairline borders.
class MindTraceScreen extends ConsumerStatefulWidget {
  const MindTraceScreen({
    super.key,
    this.initialTabIndex = 0,
    this.startInEditMode = false,
  });

  final int initialTabIndex;
  final bool startInEditMode;

  @override
  ConsumerState<MindTraceScreen> createState() => _MindTraceScreenState();
}

class _MindTraceScreenState extends ConsumerState<MindTraceScreen> {
  late int _selectedTabIndex;
  bool _isEditingToday = false;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _isEditingToday = widget.startInEditMode;
  }

  @override
  Widget build(BuildContext context) {
    final tracesAsync = ref.watch(mindTraceControllerProvider);
    final todayTrace = ref.watch(todayTraceProvider);
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FingerprintThreadSignature(size: 18, animated: false),
            const SizedBox(width: 8),
            Text(
              strings.isArabic
                  ? 'أثر اليوم (MIND TRACE)'
                  : (strings.isFrench
                      ? 'EMPREINTE DU JOUR'
                      : 'DAILY MIND TRACE'),
              style: LabTheme.serifStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: textPrimary,
              ),
            ),
          ],
        ),
        actions: const [
          SupportButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Segment
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: Row(
                children: [
                  _buildNavTab(0, strings.checkInTab, isDark, textPrimary, textSecondary, borderColor),
                  const SizedBox(width: 8),
                  _buildNavTab(1, strings.constellationTab, isDark, textPrimary, textSecondary, borderColor),
                  const SizedBox(width: 8),
                  _buildNavTab(2, strings.patternsTab, isDark, textPrimary, textSecondary, borderColor),
                ],
              ),
            ),

            // Main Tab View
            Expanded(
              child: tracesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (err, _) => Center(
                  child: Text('Error: $err'),
                ),
                data: (traces) {
                  if (_selectedTabIndex == 1) {
                    return ThoughtTraceTimelineView(
                      onRecordCheckIn: () {
                        setState(() {
                          _selectedTabIndex = 0;
                          _isEditingToday = true;
                        });
                      },
                    );
                  }

                  if (_selectedTabIndex == 2) {
                    return PatternDiscoveryView(traces: traces);
                  }

                  // 0: Check-in Tab
                  return _buildCheckInTab(
                    isDark: isDark,
                    strings: strings,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    todayTrace: todayTrace,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab(
    int index,
    String label,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedTabIndex = index;
            if (index != 0) {
              _isEditingToday = false;
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? context.tokens.accentSoft
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? context.tokens.accent
                  : Colors.transparent,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0.4,
              color: isSelected ? context.tokens.accent : textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckInTab({
    required bool isDark,
    required AppStrings strings,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required MindTraceModel? todayTrace,
  }) {
    // If today is recorded and user hasn't explicitly tapped "Edit"
    if (todayTrace != null && !_isEditingToday) {
      return _buildTodayAlreadyLoggedBanner(
        isDark: isDark,
        strings: strings,
        surfaceColor: surfaceColor,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        todayTrace: todayTrace,
      );
    }

    return Column(
      children: [
        // Opening Poetic Attunement Banner
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? LabColors.nightSurface : LabColors.daylightSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? LabColors.nightBorder : LabColors.daylightBorder, width: 1),
            ),
            child: Row(
              children: [
                const FingerprintThreadSignature(size: 24, animated: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.dailyMindTraceQuote,
                    style: LabTheme.editorialSerif(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 5-Step Stepper Wizard
        Expanded(
          child: DailyMindTraceStepper(
            initialTrace: todayTrace,
            onViewConstellation: () {
              setState(() {
                _selectedTabIndex = 1;
                _isEditingToday = false;
              });
            },
            onReturnHome: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTodayAlreadyLoggedBanner({
    required bool isDark,
    required AppStrings strings,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required MindTraceModel todayTrace,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Starlight Anchor Badge
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.tokens.accentSoft,
              border: Border.all(color: context.tokens.accent, width: 1.5),
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 28,
                color: context.tokens.accent,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            strings.isArabic
                ? 'أثر اليوم مسجل بالفعل'
                : "Today's trace has been recorded.",
            textAlign: TextAlign.center,
            style: LabTheme.serifStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.isArabic
                ? 'لقد قمت بتوثيق أثرك لهذا اليوم. يمكنك مراجعة الإدخال أو تحديثه.'
                : 'Your entry for today is recorded. You can review or edit it at any time.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.4, color: textSecondary),
          ),

          const SizedBox(height: 24),

          // Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(context.tokens.cardRadius),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      (strings.isArabic
                              ? 'الحالة والمشاعر'
                              : (strings.isFrench
                                  ? 'ÉTAT ENREGISTRÉ'
                                  : 'RECORDED STATE'))
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: context.tokens.accent,
                      ),
                    ),
                    Text(
                      '${strings.moodIntensityLabel}: ${todayTrace.moodIntensity}/10',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Emotions chips
                if (todayTrace.selectedEmotions.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: todayTrace.selectedEmotions.map((e) {
                      final icon = EmotionDescriptor.iconForLabel(e);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.tokens.surfaceSecondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 12, color: context.tokens.accent),
                            const SizedBox(width: 5),
                            Text(
                              e,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                if (todayTrace.journalText != null &&
                    todayTrace.journalText!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 12),
                  Text(
                    '“${todayTrace.journalText!.trim()}”',
                    style: LabTheme.editorialSerif(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Review Entry Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.tokens.accent,
              foregroundColor: isDark ? context.tokens.background : Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
              ),
            ),
            onPressed: () {
              ThoughtTraceDetailSheet.show(
                context,
                trace: todayTrace,
                onEdit: () {
                  setState(() => _isEditingToday = true);
                },
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.visibility_outlined, size: 16),
                const SizedBox(width: 8),
                Text(
                  (strings.isArabic
                          ? 'مراجعة تفاصيل الأثر'
                          : (strings.isFrench ? 'REVOIR L’ENTRÉE' : 'REVIEW ENTRY'))
                      .toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Edit Entry Button
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: textPrimary,
              side: BorderSide(color: borderColor),
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
              ),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _isEditingToday = true);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit_note_rounded, size: 16),
                const SizedBox(width: 8),
                Text(
                  (strings.isArabic
                          ? 'تعديل تقييم اليوم'
                          : (strings.isFrench
                              ? 'MODIFIER LE BILAN DU JOUR'
                              : 'EDIT TODAY\'S CHECK-IN'))
                      .toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // View in The Thought Trace
          TextButton(
            onPressed: () {
              setState(() => _selectedTabIndex = 1);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fingerprint_rounded, size: 14, color: context.tokens.accent),
                const SizedBox(width: 6),
                Text(
                  strings.thoughtTraceTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.tokens.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
