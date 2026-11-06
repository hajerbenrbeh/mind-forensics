import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../core/safety/support_button.dart';
import '../../tools/presentation/tools_screen.dart';
import '../controllers/journey_controller.dart';
import '../domain/journey_activity.dart';
import '../domain/journey_phase.dart';
import '../domain/journey_state_model.dart';
import 'journey_activity_detail_screen.dart';

/// The central Journey screen for Mind Forensics.
///
/// Features:
/// - Three views: [My Journey], [My Progress], and [Forensic Lab].
/// - 5 flexible phases: Self-Discovery, Understanding Patterns, Psychological Awareness,
///   Coping & Development, Personal Growth & Maintenance.
/// - Non-judgmental progress tracking (NO recovery percentages or psychological worth scoring).
/// - Vercel Luxury Dark aesthetic, 0 emojis, hairline borders.
class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  int _selectedView = 0; // 0: My Journey, 1: My Progress, 2: Forensic Lab
  JourneyPhase _viewingPhase = JourneyPhase.phase1SelfDiscovery;

  @override
  Widget build(BuildContext context) {
    final journeyAsync = ref.watch(journeyControllerProvider);
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
          strings.myJourneyTitle.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            letterSpacing: 1.0,
            color: textPrimary,
          ),
        ),
        actions: const [
          SupportButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Segmented Switch: [My Journey | My Progress | Forensic Lab]
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: surfaceColor,
                border:
                    Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: Row(
                children: [
                  _buildSegmentTab(
                    index: 0,
                    label: strings.myJourneyTitle,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),
                  const SizedBox(width: 8),
                  _buildSegmentTab(
                    index: 1,
                    label: strings.myProgressTab,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),
                  const SizedBox(width: 8),
                  _buildSegmentTab(
                    index: 2,
                    label: strings.toolkitLabTab,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: _selectedView == 2
                  ? const ToolsScreen()
                  : journeyAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (err, _) => Center(
                        child: Text('Error loading journey: $err'),
                      ),
                      data: (journey) {
                        if (_selectedView == 1) {
                          return _buildProgressView(
                            journey: journey,
                            isDark: isDark,
                            strings: strings,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          );
                        }

                        return _buildJourneyExplorerView(
                          journey: journey,
                          isDark: isDark,
                          strings: strings,
                          surfaceColor: surfaceColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab({
    required int index,
    required String label,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    final isSelected = _selectedView == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedView = index);
        },
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF222222) : const Color(0xFFE4E4E7))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : Colors.transparent,
              width: 0.8,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? textPrimary : textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyExplorerView({
    required JourneyStateModel journey,
    required bool isDark,
    required AppStrings strings,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final activePhaseActivities = journey.getActivitiesForPhase(_viewingPhase);
    final completedCount =
        activePhaseActivities.where((a) => a.isCompleted).length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Horizontal Phase Slider Pills
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: JourneyPhase.values.length,
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final phase = JourneyPhase.values[index];
              final isSelected = _viewingPhase == phase;
              final isCurrent = journey.activePhase == phase;

              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _viewingPhase = phase);
                },
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? const Color(0xFF202020)
                            : const Color(0xFFE4E4E7))
                        : (isDark
                            ? const Color(0xFF0F0F0F)
                            : const Color(0xFFFAFAFA)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : borderColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCurrent) ...[
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: LabColors.sageGreenGlow,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        'P${phase.phaseNumber}: ${phase.defaultTitle()}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? textPrimary : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // Phase Summary & Clinical Purpose Banner
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.phaseTitle(_viewingPhase).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    '$completedCount/${activePhaseActivities.length} ${strings.isArabic ? 'مكتمل' : 'completed'}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: LabColors.sageGreenGlow,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                strings.phasePurpose(_viewingPhase),
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              if (journey.activePhase != _viewingPhase) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(journeyControllerProvider.notifier)
                        .setActivePhase(_viewingPhase);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF161616)
                          : const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      strings.isArabic
                          ? 'تعيين كمرحلة استكشاف نشطة'
                          : (strings.isFrench
                              ? 'Définir comme phase active'
                              : 'Set as active focus phase'),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Activity Cards List
        ...activePhaseActivities.map((activity) {
          return _buildActivityCard(
            activity: activity,
            isDark: isDark,
            strings: strings,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          );
        }),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActivityCard({
    required JourneyActivity activity,
    required bool isDark,
    required AppStrings strings,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final hasReflections = activity.reflectionAnswers.isNotEmpty ||
        activity.personalNotes.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => JourneyActivityDetailScreen(activity: activity),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: activity.isCompleted
                  ? (isDark ? LabColors.sageGreenGlow.withValues(alpha: 0.4) : const Color(0xFF047857))
                  : borderColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      activity.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: activity.isCompleted
                          ? LabColors.sageBackground(isDark: isDark)
                          : (isDark
                              ? const Color(0xFF141414)
                              : const Color(0xFFF4F4F5)),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: activity.isCompleted
                            ? LabColors.sageGreenGlow
                            : borderColor,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          activity.isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.arrow_forward_rounded,
                          size: 11,
                          color: activity.isCompleted
                              ? LabColors.sageGreenGlow
                              : textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity.isCompleted
                              ? strings.activityCompletedBadge
                              : strings.activityInProgressBadge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: activity.isCompleted
                                ? LabColors.sageGreenGlow
                                : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                activity.purpose,
                style: TextStyle(
                  fontSize: 11.5,
                  color: textSecondary,
                  height: 1.35,
                ),
              ),
              if (hasReflections) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 12,
                      color: LabColors.warmBeige,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      strings.isArabic ? 'تم تدوين استبصاراتك' : (strings.isFrench ? 'Réflexion consignée' : 'Reflection recorded'),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: LabColors.warmBeige,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressView({
    required JourneyStateModel journey,
    required bool isDark,
    required AppStrings strings,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final completed = journey.activities.where((a) => a.isCompleted).toList();
    final reflectionsCount = journey.activities
        .where((a) =>
            a.reflectionAnswers.isNotEmpty || a.personalNotes.isNotEmpty)
        .length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Non-judgmental Clinical Notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: LabColors.warmBeige),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.nonJudgmentalNotice,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Summary Metric Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: strings.totalCompletedActivities,
                value: '${completed.length}',
                subtitle: strings.isArabic ? 'نشاط مستكشف' : 'activities',
                isDark: isDark,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: strings.totalReflectionsLogged,
                value: '$reflectionsCount',
                subtitle: strings.isArabic ? 'تأمل مسجل' : 'reflections',
                isDark: isDark,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Completed Activities Section
        Text(
          strings.isArabic ? 'محطات الاستبصار المكتملة' : (strings.isFrench ? 'ÉTAPES CONSIGNÉES' : 'COMPLETED MILESTONES'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 10),

        if (completed.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              strings.isArabic
                  ? 'لم تقم بتعليم أي نشاط كمكتمل بعد. استكشف الأنشطة بحرية في تبويب "رحلتي النفسية".'
                  : (strings.isFrench
                      ? 'Aucune activité complétée pour l’instant. Explorez librement vos activités.'
                      : 'No activities marked completed yet. Explore freely under "My Journey".'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          )
        else
          ...completed.map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          JourneyActivityDetailScreen(activity: activity),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 16, color: LabColors.sageGreenGlow),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Phase ${activity.phase.phaseNumber} — ${activity.phase.defaultTitle()}',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 16, color: textSecondary),
                    ],
                  ),
                ),
              ),
            );
          }),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
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
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
