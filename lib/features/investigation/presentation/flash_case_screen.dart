import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../controllers/investigation_providers.dart';
import '../domain/case_model.dart';
import 'ai_companion_hub_view.dart';
import 'widgets/ai_engine_config_sheet.dart';
import 'widgets/live_dialogue_view.dart';

/// Main conversational AI Guide screen combining direct session dialogue with
/// the mode/session library hub.
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
    final active =
        await ref.read(activeCaseControllerProvider.notifier).ensureHydrated();
    if (active == null || active.isCompleted) {
      if (mounted) {
        await ref
            .read(activeCaseControllerProvider.notifier)
            .startNewCase('Active Deconstruction');
      }
    }
  }

  String _engineLabel(AiConfigState config, AppStrings strings) {
    if (!config.isLiveActive) return strings.engineBadgeOffline;
    return config.provider == AiEngineProvider.groq
        ? strings.engineBadgeGroq
        : strings.engineBadgeGemini;
  }

  @override
  Widget build(BuildContext context) {
    final caseAsync = ref.watch(activeCaseControllerProvider);
    final aiConfig = ref.watch(aiConfigProvider);
    final strings = ref.watch(appStringsProvider);
    final tokens = context.tokens;

    ref.listen<AsyncValue<CaseModel?>>(activeCaseControllerProvider, (prev, next) {
      if (next.value != null && prev?.value?.id != next.value?.id) {
        if (_showHubView) {
          setState(() => _showHubView = false);
        }
      }
    });

    final caseModel = caseAsync.value;
    final isLive = aiConfig.isLiveActive;
    final engineLabel = _engineLabel(aiConfig, strings);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: tokens.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: _showHubView
            ? (caseModel != null
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: tokens.textPrimary,
                    ),
                    tooltip: strings.resumeConversationBtn,
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => setState(() => _showHubView = false),
                  )
                : null)
            : IconButton(
                icon: Icon(
                  Icons.grid_view_rounded,
                  size: 20,
                  color: tokens.textPrimary,
                ),
                tooltip: strings.modesAndHistoryTooltip,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => setState(() => _showHubView = true),
              ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                strings.navInvestigator,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 16.5,
                  color: tokens.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (_showHubView) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tokens.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  'AI HUB',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: tokens.accent,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          MindPressable(
            semanticLabel: '${strings.aiEngineTooltip}: $engineLabel',
            borderRadius: BorderRadius.circular(14),
            onPressed: () => AiEngineConfigSheet.show(context),
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isLive ? tokens.accentSoft : tokens.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLive
                        ? tokens.accent.withValues(alpha: 0.45)
                        : tokens.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.5,
                      height: 6.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLive ? tokens.accent : tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      engineLabel,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isLive ? tokens.accent : tokens.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!_showHubView)
            IconButton(
              icon: Icon(
                Icons.add_rounded,
                size: 22,
                color: tokens.textPrimary,
              ),
              tooltip: strings.newConversationBtn,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () async {
                HapticFeedback.lightImpact();
                final activeMode = ref.read(currentConversationModeProvider);
                await ref
                    .read(activeCaseControllerProvider.notifier)
                    .startNewCase('', mode: activeMode);
              },
            ),
          const SupportButton(compact: true),
          const SizedBox(width: 4),
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(tokens.accent),
                      ),
                    ),
                  ),
                )),
    );
  }
}
