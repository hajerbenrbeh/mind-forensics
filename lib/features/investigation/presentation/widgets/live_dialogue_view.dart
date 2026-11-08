import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../../core/safety/crisis_keywords.dart';
import '../../../../core/safety/safety_interceptor.dart';
import '../../../../core/widgets/bouncing_widget.dart';
import '../../../journal/controllers/journal_memory_controller.dart';
import '../../../journey/controllers/journey_controller.dart';
import '../../../mind_trace/controllers/mind_trace_controller.dart';
import '../../../profile/controllers/profile_controller.dart';
import '../../../support/presentation/contextual_support_sheet.dart';
import '../../controllers/investigation_providers.dart';
import '../../domain/case_model.dart';
import '../../domain/conversation_mode.dart';
import '../../domain/label_type.dart';
import '../../domain/session_memory_window.dart';
import '../../domain/statement.dart';
import 'custom_ai_instructions_sheet.dart';

/// Direct Interactive Conversation with "The Warm Investigator" AI.
///
/// Features:
/// - Real-time conversational dialogue powered by Google Gemini (with offline mock fallback).
/// - Multi-turn clinical context retention.
/// - Tactile Socratic quick-response pills.
/// - 1-tap forensic statement tagging ([F] Fact, [A] Assumption, [I] Interpretation).
/// - Instant session persistence & archiving.
/// - Strictly 0 emojis in UI (Vercel Luxury Dark aesthetic).
class LiveDialogueView extends ConsumerStatefulWidget {
  const LiveDialogueView({
    super.key,
    required this.caseModel,
  });

  final CaseModel caseModel;

  @override
  ConsumerState<LiveDialogueView> createState() => _LiveDialogueViewState();
}

