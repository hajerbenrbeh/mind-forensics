import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/crisis_keywords.dart';
import '../../../core/safety/safety_interceptor.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_pill.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/mind_segmented.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/presentation/widgets/home_organic_exercise_art.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/case_model.dart';
import '../../investigation/domain/conversation_mode.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../mind_trace/presentation/widgets/daily_mind_trace_stepper.dart';
import '../../mind_trace/presentation/widgets/trace_investigation_sheet.dart';
import 'widgets/track_entry_detail_sheet.dart';
import 'widgets/track_month_calendar.dart';
import 'widgets/track_mood_picker.dart';
import 'widgets/track_mood_utils.dart';

/// Consolidated daily tracking workspace combining fast check-ins with an
/// interactive calendar & chronological history.
class TrackScreen extends ConsumerStatefulWidget {
  const TrackScreen({
    super.key,
    this.initialTab = 0,
  });

  final int initialTab;

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _triggerOptions = [
    'Work / Demands',
    'Sleep Disruption',
    'Studies',
    'Social',
    'Health',
    'Overload',
  ];

  static const List<String> _helpedOptions = [
    'Walk',
    'Quiet time',
    'Breathing',
    'Talked',
    'Rest',
  ];

  late TabController _tabController;
  late TextEditingController _noteController;

  // Tab 0: Check-In Today form state
  late int _activeTab;
  String _selectedMood = 'calm';
  double _moodIntensity = 5.0;
  double _energyLevel = 5.0;
  double _anxietyLevel = 3.0;
  double _sleepHours = 7.5;
  final Set<String> _selectedTriggers = {};
  final Set<String> _selectedHelped = {};
  bool _isSaving = false;
  bool _savedConfirmed = false;
  bool _initializedFromTrace = false;
  bool _showOptionalContext = false;
  String _lastSavedNote = '';

