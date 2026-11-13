import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../controllers/investigation_providers.dart';
import '../domain/case_model.dart';
import 'ai_companion_hub_view.dart';
import 'widgets/live_dialogue_view.dart';

/// The Investigator Screen: Direct Conversational AI with "The Warm Investigator" / AI Companion.
///
/// Features (Build Session 05):
/// - Dual View: AI Companion Hub (Modes & Saved Sessions) <-> Live Dialogue (Active Conversation)
/// - 6 Clinically grounded conversational modes
/// - Socratic suggestion pills and starters
/// - 1-tap statement classification ([F] Fact, [A] Assumption, [I] Interpretation)
/// - Automatic local session persistence & hydration
/// - Strictly 0 emojis in UI (Vercel Luxury Dark aesthetic)
class FlashCaseScreen extends ConsumerStatefulWidget {
  const FlashCaseScreen({super.key});

  @override
  ConsumerState<FlashCaseScreen> createState() => _FlashCaseScreenState();
}

class _FlashCaseScreenState extends ConsumerState<FlashCaseScreen> {
  bool _showHubView = false;

  @override
  void initState() {
    super.initState();
    _ensureActiveCase();
  }

  Future<void> _ensureActiveCase() async {
    final active = await ref.read(activeCaseControllerProvider.notifier).ensureHydrated();
    if (active == null || active.isCompleted) {
      if (mounted) {
        await ref
            .read(activeCaseControllerProvider.notifier)
            .startNewCase('Active Deconstruction');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseAsync = ref.watch(activeCaseControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);

    final bg = isDark ? LabColors.nightBackground : LabColors.daylightBackground;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;
    final borderColor = isDark ? LabColors.nightBorder : LabColors.daylightBorder;

    ref.listen<AsyncValue<CaseModel?>>(activeCaseControllerProvider, (prev, next) {
      if (next.value != null && prev?.value?.id != next.value?.id) {
        // Automatically switch to chat view when a new case is selected or created
        if (_showHubView) {
          setState(() => _showHubView = false);
        }
      }
    });

    final caseModel = caseAsync.value;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        titleSpacing: 0,
        leading: _showHubView
            ? (caseModel != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    tooltip: strings.resumeConversationBtn,
                    onPressed: () => setState(() => _showHubView = false),
                  )
                : null)
            : IconButton(
                icon: const Icon(Icons.grid_view_rounded, size: 20),
                tooltip: strings.recentConversationsTitle,
                onPressed: () => setState(() => _showHubView = true),
              ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 16, color: LabColors.secondaryOlive),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                strings.navInvestigator.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: 0.6,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _showHubView
                    ? context.tokens.accentSoft
                    : context.tokens.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _showHubView
                      ? context.tokens.accent.withValues(alpha: 0.35)
                      : borderColor,
                ),
              ),
              child: Text(
                _showHubView
                    ? 'AI HUB'
                    : (caseModel?.caseNumber ?? 'SESSION 01'),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: _showHubView ? context.tokens.accent : textSecondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!_showHubView)
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 20),
              tooltip: strings.newConversationBtn,
              onPressed: () async {
                HapticFeedback.lightImpact();
                final activeMode = ref.read(currentConversationModeProvider);
                await ref
                    .read(activeCaseControllerProvider.notifier)
                    .startNewCase('', mode: activeMode);
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: 'Settings',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push(AppRouter.profile);
            },
          ),
          const SupportButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: _showHubView
          ? const SafeArea(child: AiCompanionHubView())
          : (caseModel != null
              ? SafeArea(child: LiveDialogueView(caseModel: caseModel))
              : SafeArea(
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.tokens.accent,
                        ),
                      ),
                    ),
                  ),
                )),
    );
  }
}
