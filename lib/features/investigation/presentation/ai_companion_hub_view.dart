import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../core/widgets/fingerprint_thread_signature.dart';
import '../controllers/investigation_providers.dart';
import '../domain/case_model.dart';
import '../domain/conversation_mode.dart';

/// The Landing Screen and Hub for the AI Companion.
///
/// Features (Build Session 05):
/// - Poetic introduction & identity banner
/// - Mode Selection Grid (6 modes with localized descriptions)
/// - Socratic suggested conversation starters
/// - Start New Conversation action
/// - Recent Conversation History list (Resume, Rename, Delete, Clear All)
/// - Luxury Vercel Dark & Master Burgundy aesthetics
/// - Strictly 0 emojis
class AiCompanionHubView extends ConsumerStatefulWidget {
  const AiCompanionHubView({super.key});

  @override
  ConsumerState<AiCompanionHubView> createState() => _AiCompanionHubViewState();
}

class _AiCompanionHubViewState extends ConsumerState<AiCompanionHubView> {
  IconData _getModeIcon(ConversationMode mode) {
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

  void _showRenameDialog(BuildContext context, CaseModel caseModel) {
    final controller = TextEditingController(text: caseModel.title);
    final strings = ref.read(appStringsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark ? LabColors.nightSurface : LabColors.daylightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? LabColors.nightBorder : LabColors.daylightBorder),
          ),
          title: Text(
            strings.renameConversationTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? LabColors.warmIvory : Colors.black,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter title...',
              filled: true,
              fillColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: LabColors.wineBorder),
              ),
            ),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? LabColors.warmIvory : Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                strings.cancelBtn,
                style: const TextStyle(color: LabColors.champagneGold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  await ref
                      .read(activeCaseControllerProvider.notifier)
                      .renameCase(caseModel.id, newTitle);
                }
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: Text(strings.saveVerdictBtn),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, CaseModel caseModel) {
    final strings = ref.read(appStringsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark ? LabColors.nightSurface : LabColors.daylightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? LabColors.nightBorder : LabColors.daylightBorder),
          ),
          title: Text(
            strings.deleteConversationTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? LabColors.warmIvory : Colors.black,
            ),
          ),
          content: Text(
            strings.deleteConversationConfirm,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? LabColors.softBeige : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                strings.cancelBtn,
                style: const TextStyle(color: LabColors.champagneGold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LabColors.cherryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                await ref
                    .read(activeCaseControllerProvider.notifier)
                    .deleteCase(caseModel.id);
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: Text(strings.deletePermanentlyBtn),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllDialog(BuildContext context) {
    final strings = ref.read(appStringsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark ? LabColors.nightSurface : LabColors.daylightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? LabColors.nightBorder : LabColors.daylightBorder),
          ),
          title: Text(
            strings.clearAllConversationsBtn,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? LabColors.warmIvory : Colors.black,
            ),
          ),
          content: Text(
            strings.clearAllConversationsConfirm,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? LabColors.softBeige : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                strings.cancelBtn,
                style: const TextStyle(color: LabColors.champagneGold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LabColors.cherryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                await ref
                    .read(activeCaseControllerProvider.notifier)
                    .deleteAllCases();
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: Text(strings.deletePermanentlyBtn),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startConversation([String? initialPrompt]) async {
    HapticFeedback.mediumImpact();
    final activeMode = ref.read(currentConversationModeProvider);
    await ref
        .read(activeCaseControllerProvider.notifier)
        .startNewCase(initialPrompt ?? '', mode: activeMode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final selectedMode = ref.watch(currentConversationModeProvider);
    final savedCasesAsync = ref.watch(savedCasesProvider);

    final surfaceColor = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final borderColor = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Poetic Hero Introduction
          _buildHeroHeader(isDark, strings, textPrimary, textSecondary),

          const SizedBox(height: 20),

          // 2. Mode Selection Section
          Row(
            children: [
              Text(
                strings.selectConversationMode.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: LabColors.champagneGold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141414) : const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  '6 MODES',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mode Cards Grid
          ...ConversationMode.values.map((mode) {
            final isSelected = mode == selectedMode;
            final modeTitle = strings.isArabic
                ? mode.localizedArabicName
                : (strings.isFrench ? mode.localizedFrenchName : mode.displayName);
            final modeDesc = strings.isArabic
                ? mode.localizedArabicDescription
                : (strings.isFrench ? mode.localizedFrenchDescription : mode.description);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BouncingWidget(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(currentConversationModeProvider.notifier)
                      .setMode(mode);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? LabColors.darkWine : const Color(0xFFFBE8E9))
                        : surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? LabColors.champagneGold
                          : (isDark ? LabColors.wineBorder : borderColor),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? LabColors.deepBurgundy
                              : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F2)),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? LabColors.wineBorder : borderColor,
                          ),
                        ),
                        child: Icon(
                          _getModeIcon(mode),
                          size: 18,
                          color: isSelected ? LabColors.champagneGold : textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  modeTitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? (isDark ? LabColors.warmIvory : LabColors.deepBurgundy)
                                        : textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: LabColors.champagneGold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: LabColors.champagneGold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              modeDesc,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.35,
                                color: isSelected
                                    ? (isDark ? LabColors.softBeige : Colors.brown)
                                    : textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 14),

          // 3. Suggested Conversation Starters
          Text(
            strings.suggestedStartersTitle.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: LabColors.champagneGold,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selectedMode.suggestedStarters.map((starter) {
              return BouncingWidget(
                onTap: () => _startConversation(starter),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? LabColors.nightSurfaceSubtle : LabColors.daylightSurfaceSubtle,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? LabColors.nightBorder : LabColors.daylightBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_forward_rounded, size: 12, color: textSecondary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          starter,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // 4. Primary CTA: Start New Conversation
          BouncingWidget(
            onTap: () => _startConversation(),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    strings.newConversationBtn.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 26),

          // 5. Recent Conversations List
          Row(
            children: [
              Text(
                strings.recentConversationsTitle.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: LabColors.champagneGold,
                ),
              ),
              const Spacer(),
              savedCasesAsync.maybeWhen(
                data: (cases) => cases.isNotEmpty
                    ? TextButton(
                        onPressed: () => _showClearAllDialog(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          strings.clearAllConversationsBtn,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: LabColors.cherryRed,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          savedCasesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, _) => Center(
              child: Text(
                'Error loading conversations: $err',
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
            ),
            data: (cases) {
              if (cases.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 20, color: textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          strings.noRecentConversations,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: cases.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? LabColors.wineBorder : borderColor),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(activeCaseControllerProvider.notifier)
                              .resumeCase(c);
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161616) : const Color(0xFFF4F4F6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: borderColor),
                          ),
                          child: Icon(
                            _getModeIcon(c.conversationMode),
                            size: 16,
                            color: LabColors.champagneGold,
                          ),
                        ),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF141414) : const Color(0xFFEEEEF0),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                strings.formatSessionNumber(c.caseNumber),
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                c.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text(
                                c.conversationMode.displayName,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: LabColors.champagneGold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('•', style: TextStyle(fontSize: 10, color: textSecondary)),
                              const SizedBox(width: 6),
                              Text(
                                '${c.statements.length} exchanges',
                                style: TextStyle(fontSize: 10, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, size: 16, color: textSecondary),
                          color: isDark ? LabColors.nightSurface : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isDark ? LabColors.nightBorder : LabColors.daylightBorder),
                          ),
                          onSelected: (val) {
                            if (val == 'resume') {
                              ref
                                  .read(activeCaseControllerProvider.notifier)
                                  .resumeCase(c);
                            } else if (val == 'rename') {
                              _showRenameDialog(context, c);
                            } else if (val == 'delete') {
                              _showDeleteDialog(context, c);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'resume',
                              child: Text(strings.resumeConversationBtn, style: const TextStyle(fontSize: 12)),
                            ),
                            PopupMenuItem(
                              value: 'rename',
                              child: Text(strings.renameConversationTitle, style: const TextStyle(fontSize: 12)),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                strings.deleteConversationTitle,
                                style: const TextStyle(fontSize: 12, color: LabColors.cherryRed),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(
    bool isDark,
    AppStrings strings,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? LabColors.nightSurface : LabColors.daylightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? LabColors.nightBorder : LabColors.daylightBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FingerprintThreadSignature(size: 20, animated: false),
              const SizedBox(width: 8),
              Text(
                strings.aiCompanionTitle.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: LabColors.champagneGold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDark ? LabColors.darkWine : const Color(0xFFFBE8E9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: LabColors.wineBorder),
                ),
                child: Text(
                  'CONFIDENTIAL & OFFLINE-FIRST',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isDark ? LabColors.champagneGold : LabColors.deepBurgundy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '“${strings.aiCompanionIntro}”',
            style: LabTheme.editorialSerif(
              fontSize: 14.5,
              fontStyle: FontStyle.italic,
              height: 1.35,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.aiCompanionSupporting,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
