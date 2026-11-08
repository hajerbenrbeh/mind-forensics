import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../core/safety/support_button.dart';
import '../../journey/controllers/journey_controller.dart';
import '../../journey/domain/journey_activity.dart';
import '../../support/presentation/contextual_support_sheet.dart';
import '../../support/presentation/widgets/micro_action_card.dart';
import '../../support/presentation/widgets/perspective_exploration_card.dart';

/// Inner Observatory: Primary environment for deeper psychological exploration.
///
/// Features:
/// - 4 Non-gamified sections:
///   1. Perspective Exploration (Fact vs. Assumption vs. Interpretation)
///   2. Experiments & Strategies (Behavioral activation, practical micro-steps)
///   3. Personal Discoveries (User reflection notes, insights, pattern awareness)
///   4. Symptom Exploration (Somatic & cognitive self-attunement)
/// - Top action button for immediate Contextual Support
/// - Global crisis hotline access via [SupportButton]
/// - Vercel Luxury Dark minimalist precision, 0 emojis
class InnerObservatoryScreen extends ConsumerStatefulWidget {
  const InnerObservatoryScreen({super.key});

  @override
  ConsumerState<InnerObservatoryScreen> createState() =>
      _InnerObservatoryScreenState();
}

class _InnerObservatoryScreenState extends ConsumerState<InnerObservatoryScreen> {
  int _selectedSection = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final isAr = strings.isArabic;

