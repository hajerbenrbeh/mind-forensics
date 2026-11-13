import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/neural_brain_wireframe.dart';
import '../../journey/controllers/journey_controller.dart';
import '../../journey/domain/journey_activity.dart';
import '../../support/presentation/contextual_support_sheet.dart';
import '../../support/presentation/widgets/micro_action_card.dart';
import '../../support/presentation/widgets/perspective_exploration_card.dart';
import '../../support/presentation/widgets/routine_anchor_card.dart';
import 'widgets/add_discovery_sheet.dart';
import 'widgets/longitudinal_analysis_view.dart';
import 'widgets/symptom_library_view.dart';

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
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Top Phone 5 Hero Banner (3D Neural Brain & Exploration Cards)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _buildPhone5Hero(isDark, textPrimary, textSecondary),
              ),
            ),

            // Section Switcher Tabs
            SliverToBoxAdapter(
              child: Container(
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
                      const SizedBox(width: 8),
                      _buildSectionTab(
                        index: 4,
                        label: isAr ? 'التحليل الطولي والأنماط' : 'Longitudinal & Patterns',
                        icon: Icons.insights_outlined,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        borderColor: borderColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Section Content Body
          body: _buildSectionContent(
            isDark: isDark,
            strings: strings,
            isAr: isAr,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPhone5Hero(bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: LabColors.forestGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: LabColors.forestGreen.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Inner Observatory',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: LabColors.warmIvory,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'A deeper look into your mind',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: LabColors.warmIvory.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 110,
            child: NeuralBrainWireframe(size: 110),
          ),
          const SizedBox(height: 12),
          // 3 Phone 5 Exploration Cards
          _buildHeroExplorationCard(
            title: 'Thought Patterns',
            subtitle: 'Explore recurring thoughts',
            icon: Icons.lightbulb_outline,
            isSelected: _selectedSection == 0,
            onTap: () => setState(() => _selectedSection = 0),
          ),
          const SizedBox(height: 6),
          _buildHeroExplorationCard(
            title: 'Emotional Landscape',
            subtitle: 'Understand your emotions',
            icon: Icons.favorite_border_rounded,
            isSelected: _selectedSection == 3,
            onTap: () => setState(() => _selectedSection = 3),
          ),
          const SizedBox(height: 6),
          _buildHeroExplorationCard(
            title: 'Behavior Insights',
            subtitle: 'See what drives your actions',
            icon: Icons.trending_up_rounded,
            isSelected: _selectedSection == 1,
            onTap: () => setState(() => _selectedSection = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroExplorationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return MindPressable(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? LabColors.warmIvory
                : Colors.white.withValues(alpha: 0.15),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 15, color: LabColors.warmIvory),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: LabColors.warmIvory,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: LabColors.warmIvory.withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: LabColors.warmIvory,
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
        return _buildSymptomExplorationView(strings, isDark, textPrimary, textSecondary, surfaceColor, borderColor);
      case 4:
      default:
        return const LongitudinalAnalysisView();
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
          const SizedBox(height: 16),
          const RoutineAnchorCard(),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.sectionPersonalDiscoveries,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => AddDiscoverySheet.show(context),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      strings.isArabic ? 'إضافة خلاصة' : 'Add Discovery',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: LabColors.sageGreen,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
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
              if (activity.completedAt != null) ...[
                Text(
                  '${activity.completedAt!.day}/${activity.completedAt!.month}',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Semantics(
                button: true,
                label: 'Delete discovery',
                child: InkWell(
                  onTap: () {
                    ref.read(journeyControllerProvider.notifier).deleteDiscovery(activity.id);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.radar_outlined, size: 16, color: LabColors.sageGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.isArabic ? 'فحص التناغم الذاتي السريع' : 'Self-Attunement Check',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        strings.sectionSymptomExploration,
                        style: TextStyle(fontSize: 10.5, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => ContextualSupportSheet.show(context),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: LabColors.sageGreen,
                  ),
                  child: Text(
                    strings.contextualSupportTitle,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Expanded(
          child: SymptomLibraryView(),
        ),
      ],
    );
  }
}