  // Tab 1: History & Calendar state
  DateTime _calendarMonth =
      DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedDateKey;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab.clamp(0, 1);
    _noteController = TextEditingController();
    _noteController.addListener(_onNoteChanged);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _activeTab,
    );
    _tabController.addListener(_handleTabControllerTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hydrateFromTrace(ref.read(todayTraceProvider));
    });
  }

  @override
  void didUpdateWidget(covariant TrackScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextInitial = widget.initialTab.clamp(0, 1);
    if (oldWidget.initialTab != widget.initialTab &&
        nextInitial != _tabController.index) {
      _tabController.animateTo(nextInitial);
    }
  }

  void _handleTabControllerTick() {
    if (!mounted) return;
    if (_tabController.index != _activeTab) {
      setState(() => _activeTab = _tabController.index);
    }
  }

  void _onNoteChanged() {
    if (_savedConfirmed &&
        _noteController.text.trim() != _lastSavedNote &&
        mounted) {
      setState(() => _savedConfirmed = false);
    }
  }

  @override
  void dispose() {
    _noteController.removeListener(_onNoteChanged);
    _noteController.dispose();
    _tabController.removeListener(_handleTabControllerTick);
    _tabController.dispose();
    super.dispose();
  }

  void _hydrateFromTrace(MindTraceModel? trace, {bool force = false}) {
    if ((!force && _initializedFromTrace) || trace == null) return;
    _initializedFromTrace = true;
    final hydratedNote = trace.journalText ?? '';
    _lastSavedNote = hydratedNote.trim();
    setState(() {
      _selectedMood = trace.overallMood;
      _moodIntensity = trace.moodIntensity.toDouble().clamp(1, 10);
      _energyLevel = (trace.energyLevel ?? 5).toDouble().clamp(1, 10);
      _anxietyLevel = (trace.anxietyLevel ?? 3).toDouble().clamp(0, 10);
      _sleepHours = (trace.sleepHours ?? 7.5).clamp(2, 14);
      _noteController.text = hydratedNote;

      _selectedTriggers.clear();
      if (trace.situation != null && trace.situation!.trim().isNotEmpty) {
        _selectedTriggers.addAll(
          trace.situation!
              .split(',')
              .map((s) => s.trim())
              .where((p) => p.isNotEmpty),
        );
      }

      _selectedHelped.clear();
      if (trace.behavioralResponse != null &&
          trace.behavioralResponse!.trim().isNotEmpty) {
        _selectedHelped.addAll(
          trace.behavioralResponse!
              .split(',')
              .map((s) => s.trim())
              .where((p) => p.isNotEmpty),
        );
      }
    });
  }

  Future<void> _saveQuickCheckIn() async {
    final strings = ref.read(appStringsProvider);
    final tokens = context.tokens;

    if (_selectedMood.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: tokens.surfaceSecondary,
          content: Text(
            strings.pickHowYouFeelFirst,
            style: TextStyle(color: tokens.textPrimary, fontSize: 13),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final today = ref.read(todayTraceProvider);
      final authUser = ref.read(authControllerProvider).user;
      final userId = authUser?.id ?? 'local_user';

      final situationStr =
          _selectedTriggers.isNotEmpty ? _selectedTriggers.join(', ') : null;
      final helpedStr =
          _selectedHelped.isNotEmpty ? _selectedHelped.join(', ') : null;
      final noteText = _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null;

      // Preserve Level 2 crisis pre-scan safeguard before saving any note.
      if (noteText != null && CrisisKeywords.evaluateText(noteText) == 2) {
        setState(() => _isSaving = false);
        if (mounted) {
          SafetyInterceptor.showCrisisPauseDialog(context);
        }
        return;
      }

      final trace = today != null
          ? today.copyWith(
              overallMood: _selectedMood,
              selectedEmotions: [_selectedMood],
              moodIntensity: _moodIntensity.round(),
              energyLevel: _energyLevel.round(),
              anxietyLevel: _anxietyLevel.round(),
              sleepHours: _sleepHours,
              situation: situationStr,
              behavioralResponse: helpedStr,
              journalText: noteText,
              updatedAt: now,
            )
          : MindTraceModel(
              id: const Uuid().v4(),
              userId: userId,
              date: DateTime(now.year, now.month, now.day),
              overallMood: _selectedMood,
              selectedEmotions: [_selectedMood],
              moodIntensity: _moodIntensity.round(),
              energyLevel: _energyLevel.round(),
              anxietyLevel: _anxietyLevel.round(),
              sleepHours: _sleepHours,
              situation: situationStr,
              behavioralResponse: helpedStr,
              journalText: noteText,
              createdAt: now,
              updatedAt: now,
            );

      _initializedFromTrace = true;
      _lastSavedNote = noteText ?? '';
      await ref
          .read(mindTraceControllerProvider.notifier)
          .recordCheckIn(trace, generateAi: false);

      if (mounted) {
        setState(() => _savedConfirmed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: tokens.surfaceSecondary,
            content: Text(
              strings.checkInSavedSnackbar,
              style: TextStyle(color: tokens.textPrimary, fontSize: 13),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openGuidedCheckInSheet(MindTraceModel? todayTrace) {
    final tokens = context.tokens;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: Container(
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(tokens.cardRadius),
              ),
              border: Border.all(color: tokens.border),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: DailyMindTraceStepper(
                    initialTrace: todayTrace,
                    onViewConstellation: () {
                      Navigator.of(sheetCtx).pop();
                      if (mounted) _tabController.animateTo(1);
                    },
                    onReturnHome: () => Navigator.of(sheetCtx).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleInspectTrace(MindTraceModel trace, AppStrings strings) {
    final today = ref.read(todayTraceProvider);
    final isTodayTrace =
        today != null && (trace.id == today.id || trace.dateKey == today.dateKey);

    TrackEntryDetailSheet.show(
      context,
      trace: trace,
      onEdit: () {
        if (isTodayTrace) {
          _hydrateFromTrace(trace, force: true);
          _tabController.animateTo(0);
        } else {
          EditPastTraceSheet.show(context, trace);
        }
      },
      onExploreWithAi: () async {
        final moodText = trackMoodLabel(trace.overallMood, strings);
        final note = trace.journalText?.trim() ?? '';
        final notePart = note.isNotEmpty ? ' — "$note"' : '';
        final handoffPrompt =
            '${strings.exploreMoodContextPrefix} $moodText (${trace.moodIntensity}/10)$notePart';

        await ref.read(activeCaseControllerProvider.notifier).startNewCase(
              handoffPrompt,
              mode: ConversationMode.understandEmotion,
            );
        if (!mounted) return;
        final router = GoRouter.maybeOf(context);
        if (router != null) {
          router.go(AppRouter.companion);
        } else {
          TraceInvestigationSheet.show(context, trace);
        }
      },
      onDeleted: () {
        if (_selectedDateKey == trace.dateKey && mounted) {
          setState(() => _selectedDateKey = null);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final todayTrace = ref.watch(todayTraceProvider);

    ref.listen<MindTraceModel?>(todayTraceProvider, (_, next) {
      if (!_initializedFromTrace && next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _hydrateFromTrace(next);
        });
      }
    });

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopHeaderAndSegmented(tokens, strings),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCheckInTodayTab(tokens, strings, todayTrace),
                  _buildHistoryAndCalendarTab(tokens, strings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeaderAndSegmented(MindTokens tokens, AppStrings strings) {
    final canPop = Navigator.of(context).canPop();
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (canPop) ...[
                IconButton(
                  tooltip: strings.backBtn,
                  icon: Icon(
                    isRtl
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,
                    color: tokens.textPrimary,
                    size: 20,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  strings.trackPageTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: tokens.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: strings.isArabic ? 0 : -0.3,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: tokens.textPrimary,
                ),
                tooltip: strings.fullCalendarTooltip,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final router = GoRouter.maybeOf(context);
                  if (router != null) {
                    router.push(AppRouter.progress);
                  } else {
                    _tabController.animateTo(1);
                  }
                },
              ),
              const SupportButton(compact: true),
            ],
          ),
          const SizedBox(height: 10),
          MindSegmented(
            index: _activeTab,
            labels: [
              strings.checkInTodayTab,
              strings.historyAndCalendarTab,
            ],
            onChanged: (idx) {
              HapticFeedback.selectionClick();
              _tabController.animateTo(idx);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInTodayTab(
    MindTokens tokens,
    AppStrings strings,
    MindTraceModel? todayTrace,
  ) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.howFeelingRightNow,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                    letterSpacing: strings.isArabic ? 0 : -0.3,
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    strings.todaysCoreState,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: tokens.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: strings.isArabic ? 0 : 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TrackMoodPicker(
                  selectedMoodKey: _selectedMood,
                  strings: strings,
                  onSelect: (key) {
                    setState(() {
                      _selectedMood = key;
                      _savedConfirmed = false;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TrackIntensitySlider(
                  value: _moodIntensity,
                  strings: strings,
                  onChanged: (v) {
                    setState(() {
                      _moodIntensity = v;
                      _savedConfirmed = false;
                    });
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.border),
                  ),
                  child: TextField(
                    controller: _noteController,
                    maxLines: 5,
                    minLines: 3,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 1.45,
                      color: tokens.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      hintText: strings.whatsOnYourMindHint,
                      hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        color: tokens.textSecondary,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                MindCard(
                  padding: EdgeInsets.zero,
                  child: MindPressable(
                    semanticLabel: strings.addContextOptionalTitle,
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                    onPressed: () {
                      setState(
                        () => _showOptionalContext = !_showOptionalContext,
                      );
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        12,
                        14,
                        12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_outlined,
                            size: 18,
                            color: tokens.accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  strings.addContextOptionalTitle,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  strings.addContextOptionalSub,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: tokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _showOptionalContext
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: tokens.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: _showOptionalContext
                      ? _buildOptionalContextSection(tokens, strings)
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                Center(
                  child: MindPressable(
                    semanticLabel: strings.preferStepByStepLabel,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => _openGuidedCheckInSheet(todayTrace),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 16,
                            color: tokens.accent,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              strings.preferStepByStepLabel,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: tokens.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildPinnedSaveFooter(tokens, strings, todayTrace, reduceMotion),
      ],
    );
  }

  Widget _buildPinnedSaveFooter(
    MindTokens tokens,
    AppStrings strings,
    MindTraceModel? todayTrace,
    bool reduceMotion,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.background,
        border: Border(top: BorderSide(color: tokens.border, width: 1.0)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutBack,
              child: _savedConfirmed
                  ? Padding(
                      key: const ValueKey('saved-pill'),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: tokens.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            strings.savedBadgeLabel,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.accent,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('not-saved-pill')),
            ),
            MindButton(
              text: todayTrace != null
                  ? strings.updateTodaysEntryAction
                  : strings.saveCheckInAction,
              isFullWidth: true,
              isLoading: _isSaving,
              leadingIcon: _savedConfirmed
                  ? Icons.check_rounded
                  : Icons.check_circle_outline,
              onPressed: _saveQuickCheckIn,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionalContextSection(MindTokens tokens, AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.whatsInfluencingMood,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: tokens.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  strings.triggersContextHeader,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: tokens.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: strings.isArabic ? 0 : 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _triggerOptions.map((trig) {
              final isSel = _selectedTriggers.contains(trig);
              return MindPill(
                label: strings.trackTriggerDisplay(trig),
                isSelected: isSel,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _savedConfirmed = false;
                    if (isSel) {
                      _selectedTriggers.remove(trig);
                    } else {
                      _selectedTriggers.add(trig);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            strings.whatHelpedTodayLabel,
            style: TextStyle(
              fontFamily: 'Inter',
              color: tokens.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _helpedOptions.map((item) {
              final isSel = _selectedHelped.contains(item);
              return MindPill(
                label: strings.trackHelpedDisplay(item),
                isSelected: isSel,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _savedConfirmed = false;
                    if (isSel) {
                      _selectedHelped.remove(item);
                    } else {
                      _selectedHelped.add(item);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          MindCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSliderRow(
                  label: strings.sleepTrackingLabel,
                  value: _sleepHours,
                  min: 4,
                  max: 11,
                  divisions: 14,
                  unit: 'h',
                  tokens: tokens,
                  onChanged: (v) {
                    setState(() {
                      _sleepHours = v;
                      _savedConfirmed = false;
                    });
                  },
                ),
                const Divider(height: 20, thickness: 0.5),
                _buildSliderRow(
                  label: strings.energyTrackingLabel,
                  value: _energyLevel,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  unit: '/10',
                  tokens: tokens,
                  onChanged: (v) {
                    setState(() {
                      _energyLevel = v;
                      _savedConfirmed = false;
                    });
                  },
                ),
                const Divider(height: 20, thickness: 0.5),
                _buildSliderRow(
                  label: strings.anxietyTrackingLabel,
                  value: _anxietyLevel,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  unit: '/10',
                  tokens: tokens,
                  onChanged: (v) {
                    setState(() {
                      _anxietyLevel = v;
                      _savedConfirmed = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required MindTokens tokens,
    required ValueChanged<double> onChanged,
  }) {
    final formatted =
        value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: tokens.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$formatted$unit',
              style: TextStyle(
                fontFamily: 'Inter',
                color: tokens.accent,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: tokens.accent,
            inactiveTrackColor: tokens.border,
            thumbColor: tokens.textPrimary,
            overlayColor: tokens.accent.withValues(alpha: 0.12),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryAndCalendarTab(MindTokens tokens, AppStrings strings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final traces = ref.watch(mindTraceControllerProvider).value ?? const [];
    final cases = ref.watch(savedCasesProvider).value ?? const [];
    final now = DateTime.now();
    final nextMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1);
    final canGoNext = nextMonth.isBefore(DateTime(now.year, now.month + 1));

    final visibleTraces = (_selectedDateKey != null
            ? traces.where((t) => t.dateKey == _selectedDateKey).toList()
            : List<MindTraceModel>.from(traces))
      ..sort((a, b) => b.date.compareTo(a.date));

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TrackMonthCalendar(
            month: _calendarMonth,
            traces: traces,
            selectedDateKey: _selectedDateKey,
            strings: strings,
            canGoNextMonth: canGoNext,
            onPreviousMonth: () {
              setState(() {
                _calendarMonth =
                    DateTime(_calendarMonth.year, _calendarMonth.month - 1);
                _selectedDateKey = null;
              });
            },
            onNextMonth: () {
              if (!canGoNext) return;
              setState(() {
                _calendarMonth = nextMonth;
                _selectedDateKey = null;
              });
            },
            onSelectDateKey: (dayKey) {
              setState(() => _selectedDateKey = dayKey);
            },
            onInspectTrace: (trace) => _handleInspectTrace(trace, strings),
          ),
          const SizedBox(height: 18),
          if (traces.isEmpty && cases.isEmpty)
            MindCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                children: [
                  HomeOrganicExerciseArt(size: 72, isDark: isDark),
                  const SizedBox(height: 14),
                  Text(
                    strings.timelineBuildsTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  MindButton(
                    text: strings.logTodayBtn,
                    leadingIcon: Icons.add_rounded,
                    onPressed: () => _tabController.animateTo(0),
                  ),
                ],
              ),
            )
          else ...[
            if (visibleTraces.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 10),
                child: Text(
                  strings.timelineOverline,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: tokens.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: strings.isArabic ? 0 : 0.6,
                  ),
                ),
              ),
            ],
            if (visibleTraces.isEmpty && _selectedDateKey != null)
              MindCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  strings.noEntriesForDayNote,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
            ...visibleTraces
                .take(20)
                .map((t) => _buildTraceCard(t, tokens, strings)),
            if (_selectedDateKey == null && cases.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                strings.recentCasesSection,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: tokens.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: strings.isArabic ? 0 : 0.6,
                ),
              ),
              const SizedBox(height: 8),
              ...cases.take(4).map((c) => _buildCaseCard(c, tokens, strings)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTraceCard(
    MindTraceModel t,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final moodStyle = trackMoodOptionFor(t.overallMood);
    final moodText = trackMoodLabel(t.overallMood, strings);
    final triggers = (t.situation ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MindCard(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 12, 14),
        onTap: () => _handleInspectTrace(t, strings),
        semanticLabel: '${t.dateKey} $moodText ${t.moodIntensity}/10',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${t.date.day}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    strings.shortMonthName(t.date.month),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: strings.isArabic ? 0 : 0.3,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(moodStyle.icon, size: 16, color: moodStyle.color),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '$moodText · ${t.moodIntensity}/10',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (triggers.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: triggers
                          .map(
                            (trig) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.surfaceSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: tokens.border),
                              ),
                              child: Text(
                                strings.trackTriggerDisplay(trig),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11.5,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (t.journalText != null &&
                      t.journalText!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      t.journalText!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: tokens.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Icon(
                isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                size: 18,
                color: tokens.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseCard(CaseModel c, MindTokens tokens, AppStrings strings) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MindCard(
        padding: const EdgeInsets.all(12),
        onTap: () => GoRouter.maybeOf(context)?.go('/case/${c.id}'),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tokens.accentSoft,
                borderRadius: BorderRadius.circular(tokens.chipRadius),
              ),
              child: Icon(
                Icons.psychology_outlined,
                size: 16,
                color: tokens.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.incidentDescription.isNotEmpty
                        ? c.incidentDescription
                        : strings.newInvestigation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.isCompleted
                        ? (strings.isArabic
                            ? 'مكتمل'
                            : (strings.isFrench
                                ? 'Recadrage résolu'
                                : 'Resolved Reframe'))
                        : (strings.isArabic
                            ? 'قيد البحث'
                            : (strings.isFrench ? 'En cours' : 'In Progress')),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: tokens.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              size: 18,
              color: tokens.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
