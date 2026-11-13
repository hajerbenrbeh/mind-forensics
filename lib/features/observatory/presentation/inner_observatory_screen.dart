import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/mind_tokens.dart';
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
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final isAr = strings.isArabic;

    final bg = tokens.background;
    final surfaceColor = tokens.surface;
    final borderColor = tokens.border;
    final textPrimary = tokens.textPrimary;
    final textSecondary = tokens.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
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
          IconButton(
            tooltip: strings.contextualSupportTitle,
            icon: Icon(
              Icons.healing_outlined,
              size: 20,
              color: tokens.accent,
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
            // Top Soft Observatory Hero Banner (MindTokens styled, non-redundant actions)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: _buildPhone5Hero(isDark, tokens, strings),
              ),
            ),

            // Section Switcher Tabs (4 focused sections)
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
                        tokens: tokens,
                      ),
                      const SizedBox(width: 8),
                      _buildSectionTab(
                        index: 1,
                        label: strings.sectionExperimentsStrategies,
                        icon: Icons.lightbulb_outline_rounded,
                        tokens: tokens,
                      ),
                      const SizedBox(width: 8),
                      _buildSectionTab(
                        index: 2,
                        label: strings.sectionPersonalDiscoveries,
                        icon: Icons.auto_awesome_outlined,
                        tokens: tokens,
                      ),
                      const SizedBox(width: 8),
                      _buildSectionTab(
                        index: 3,
                        label: strings.sectionSymptomExploration,
                        icon: Icons.radar_outlined,
                        tokens: tokens,
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

  Widget _buildPhone5Hero(bool isDark, MindTokens tokens, AppStrings strings) {
    final heroBg = isDark ? tokens.surface : tokens.accent;
    final heroFg = isDark ? tokens.textPrimary : Colors.white;
    final heroSubFg = heroFg.withValues(alpha: 0.78);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: heroBg,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: isDark ? Border.all(color: tokens.border, width: 1.0) : null,
      ),
      child: Column(
        children: [
          Text(
            strings.observatoryTitle,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: heroFg,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            strings.observatoryHeroSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: heroSubFg,
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 96,
            child: NeuralBrainWireframe(size: 96),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHeroActionPill(
                  title: strings.mindAssistantTitle,
                  icon: Icons.auto_awesome,
                  isDark: isDark,
                  heroFg: heroFg,
                  tokens: tokens,
                  onTap: () => context.push(AppRouter.companion),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHeroActionPill(
                  title: strings.quickGroundingTitle,
                  icon: Icons.spa_outlined,
                  isDark: isDark,
                  heroFg: heroFg,
                  tokens: tokens,
                  onTap: () => ContextualSupportSheet.show(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroActionPill({
    required String title,
    required IconData icon,
    required bool isDark,
    required Color heroFg,
    required MindTokens tokens,
    required VoidCallback onTap,
  }) {
    return MindPressable(
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? tokens.surfaceSecondary : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? tokens.border : Colors.white.withValues(alpha: 0.22),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: isDark ? tokens.accent : Colors.white),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: heroFg,
                ),
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
    required MindTokens tokens,
  }) {
    final isSelected = _selectedSection == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedSection = index);
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? tokens.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? tokens.accent.withValues(alpha: 0.35) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? tokens.accent : tokens.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? tokens.accent : tokens.textSecondary,
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
                      foregroundColor: context.tokens.accent,
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
                    borderRadius: BorderRadius.circular(context.tokens.cardRadius),
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.tokens.accent,
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
                color: context.tokens.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.radar_outlined, size: 16, color: context.tokens.accent),
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
                    foregroundColor: context.tokens.accent,
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