    final bg = isDark ? LabColors.nightBackground : LabColors.daylightBackground;
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
          strings.observatoryTitle.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            letterSpacing: 1.0,
            color: textPrimary,
          ),
        ),
        actions: [
          // Contextual Support Quick Action
          IconButton(
            tooltip: strings.contextualSupportTitle,
            icon: Icon(
              Icons.healing_outlined,
              size: 20,
              color: LabColors.sageGreen,
            ),
            onPressed: () => ContextualSupportSheet.show(context),
          ),
          const SupportButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Section Switcher Tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSectionTab(
                      index: 0,
                      label: strings.sectionPerspectiveExploration,
                      icon: Icons.psychology_outlined,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),
                    const SizedBox(width: 8),
                    _buildSectionTab(
                      index: 1,
                      label: strings.sectionExperimentsStrategies,
                      icon: Icons.lightbulb_outline_rounded,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),
                    const SizedBox(width: 8),
                    _buildSectionTab(
                      index: 2,
                      label: strings.sectionPersonalDiscoveries,
                      icon: Icons.auto_awesome_outlined,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),
                    const SizedBox(width: 8),
                    _buildSectionTab(
                      index: 3,
                      label: strings.sectionSymptomExploration,
                      icon: Icons.radar_outlined,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),
                  ],
                ),
              ),
            ),

            // Section Content Body
            Expanded(
              child: _buildSectionContent(
                isDark: isDark,
                strings: strings,
                isAr: isAr,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTab({
    required int index,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    final isSelected = _selectedSection == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedSection = index);
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF222222) : const Color(0xFFE5E7EB))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? borderColor : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? textPrimary : textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? textPrimary : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContent({
    required bool isDark,
    required AppStrings strings,
    required bool isAr,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    switch (_selectedSection) {
      case 0:
        return _buildPerspectiveExplorationView(strings, isDark, textPrimary, textSecondary);
      case 1:
        return _buildExperimentsStrategiesView(strings, isDark, textPrimary, textSecondary, surfaceColor, borderColor);
      case 2:
        return _buildPersonalDiscoveriesView(strings, isDark, textPrimary, textSecondary, surfaceColor, borderColor);
      case 3:
      default:
        return _buildSymptomExplorationView(strings, isDark, textPrimary, textSecondary, surfaceColor, borderColor);
    }
  }

  Widget _buildPerspectiveExplorationView(
    AppStrings strings,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.sectionPerspectiveExploration,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.isArabic
                ? 'استكشف الفارق بين الواقعة الملموسة، وما يقفز إليه عقلك من افتراضات وتأويلات، لاكتشاف زوايا نظر جديدة.'
                : 'Explore the difference between what actually happened and what your mind assumed, opening up grounded alternatives.',
            style: TextStyle(fontSize: 12.5, color: textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          const PerspectiveExplorationCard(),
        ],
      ),
    );
  }

  Widget _buildExperimentsStrategiesView(
    AppStrings strings,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
    Color borderColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.sectionExperimentsStrategies,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.isArabic
                ? 'استراتيجيات عملية وخطوات واقعية لكسر الجمود واستعادة التوازن اليومي بدون أي ضغط أو شعور بالذنب.'
                : 'Manageable behavioral steps and low-pressure experiments to break inertia and restore equilibrium.',
            style: TextStyle(fontSize: 12.5, color: textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          const MicroActionCard(),
        ],
      ),
    );
  }

  Widget _buildPersonalDiscoveriesView(
    AppStrings strings,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
    Color borderColor,
  ) {
    final journeyAsync = ref.watch(journeyControllerProvider);

    return journeyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, st) => Center(
        child: Text(
          strings.isArabic ? 'تعذر تحميل الاكتشافات' : 'Unable to load discoveries',
          style: TextStyle(color: textSecondary),
        ),
      ),
      data: (state) {
        final completedActivities =
            state.activities.where((a) => a.isCompleted).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.sectionPersonalDiscoveries,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.isArabic
                    ? 'أرشيف لخلاصاتك وملاحظاتك الشخصية. لا وجود لمستويات خطية؛ التقدم في الفهم النفسي مسار فريد خاص بك.'
                : 'Your archive of personal insights and reflections. No artificial levels; psychological understanding is non-linear.',
                style: TextStyle(fontSize: 12.5, color: textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              if (completedActivities.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 36,
                        color: textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        strings.isArabic ? 'لا توجد خلاصات محفوظة بعد' : 'No saved reflections yet',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.isArabic
                            ? 'كلما استكشفت زاوية نظر أو أنجزت خطوة ميكرو-بسيطة، ستظهر خلاصاتك هنا.'
                            : 'When you explore perspectives or try strategies, your personal notes will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: completedActivities.map((act) {
                    return _buildDiscoveryCard(
                      activity: act,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscoveryCard({
    required JourneyActivity activity,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: LabColors.sageGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activity.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              if (activity.completedAt != null)
                Text(
                  '${activity.completedAt!.day}/${activity.completedAt!.month}',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            activity.shortExplanation,
            style: TextStyle(
              fontSize: 11.5,
              color: textSecondary,
              height: 1.35,
            ),
          ),
          if (activity.personalNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141414) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                activity.personalNotes,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSymptomExplorationView(
    AppStrings strings,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
    Color borderColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.sectionSymptomExploration,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.isArabic
                ? 'ملاحظة العلامات الجسدية والمعرفية للضغط بدون إصدار أحكام.'
                : 'Notice somatic and cognitive distress signals with curiosity and psychological self-attunement.',
            style: TextStyle(fontSize: 12.5, color: textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.radar_outlined,
                  size: 40,
                  color: isDark ? LabColors.warmBeige : LabColors.warmBeigeDark,
                ),
                const SizedBox(height: 14),
                Text(
                  strings.isArabic ? 'فحص التناغم الذاتي السريع' : 'Self-Attunement Check',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.isArabic
                      ? 'إذا كنت تشعر بضغط أو تسارع أفكار حالياً، يمكنك فتح الدعم الفوري أو تسجيل أثر اليوم.'
                      : 'If you are experiencing elevated cognitive tension right now, access immediate contextual support.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () => ContextualSupportSheet.show(context),
                    icon: const Icon(Icons.healing_outlined, size: 16),
                    label: Text(
                      strings.contextualSupportTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textPrimary,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
