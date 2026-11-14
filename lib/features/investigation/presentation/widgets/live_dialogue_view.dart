import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/localization/locale_controller.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/safety/crisis_keywords.dart';
import '../../../../core/safety/safety_interceptor.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../journal/controllers/journal_memory_controller.dart';
import '../../../journey/controllers/journey_controller.dart';
import '../../../mind_trace/controllers/mind_trace_controller.dart';
import '../../../profile/controllers/profile_controller.dart';
import '../../../support/presentation/contextual_support_sheet.dart';
import '../../controllers/investigation_providers.dart';
import '../../data/mock_investigator_service.dart';
import '../../domain/case_model.dart';
import '../../domain/conversation_mode.dart';
import '../../domain/label_type.dart';
import '../../domain/session_memory_window.dart';
import '../../domain/statement.dart';
import 'custom_ai_instructions_sheet.dart';
import 'mode_chooser_sheet.dart';

/// Conversational reflection workspace for the AI Guide with warm blank-session
/// onboarding, single-tap mode switching, accessible statement labels, and
/// silent mock fallback on network errors.
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
    if (oldWidget.caseModel.conversationMode !=
        widget.caseModel.conversationMode) {
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
      if (!mounted || !_scrollController.hasClients) return;
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      final target = _scrollController.position.maxScrollExtent;
      if (reduceMotion) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = (quickText ?? _textController.text).trim();
    if (text.isEmpty || _isInvestigatorTyping) return;

    final activeCase =
        ref.read(activeCaseControllerProvider).value ?? widget.caseModel;
    if (activeCase.isPausedForSafety) return;

    if (quickText == null) {
      _textController.clear();
    }

    HapticFeedback.lightImpact();
    final notifier = ref.read(activeCaseControllerProvider.notifier);
    final service = ref.read(investigatorServiceProvider);
    final locale = ref.read(localeControllerProvider);

    // Offline Level-2 pre-generation crisis & medical emergency interception
    final classification = CrisisKeywords.classifyText(text);
    if (classification == SafetyClassification.immediateMedicalEmergency ||
        classification == SafetyClassification.imminentIntentOrCrisis ||
        classification == SafetyClassification.accidentalIngestionAlert) {
      bool statementPersisted = false;
      try {
        await notifier.addStatement(
          text,
          StatementSpeaker.user,
          label: LabelType.assumption,
          isSafetyStatement: true,
        );
        statementPersisted = true;
      } catch (e) {
        // Record safe diagnostic information without logging sensitive statement contents
        debugPrint(
            'Safety Warning: Failed to persist safety statement: ${e.runtimeType}');
      }

      // Attempt safety pause state persistence with graceful fail-safe handling
      final pausePersisted = await notifier.pauseCaseForSafety();

      // Regardless of persistence failure, always prioritize immediate user safety and display guidance
      if (mounted) {
        SafetyInterceptor.showCrisisPauseDialog(
          context,
          isMedicalEmergency:
              classification == SafetyClassification.immediateMedicalEmergency,
          isAccidentalIngestion:
              classification == SafetyClassification.accidentalIngestionAlert,
        );
        if (!pausePersisted) {
          debugPrint(
              'Safety Warning: Safety pause flag failed to persist to disk: fail-closed in memory active.');
        }
        if (!statementPersisted) {
          debugPrint(
              'Safety Warning: Safety statement failed to persist to disk: statement kept in volatile memory only.');
        }
      }
      return;
    }

    if (widget.caseModel.incidentDescription.trim().isEmpty) {
      await notifier.updateIncident(text);
    }

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
      final currentCase =
          ref.read(activeCaseControllerProvider).value ?? widget.caseModel;
      final profile = ref.read(profileControllerProvider).value;
      final journey = ref.read(journeyControllerProvider).value;
      final traces = ref.read(mindTraceControllerProvider).value ?? [];
      final memories = ref.read(journalMemoryControllerProvider).value ?? [];

      final window =
          SessionMemoryWindowManager.partition(currentCase.statements);
      String reply;
      try {
        reply = await service.getNextQuestion(
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
      } catch (_) {
        reply = await MockInvestigatorService().getNextQuestion(
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
      }

      if (mounted && reply.trim().isNotEmpty) {
        await notifier.addStatement(
          reply,
          StatementSpeaker.investigator,
        );
        HapticFeedback.selectionClick();
      }
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
    final strings = ref.read(appStringsProvider);

    final distortions = [
      (
        id: 'mind_reading',
        name: strings.isArabic
            ? 'قراءة الأفكار'
            : (strings.isFrench ? 'Lecture de pensée' : 'Mind Reading'),
        desc: strings.distortionMindReading,
      ),
      (
        id: 'catastrophizing',
        name: strings.isArabic
            ? 'التهويل والكارثية'
            : (strings.isFrench ? 'Catastrophisme' : 'Catastrophizing'),
        desc: strings.distortionCatastrophizing,
      ),
      (
        id: 'all_or_nothing',
        name: strings.isArabic
            ? 'التفكير الثنائي المطلق'
            : (strings.isFrench ? 'Tout-ou-rien' : 'All-or-Nothing'),
        desc: strings.distortionAllOrNothing,
      ),
      (
        id: 'emotional_reasoning',
        name: strings.isArabic
            ? 'الاستدلال الشعوري'
            : (strings.isFrench ? 'Raisonnement émotionnel' : 'Emotional Reasoning'),
        desc: strings.distortionEmotionalReasoning,
      ),
      (
        id: 'mental_filter',
        name: strings.isArabic
            ? 'التصفية الذهنية'
            : (strings.isFrench ? 'Filtre mental' : 'Mental Filter'),
        desc: strings.distortionMentalFilter,
      ),
      (
        id: 'overgeneralization',
        name: strings.isArabic
            ? 'التعميم المفرط'
            : (strings.isFrench ? 'Généralisation' : 'Overgeneralization'),
        desc: strings.distortionOvergeneralization,
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.tokens.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.tokens.cardRadius)),
      ),
      builder: (ctx) {
        final sheetTokens = ctx.tokens;
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
                      color: sheetTokens.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        strings.cognitiveDistortionSheetTitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: sheetTokens.textPrimary,
                        ),
                      ),
                    ),
                    if (statement.distortionTag != null)
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: sheetTokens.safetyWarmth,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          _updateStatementDistortion(statement, null);
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          strings.isArabic
                              ? 'إزالة'
                              : (strings.isFrench ? 'Effacer' : 'Clear'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  strings.cognitiveDistortionSheetDesc,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: sheetTokens.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: distortions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final item = distortions[idx];
                      final isSelected = statement.distortionTag == item.name;
                      return MindPressable(
                        semanticLabel: item.name,
                        borderRadius:
                            BorderRadius.circular(sheetTokens.buttonRadius),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _updateStatementDistortion(statement, item.name);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? sheetTokens.accentSoft
                                : sheetTokens.surfaceSecondary,
                            borderRadius: BorderRadius.circular(
                              sheetTokens.buttonRadius,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? sheetTokens.accent
                                  : sheetTokens.border,
                              width: isSelected ? 1.4 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? sheetTokens.accent
                                            : sheetTokens.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 17,
                                      color: sheetTokens.accent,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.desc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: sheetTokens.textSecondary,
                                  height: 1.35,
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
    final activeCase = ref.read(activeCaseControllerProvider).value;
    if (activeCase == null ||
        activeCase.statements.isEmpty ||
        _isSynthesizing ||
        activeCase.isPausedForSafety) {
      if (activeCase == null) {
        debugPrint(
            'Safety Warning: Case synthesis aborted because active case is unavailable or unverified.');
      } else if (activeCase.isPausedForSafety) {
        debugPrint(
            'Safety Warning: Case synthesis blocked because session is paused for safety.');
      }
      return;
    }

    setState(() => _isSynthesizing = true);
    HapticFeedback.mediumImpact();

    try {
      final strings = ref.read(appStringsProvider);
      final service = ref.read(investigatorServiceProvider);
      final locale = ref.read(localeControllerProvider);
      final profile = ref.read(profileControllerProvider).value;
      final tokens = context.tokens;

      final summary = await service.summarizeFindings(
        currentCase: activeCase,
        languageCode: locale.languageCode,
        profile: profile,
      );

      final notifier = ref.read(activeCaseControllerProvider.notifier);
      await notifier.saveFindings(summary);
      await notifier.saveConclusion(summary);

      if (mounted) {
        final router = GoRouter.maybeOf(context);
        if (router != null) {
          router.push('/case/${activeCase.id}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: tokens.surface,
              content: Text(
                strings.caseSynthesizedSuccess,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: tokens.border),
              ),
            ),
          );
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isSynthesizing = false);
      }
    }
  }

  void _openModeChooser() {
    ModeChooserSheet.show(
      context,
      activeMode: _currentMode,
      onModeSelected: (mode) {
        if (mounted) {
          setState(() => _currentMode = mode);
          ref
              .read(activeCaseControllerProvider.notifier)
              .setConversationMode(mode);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final aiConfig = ref.watch(aiConfigProvider);
    final profile = ref.watch(profileControllerProvider).value;

    final activeCase = ref.watch(activeCaseControllerProvider).value;
    final isPaused = activeCase == null || activeCase.isPausedForSafety;
    final statements = activeCase?.statements ?? widget.caseModel.statements;
    final hasUserMessages =
        statements.any((s) => s.speaker == StatementSpeaker.user);
    final isLive = aiConfig.isLiveActive;

    return Column(
      children: [
        _buildContextHeaderStrip(
          tokens: tokens,
          strings: strings,
          hasUserMessages: hasUserMessages,
          isPaused: isPaused,
        ),
        Expanded(
          child: !hasUserMessages
              ? _buildWelcomeEmptyState(
                  tokens: tokens,
                  strings: strings,
                  isLive: isLive,
                  profileConsented: profile?.shareWithAiCompanion ?? false,
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  itemCount:
                      statements.length + (_isInvestigatorTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == statements.length && _isInvestigatorTyping) {
                      return _CalmTypingIndicator(
                        tokens: tokens,
                        label: strings.investigatorTyping,
                      );
                    }
                    return _buildMessageBubble(
                      statement: statements[index],
                      isDark: isDark,
                      tokens: tokens,
                      strings: strings,
                      isLive: isLive,
                    );
                  },
                ),
        ),
        _buildSuggestedRepliesBar(
          tokens: tokens,
          strings: strings,
          hasUserMessages: hasUserMessages,
          isPaused: isPaused,
        ),
        _buildBottomInputBar(
          isDark: isDark,
          tokens: tokens,
          strings: strings,
        ),
      ],
    );
  }

  Widget _buildContextHeaderStrip({
    required MindTokens tokens,
    required AppStrings strings,
    required bool hasUserMessages,
    required bool isPaused,
  }) {
    final modeTitle = localizedModeName(_currentMode, strings);
    final hasCustomInstructions =
        ref.watch(profileControllerProvider).value?.customAiDirectives
                .trim()
                .isNotEmpty ==
            true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MindPressable(
            semanticLabel: '${strings.changeModeTooltip}: $modeTitle',
            borderRadius: BorderRadius.circular(14),
            onPressed: _openModeChooser,
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: tokens.accentSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: tokens.accent.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    iconForConversationMode(_currentMode),
                    size: 16,
                    color: tokens.accent,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      modeTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tokens.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: tokens.accent,
                  ),
                ],
              ),
            ),
          ),
          MindPressable(
            semanticLabel: strings.isArabic
                ? 'تعليمات المساعد'
                : (strings.isFrench ? 'Instructions IA' : 'Instructions'),
            borderRadius: BorderRadius.circular(12),
            onPressed: () => CustomAiInstructionsSheet.show(context),
            child: Container(
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: hasCustomInstructions
                    ? tokens.accentSoft
                    : tokens.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasCustomInstructions
                      ? tokens.accent.withValues(alpha: 0.4)
                      : tokens.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 15,
                    color: hasCustomInstructions
                        ? tokens.accent
                        : tokens.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      strings.isArabic
                          ? 'تعليمات'
                          : (strings.isFrench
                              ? 'Instructions'
                              : 'Instructions'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasCustomInstructions
                            ? tokens.accent
                            : tokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasUserMessages && !isPaused)
            MindPressable(
              semanticLabel: strings.saveTakeawayReportBtn,
              borderRadius: BorderRadius.circular(12),
              onPressed: (_isSynthesizing || isPaused) ? null : _synthesizeCaseBrief,
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: tokens.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tokens.accent.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSynthesizing)
                      SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: tokens.accent,
                        ),
                      )
                    else
                      Icon(
                        Icons.fact_check_outlined,
                        size: 15,
                        color: tokens.accent,
                      ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        strings.saveTakeawayReportBtn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tokens.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeEmptyState({
    required MindTokens tokens,
    required AppStrings strings,
    required bool isLive,
    required bool profileConsented,
  }) {
    final starters = strings.localizedStartersForMode(_currentMode.name);
    final privacyTag = widget.caseModel.isPrivate
        ? strings.privacyPrivateSessionTag
        : (isLive && profileConsented
            ? strings.privacyCloudConsentedTag
            : strings.privacyLocalTag);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              border: Border.all(color: tokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tokens.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: tokens.accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        iconForConversationMode(_currentMode),
                        size: 20,
                        color: tokens.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.surfaceSecondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: tokens.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 13,
                              color: tokens.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                privacyTag,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  strings.welcomeQuestionHeadline,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.welcomePickOrTypeSub,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...starters.take(3).map((starter) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MindPressable(
                semanticLabel: starter,
                borderRadius: BorderRadius.circular(tokens.cardRadius),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _sendMessage(starter);
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          starter,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: tokens.accent,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              MindPressable(
                semanticLabel: strings.openSelfCareToolsShort,
                borderRadius: BorderRadius.circular(14),
                onPressed: () {
                  final router = GoRouter.maybeOf(context);
                  if (router != null) {
                    router.push(AppRouter.observatory);
                  } else {
                    ContextualSupportSheet.show(context);
                  }
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: tokens.surfaceSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.spa_outlined,
                        size: 16,
                        color: tokens.accent,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          strings.openSelfCareToolsShort,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required Statement statement,
    required bool isDark,
    required MindTokens tokens,
    required AppStrings strings,
    required bool isLive,
  }) {
    final isUser = statement.speaker == StatementSpeaker.user;
    final bubbleBg = isUser ? tokens.surfaceSecondary : tokens.surface;
    final bubbleBorder = isUser
        ? tokens.border
        : (isLive ? tokens.accent.withValues(alpha: 0.35) : tokens.border);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isUser) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLive ? tokens.accent : tokens.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  strings.navInvestigator,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isLive ? tokens.accent : tokens.textSecondary,
                  ),
                ),
              ] else ...[
                Text(
                  strings.userSpeakerYou,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: bubbleBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bubbleBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statement.text,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: tokens.textPrimary,
                    fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      MindPressable(
                        semanticLabel: statement.label != null
                            ? localizedStatementLabelName(
                                statement.label!,
                                strings,
                              )
                            : strings.tagFactGuessStoryHint,
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () => _cycleStatementLabel(statement),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 34),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statement.label != null
                                ? LabColors.labelBackground(
                                    statement.label!,
                                    isDark: isDark,
                                  )
                                : tokens.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: statement.label != null
                                  ? LabColors.forLabel(statement.label!)
                                  : tokens.border,
                              width: statement.label != null ? 1.2 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statement.label != null
                                    ? iconForStatementLabel(statement.label!)
                                    : Icons.label_outline_rounded,
                                size: 14,
                                color: statement.label != null
                                    ? LabColors.forLabel(statement.label!)
                                    : tokens.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  statement.label != null
                                      ? localizedStatementLabelName(
                                          statement.label!,
                                          strings,
                                        )
                                      : strings.tagFactGuessStoryHint,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: statement.label != null
                                        ? LabColors.forLabel(statement.label!)
                                        : tokens.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      MindPressable(
                        semanticLabel: statement.distortionTag ??
                            strings.tagDistortionBtn,
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () =>
                            _showCognitiveDistortionsSheet(statement),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 34),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statement.distortionTag != null
                                ? tokens.accentSoft
                                : tokens.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: statement.distortionTag != null
                                  ? tokens.accent
                                  : tokens.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            statement.distortionTag ?? strings.tagDistortionBtn,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: statement.distortionTag != null
                                  ? tokens.accent
                                  : tokens.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  MindPressable(
                    semanticLabel: strings.saveTakeawayAction,
                    borderRadius: BorderRadius.circular(10),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final notifier =
                          ref.read(activeCaseControllerProvider.notifier);
                      await notifier.saveConclusion(statement.text);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            strings.isArabic
                                ? 'تم حفظ الفكرة في ملفك'
                                : (strings.isFrench
                                    ? 'Idée sauvegardée dans votre profil'
                                    : 'Takeaway saved to your profile'),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 34),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: tokens.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark_add_outlined,
                            size: 14,
                            color: tokens.accent,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            strings.saveTakeawayAction,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedRepliesBar({
    required MindTokens tokens,
    required AppStrings strings,
    required bool hasUserMessages,
    required bool isPaused,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: tokens.background,
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildReplyChip(
            tokens: tokens,
            icon: Icons.fact_check_outlined,
            label: strings.suggestedReplyFactsVsGuesses,
            highlighted: false,
            onPressed: () =>
                _sendMessage(strings.suggestedReplyFactsVsGuesses),
          ),
          _buildReplyChip(
            tokens: tokens,
            icon: Icons.spa_outlined,
            label: strings.suggestedReplyGroundingFirst,
            highlighted: true,
            onPressed: () => ContextualSupportSheet.show(context),
          ),
          if (hasUserMessages && !isPaused)
            _buildReplyChip(
              tokens: tokens,
              icon: Icons.bookmark_added_outlined,
              label: strings.suggestedReplySaveTakeaway,
              highlighted: false,
              onPressed: _synthesizeCaseBrief,
            ),
        ],
      ),
    );
  }

  Widget _buildReplyChip({
    required MindTokens tokens,
    required IconData icon,
    required String label,
    required bool highlighted,
    required VoidCallback onPressed,
  }) {
    return MindPressable(
      semanticLabel: label,
      borderRadius: BorderRadius.circular(14),
      onPressed: _isInvestigatorTyping ? null : onPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: highlighted ? tokens.accentSoft : tokens.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlighted
                ? tokens.accent.withValues(alpha: 0.4)
                : tokens.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: highlighted ? tokens.accent : tokens.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: highlighted ? tokens.accent : tokens.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInputBar({
    required bool isDark,
    required MindTokens tokens,
    required AppStrings strings,
  }) {
    final activeCase =
        ref.watch(activeCaseControllerProvider).value ?? widget.caseModel;
    final isPaused = activeCase.isPausedForSafety;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(top: BorderSide(color: tokens.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: !isPaused && !_isInvestigatorTyping,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => isPaused ? null : _sendMessage(),
              style: TextStyle(fontSize: 14.5, color: tokens.textPrimary),
              decoration: InputDecoration(
                hintText: isPaused
                    ? (strings.isArabic
                        ? 'تم إيقاف الجلسة مؤقتاً لسلامتك'
                        : (strings.isFrench
                            ? 'Session mise en pause par sécurité'
                            : 'Session paused for safety'))
                    : strings.typeMessageHint,
                hintStyle: TextStyle(
                  fontSize: 13.5,
                  color:
                      isPaused ? tokens.safetyWarmth : tokens.textSecondary,
                ),
                filled: true,
                fillColor: tokens.surfaceSecondary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(tokens.buttonRadius),
                  borderSide: BorderSide(color: tokens.border, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(tokens.buttonRadius),
                  borderSide: BorderSide(color: tokens.border, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(tokens.buttonRadius),
                  borderSide: BorderSide(color: tokens.accent, width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          MindPressable(
            semanticLabel: isPaused
                ? (strings.isArabic
                    ? 'تم إيقاف الجلسة مؤقتاً لسلامتك'
                    : (strings.isFrench
                        ? 'Session mise en pause par sécurité'
                        : 'Session paused for safety'))
                : (strings.isArabic
                    ? 'إرسال الرسالة'
                    : (strings.isFrench
                        ? 'Envoyer le message'
                        : 'Send message')),
            enabled: !isPaused && !_isInvestigatorTyping,
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
            onPressed:
                isPaused || _isInvestigatorTyping ? null : () => _sendMessage(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isPaused || _isInvestigatorTyping
                    ? tokens.border
                    : tokens.accent,
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
              ),
              child: Icon(
                isPaused
                    ? Icons.lock_outline_rounded
                    : Icons.arrow_upward_rounded,
                size: 20,
                color: isPaused || _isInvestigatorTyping
                    ? tokens.textSecondary
                    : (isDark ? tokens.background : Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalmTypingIndicator extends StatefulWidget {
  const _CalmTypingIndicator({
    required this.tokens,
    required this.label,
  });

  final MindTokens tokens;
  final String label;

  @override
  State<_CalmTypingIndicator> createState() => _CalmTypingIndicatorState();
}

class _CalmTypingIndicatorState extends State<_CalmTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.tokens.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.tokens.border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reduceMotion)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (_) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsetsDirectional.only(end: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.tokens.accent,
                        ),
                      ),
                    ),
                  )
                else
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, _) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          final phase = (_controller.value * 2 * math.pi) - (i * 0.7);
                          final alpha = (0.35 + 0.65 * ((math.sin(phase) + 1) / 2))
                              .clamp(0.3, 1.0);
                          return Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsetsDirectional.only(end: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.tokens.accent.withValues(alpha: alpha),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: widget.tokens.textSecondary,
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
