import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../controllers/investigation_providers.dart';
import '../../domain/conversation_mode.dart';
import '../../domain/label_type.dart';

/// Shared icon lookup for all six conversational modes.
IconData iconForConversationMode(ConversationMode mode) {
  switch (mode) {
    case ConversationMode.exploreThought:
      return Icons.psychology_outlined;
    case ConversationMode.understandEmotion:
      return Icons.favorite_border_rounded;
    case ConversationMode.psychologicalAnalysis:
      return Icons.hub_outlined;
    case ConversationMode.guidedReflection:
      return Icons.auto_stories_outlined;
    case ConversationMode.justTalk:
      return Icons.chat_bubble_outline_rounded;
    case ConversationMode.grounding:
      return Icons.spa_outlined;
  }
}

/// Shared localized title for any [ConversationMode].
String localizedModeName(ConversationMode mode, AppStrings strings) {
  if (strings.isArabic) return mode.localizedArabicName;
  if (strings.isFrench) return mode.localizedFrenchName;
  return mode.displayName;
}

/// Shared localized description for any [ConversationMode].
String localizedModeDesc(ConversationMode mode, AppStrings strings) {
  if (strings.isArabic) return mode.localizedArabicDescription;
  if (strings.isFrench) return mode.localizedFrenchDescription;
  return mode.description;
}

/// Accessible icon pairing for each statement classification tag.
IconData iconForStatementLabel(LabelType label) {
  switch (label) {
    case LabelType.fact:
      return Icons.fact_check_outlined;
    case LabelType.assumption:
      return Icons.help_outline_rounded;
    case LabelType.interpretation:
      return Icons.auto_stories_outlined;
  }
}

/// Human-friendly localized label text (Fact / Guess / Story) while preserving
/// underlying [LabelType] values for clinical exports and memory storage.
String localizedStatementLabelName(LabelType label, AppStrings strings) {
  switch (label) {
    case LabelType.fact:
      return strings.labelFactHuman;
    case LabelType.assumption:
      return strings.labelGuessHuman;
    case LabelType.interpretation:
      return strings.labelStoryHuman;
  }
}

/// Clean 6-mode bottom sheet chooser triggered directly from the AI Guide header.
class ModeChooserSheet extends ConsumerWidget {
  const ModeChooserSheet({
    super.key,
    required this.activeMode,
    required this.onModeSelected,
  });

  final ConversationMode activeMode;
  final ValueChanged<ConversationMode> onModeSelected;

  static Future<ConversationMode?> show(
    BuildContext context, {
    required ConversationMode activeMode,
    required ValueChanged<ConversationMode> onModeSelected,
  }) {
    return showModalBottomSheet<ConversationMode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ModeChooserSheet(
        activeMode: activeMode,
        onModeSelected: onModeSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(tokens.cardRadius)),
        border: Border.all(color: tokens.border),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.chooseModeSheetTitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.chooseModeSheetSub,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: ConversationMode.values.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final mode = ConversationMode.values[idx];
                  final isSelected = mode == activeMode;
                  final name = localizedModeName(mode, strings);
                  final desc = localizedModeDesc(mode, strings);

                  return MindPressable(
                    semanticLabel: name,
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(currentConversationModeProvider.notifier)
                          .setMode(mode);
                      onModeSelected(mode);
                      Navigator.of(context).pop(mode);
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? tokens.accentSoft
                            : tokens.surfaceSecondary,
                        borderRadius: BorderRadius.circular(tokens.cardRadius),
                        border: Border.all(
                          color: isSelected ? tokens.accent : tokens.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? tokens.accent.withValues(alpha: 0.16)
                                  : tokens.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? tokens.accent.withValues(alpha: 0.35)
                                    : tokens.border,
                              ),
                            ),
                            child: Icon(
                              iconForConversationMode(mode),
                              size: 18,
                              color: isSelected
                                  ? tokens.accent
                                  : tokens.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? tokens.accent
                                              : tokens.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 18,
                                        color: tokens.accent,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  desc,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.4,
                                    color: tokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