class _LiveDialogueViewState extends ConsumerState<LiveDialogueView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInvestigatorTyping = false;
  bool _isSynthesizing = false;
  late ConversationMode _currentMode;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.caseModel.conversationMode;
  }

  @override
  void didUpdateWidget(LiveDialogueView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caseModel.conversationMode != widget.caseModel.conversationMode) {
      _currentMode = widget.caseModel.conversationMode;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = (quickText ?? _textController.text).trim();
    if (text.isEmpty || _isInvestigatorTyping) return;

    final activeCase = ref.read(activeCaseControllerProvider).value ?? widget.caseModel;
    if (activeCase.isPausedForSafety) return;

    if (quickText == null) {
      _textController.clear();
    }

    HapticFeedback.lightImpact();
    final notifier = ref.read(activeCaseControllerProvider.notifier);
    final service = ref.read(investigatorServiceProvider);
    final locale = ref.read(localeControllerProvider);

    // Layer 1 (Offline) Pre-Generation Crisis Scan
    final safetyLevel = CrisisKeywords.evaluateText(text);
    if (safetyLevel == 2) {
      // 1. Persist the incoming statement
      await notifier.addStatement(
        text,
        StatementSpeaker.user,
        label: LabelType.assumption,
        isSafetyStatement: true,
      );
      // 2. Mark case paused for safety with fail-closed persistence
      final pausePersisted = await notifier.pauseCaseForSafety();
      if (!pausePersisted) {
        // Fail closed: abort all dialogue continuation
        return;
      }
      if (mounted) {
        SafetyInterceptor.showCrisisPauseDialog(context);
      }
      return; // Immediate abort of AI generation
    }

    // If case has no incident description yet, initialize it with this first thought
    if (widget.caseModel.incidentDescription.trim().isEmpty) {
      await notifier.updateIncident(text);
    }

    // 1. Add user statement
    await notifier.addStatement(
      text,
      StatementSpeaker.user,
      label: LabelType.assumption,
    );

    _scrollToBottom();

    if (mounted) {
      setState(() => _isInvestigatorTyping = true);
    }

    try {
      final currentCase = ref.read(activeCaseControllerProvider).value ?? widget.caseModel;
      final profile = ref.read(profileControllerProvider).value;
      final journey = ref.read(journeyControllerProvider).value;
      final traces = ref.read(mindTraceControllerProvider).value ?? [];
      final memories = ref.read(journalMemoryControllerProvider).value ?? [];

      // Partition into verbatim reciprocal window and deterministically recomputed summary
      final window = SessionMemoryWindowManager.partition(currentCase.statements);
      final reply = await service.getNextQuestion(
        currentCase: currentCase,
        conversationHistory: window.verbatimStatements,
        sessionSummary: window.sessionSummary ?? currentCase.sessionSummary,
        languageCode: locale.languageCode,
        profile: profile,
        journey: journey,
        conversationMode: _currentMode,
        latestTrace: ref.read(todayTraceProvider),
        historicalTraces: traces,
        compressedMemories: memories,
      );

      if (mounted) {
        await notifier.addStatement(
          reply,
          StatementSpeaker.investigator,
        );
        HapticFeedback.selectionClick();
      }
    } catch (_) {
      // Fallback handled automatically inside InvestigatorService
    } finally {
      if (mounted) {
        setState(() => _isInvestigatorTyping = false);
        _scrollToBottom();
      }
    }
  }

  void _cycleStatementLabel(Statement statement) {
    HapticFeedback.selectionClick();
    final nextLabel = switch (statement.label) {
      null => LabelType.assumption,
      LabelType.assumption => LabelType.fact,
      LabelType.fact => LabelType.interpretation,
      LabelType.interpretation => null,
    };

    final currentCase = ref.read(activeCaseControllerProvider).value;
    if (currentCase == null) return;

    final updatedStatements = currentCase.statements.map((s) {
      if (s.id == statement.id) {
        return s.copyWith(label: nextLabel);
      }
      return s;
    }).toList();

    ref.read(caseRepositoryProvider).saveCase(
          currentCase.copyWith(
            statements: updatedStatements,
            updatedAt: DateTime.now(),
          ),
        );

    ref.read(activeCaseControllerProvider.notifier).resumeCase(
          currentCase.copyWith(statements: updatedStatements),
        );
  }

  void _updateStatementDistortion(Statement statement, String? distortion) {
    HapticFeedback.selectionClick();
    final currentCase = ref.read(activeCaseControllerProvider).value;
    if (currentCase == null) return;

    final updatedStatements = currentCase.statements.map((s) {
      if (s.id == statement.id) {
        return s.copyWith(distortionTag: distortion);
      }
      return s;
    }).toList();

    ref.read(caseRepositoryProvider).saveCase(
          currentCase.copyWith(
            statements: updatedStatements,
            updatedAt: DateTime.now(),
          ),
        );

    ref.read(activeCaseControllerProvider.notifier).resumeCase(
          currentCase.copyWith(statements: updatedStatements),
        );
  }

  void _showCognitiveDistortionsSheet(Statement statement) {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.read(appStringsProvider);

    final bg = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final border = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    final distortions = [
      (
        id: 'mind_reading',
        name: strings.isArabic ? 'قراءة الأفكار' : (strings.isFrench ? 'Lecture de pensée' : 'Mind Reading'),
        desc: strings.distortionMindReading,
      ),
      (
        id: 'catastrophizing',
        name: strings.isArabic ? 'التهويل والكارثية' : (strings.isFrench ? 'Catastrophisme' : 'Catastrophizing'),
        desc: strings.distortionCatastrophizing,
      ),
      (
        id: 'all_or_nothing',
        name: strings.isArabic ? 'التفكير الثنائي المطلق' : (strings.isFrench ? 'Tout-ou-rien' : 'All-or-Nothing'),
        desc: strings.distortionAllOrNothing,
      ),
      (
        id: 'emotional_reasoning',
        name: strings.isArabic ? 'الاستدلال الشعوري' : (strings.isFrench ? 'Raisonnement émotionnel' : 'Emotional Reasoning'),
        desc: strings.distortionEmotionalReasoning,
      ),
      (
        id: 'mental_filter',
        name: strings.isArabic ? 'التصفية الذهنية' : (strings.isFrench ? 'Filtre mental' : 'Mental Filter'),
        desc: strings.distortionMentalFilter,
      ),
      (
        id: 'overgeneralization',
        name: strings.isArabic ? 'التعميم المفرط' : (strings.isFrench ? 'Généralisation' : 'Overgeneralization'),
        desc: strings.distortionOvergeneralization,
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings.cognitiveDistortionSheetTitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: textPrimary,
                      ),
                    ),
                    if (statement.distortionTag != null)
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: LabColors.cherryRedGlow,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          _updateStatementDistortion(statement, null);
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          strings.isArabic ? 'إزالة' : 'Clear',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  strings.cognitiveDistortionSheetDesc,
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: distortions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, idx) {
                      final item = distortions[idx];
                      final isSelected = statement.distortionTag == item.name;
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _updateStatementDistortion(statement, item.name);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE4E4E7))
                                : (isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? Colors.white : Colors.black)
                                  : border,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? (isDark ? Colors.white : Colors.black)
                                          : textPrimary,
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 14,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.desc,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: textSecondary,
                                  height: 1.3,
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
      },
    );
  }

  Future<void> _synthesizeCaseBrief() async {
    final currentCase = ref.read(activeCaseControllerProvider).value;
    if (currentCase == null || currentCase.statements.isEmpty || _isSynthesizing) return;

    setState(() => _isSynthesizing = true);
    HapticFeedback.mediumImpact();

    try {
      final strings = ref.read(appStringsProvider);
      final service = ref.read(investigatorServiceProvider);
      final locale = ref.read(localeControllerProvider);
      final profile = ref.read(profileControllerProvider).value;

      final summary = await service.summarizeFindings(
        currentCase: currentCase,
        languageCode: locale.languageCode,
        profile: profile,
      );

      final notifier = ref.read(activeCaseControllerProvider.notifier);
      await notifier.saveFindings(summary);
      await notifier.saveConclusion(summary);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? LabColors.nightSurface
                : LabColors.daylightSurface,
            content: Text(
              strings.caseSynthesizedSuccess,
              style: TextStyle(
                fontSize: 11.5,
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
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isSynthesizing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final aiConfig = ref.watch(aiConfigProvider);

    final surfaceColor = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final borderColor = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    final statements = widget.caseModel.statements;
    final isLive = aiConfig.isLiveActive;

    return Column(
      children: [
        // Sub-bar: Status Telemetry & Quick Session Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLive ? LabColors.sageGreenGlow : LabColors.warmBeige,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    isLive ? strings.liveGeminiActiveBadge : strings.offlineMockActiveBadge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: isLive ? LabColors.sageGreenGlow : LabColors.warmBeige,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (statements.isNotEmpty) ...[
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: _isSynthesizing
                          ? const SizedBox(
                              width: 11,
                              height: 11,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            )
                          : const Icon(Icons.fact_check_outlined, size: 14),
                      label: Text(
                        strings.synthesizeCaseBtn,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                      onPressed: _isSynthesizing ? null : _synthesizeCaseBrief,
                    ),
                    const SizedBox(width: 4),
                  ],
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: Text(
                      strings.newSessionBtn,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(activeCaseControllerProvider.notifier)
                          .startNewCase('Active Deconstruction');
                    },
                  ),
                  const SizedBox(width: 4),
                  Consumer(
                    builder: (context, ref, _) {
                      final profile = ref.watch(profileControllerProvider).value;
                      final hasCustom = profile?.customAiDirectives.trim().isNotEmpty == true;
                      return TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: hasCustom ? LabColors.champagneGold : textSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: Icon(
                          Icons.tune_rounded,
                          size: 14,
                          color: hasCustom ? LabColors.champagneGold : textSecondary,
                        ),
                        label: Text(
                          strings.isArabic ? 'تعليمات' : 'Instructions',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: hasCustom ? FontWeight.w800 : FontWeight.w600,
                            color: hasCustom ? LabColors.champagneGold : textSecondary,
                          ),
                        ),
                        onPressed: () => CustomAiInstructionsSheet.show(context),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),

        // Conversation Modes Selector Bar
        _buildConversationModesBar(isDark, borderColor, surfaceColor, textPrimary, textSecondary, strings),

        // Conversation Stream List
        Expanded(
          child: statements.isEmpty
              ? _buildWelcomeEmptyState(strings, isDark, textPrimary, textSecondary, surfaceColor, borderColor)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: statements.length + (_isInvestigatorTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == statements.length && _isInvestigatorTyping) {
                      return _buildTypingIndicator(strings, isDark, borderColor, surfaceColor, textSecondary);
                    }
                    final statement = statements[index];
                    return _buildMessageBubble(
                      statement: statement,
                      isDark: isDark,
                      strings: strings,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isLive: isLive,
                    );
                  },
                ),
        ),

        // Socratic Quick Suggestion Pills
        _buildSocraticPills(strings, isDark, surfaceColor, borderColor, textSecondary, statements.length),

        // Bottom Input Action Bar
        _buildBottomInputBar(isDark, strings, surfaceColor, borderColor, textPrimary, textSecondary),
      ],
    );
  }

  Widget _buildWelcomeEmptyState(
    AppStrings strings,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
    Color borderColor,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF141414) : const Color(0xFFF4F4F5),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Icon(Icons.psychology_outlined, size: 28, color: textPrimary),
            ),
            const SizedBox(height: 14),
            Text(
              strings.navInvestigator.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Text(
                strings.welcomeDialoguePrompt,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required Statement statement,
    required bool isDark,
    required AppStrings strings,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isLive,
  }) {
    final isUser = statement.speaker == StatementSpeaker.user;

    final bubbleBg = isUser
        ? (isDark ? const Color(0xFF181818) : const Color(0xFFE4E4E7))
        : (isDark ? const Color(0xFF0C0C0C) : const Color(0xFFFAFAFA));

    final bubbleBorder = isUser
        ? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFD4D4D8))
        : (isDark ? (isLive ? LabColors.sageBorder(isDark: true) : borderColor) : borderColor);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLive ? LabColors.sageGreenGlow : LabColors.warmBeige,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  strings.navInvestigator.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isLive ? LabColors.sageGreenGlow : textSecondary,
                  ),
                ),
              ] else ...[
                Text(
                  strings.navProfile.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: bubbleBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: bubbleBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statement.text,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: textPrimary,
                    fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      InkWell(
                        onTap: () => _cycleStatementLabel(statement),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statement.label != null
                                ? LabColors.labelBackground(statement.label!, isDark: isDark)
                                : (isDark ? const Color(0xFF222222) : const Color(0xFFE4E4E7)),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: statement.label != null
                                  ? LabColors.forLabel(statement.label!)
                                  : borderColor,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            statement.label != null
                                ? '[${statement.label!.letter}] ${statement.label!.displayName}'
                                : '+ Tag [F/A/I]',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: statement.label != null
                                  ? LabColors.forLabel(statement.label!)
                                  : textSecondary,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _showCognitiveDistortionsSheet(statement),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statement.distortionTag != null
                                ? LabColors.beigeBackground(isDark: isDark)
                                : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE4E4E7)),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: statement.distortionTag != null
                                  ? LabColors.warmBeige
                                  : borderColor,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            statement.distortionTag != null
                                ? '[${statement.distortionTag}]'
                                : strings.tagDistortionBtn,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: statement.distortionTag != null
                                  ? LabColors.warmBeige
                                  : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(
    AppStrings strings,
    bool isDark,
    Color borderColor,
    Color surfaceColor,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  strings.investigatorTyping,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocraticPills(
    AppStrings strings,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textSecondary,
    int statementCount,
  ) {
    final pills = statementCount <= 2
        ? [
            strings.quickPillWhatFacts,
            strings.quickPillAssumption,
            strings.quickPillSomatic,
          ]
        : [
            strings.quickPillNoProof,
            strings.quickPillAlternative,
            strings.quickPillFriendPerspective,
            strings.quickPillControl,
          ];

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ActionChip(
            backgroundColor: surfaceColor,
            side: BorderSide(color: LabColors.sageGreen.withValues(alpha: 0.5), width: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            avatar: const Icon(Icons.spa_outlined, size: 13, color: LabColors.sageGreen),
            label: Text(
              strings.needPracticalSupportNow,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: LabColors.sageGreen),
            ),
            onPressed: () => ContextualSupportSheet.show(context),
          ),
          const SizedBox(width: 6),
          ...pills.map((pill) => Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: ActionChip(
              backgroundColor: surfaceColor,
              side: BorderSide(color: borderColor, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              label: Text(
                pill,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textSecondary),
              ),
              onPressed: () => _sendMessage(pill),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomInputBar(
    bool isDark,
    AppStrings strings,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final activeCase = ref.watch(activeCaseControllerProvider).value ?? widget.caseModel;
    final isPaused = activeCase.isPausedForSafety;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: !isPaused,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => isPaused ? null : _sendMessage(),
              style: TextStyle(fontSize: 13, color: textPrimary),
              decoration: InputDecoration(
                hintText: isPaused
                    ? 'Session paused for safety'
                    : strings.typeMessageHint,
                hintStyle: TextStyle(
                    fontSize: 12,
                    color: isPaused
                        ? LabColors.safetyWarmth
                        : textSecondary.withValues(alpha: 0.6)),
                filled: true,
                fillColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F4F5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: textPrimary, width: 1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          BouncingWidget(
            onTap: isPaused || _isInvestigatorTyping ? null : () => _sendMessage(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isPaused
                    ? (isDark ? const Color(0xFF222222) : const Color(0xFFE5E5E5))
                    : (isDark ? Colors.white : Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPaused ? Icons.lock_outline_rounded : Icons.arrow_upward_rounded,
                size: 20,
                color: isPaused
                    ? textSecondary
                    : (isDark ? Colors.black : Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationModesBar(
    bool isDark,
    Color borderColor,
    Color surfaceColor,
    Color textPrimary,
    Color textSecondary,
    AppStrings strings,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F080A) : const Color(0xFFFBF8F6),
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: ConversationMode.values.map((mode) {
            final isSelected = mode == _currentMode;
            final label = strings.isArabic
                ? mode.localizedArabicName
                : (strings.isFrench ? mode.localizedFrenchName : mode.displayName);

            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: BouncingWidget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentMode = mode);
                  ref.read(activeCaseControllerProvider.notifier).setConversationMode(mode);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? LabColors.darkWine : LabColors.warmIvory)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? LabColors.champagneGold
                          : (isDark ? const Color(0xFF262626) : const Color(0xFFE4E4E7)),
                      width: isSelected ? 1.2 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: LabColors.champagneGold,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? LabColors.champagneGold : textSecondary,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
