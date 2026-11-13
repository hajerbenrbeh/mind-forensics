import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/crisis_keywords.dart';
import '../../../core/safety/safety_interceptor.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/mind_badge.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_pill.dart';
import '../../../core/widgets/radial_mood_dial.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/case_model.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../mind_trace/presentation/widgets/daily_mind_trace_stepper.dart';

/// Structured destination for self-observation and tracking.
///
/// Unites fast daily check-ins, sleep/energy telemetry, triggers,
/// thought tracking, and journal archives with minimum friction.
class TrackScreen extends ConsumerStatefulWidget {
  const TrackScreen({
    super.key,
    this.initialTab = 0,
  });

  final int initialTab;

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _noteController;

  // Quick Check-in state
  String _selectedMood = 'calm';
  double _moodIntensity = 5.0;
  double _energyLevel = 5.0;
  double _anxietyLevel = 3.0;
  double _sleepHours = 7.5;
  final Set<String> _selectedTriggers = {};
  final Set<String> _selectedHelped = {};
  bool _isSaving = false;
  bool _initializedFromTrace = false;

  final List<({String key, IconData icon})> _moodOptions = const [
    (key: 'calm', icon: Icons.sentiment_satisfied_outlined),
    (key: 'anxious', icon: Icons.sentiment_neutral_outlined),
    (key: 'frustrated', icon: Icons.sentiment_dissatisfied_outlined),
    (key: 'heavy', icon: Icons.sentiment_very_dissatisfied_outlined),
    (key: 'restless', icon: Icons.sentiment_neutral_outlined),
  ];

  final List<String> _triggerOptions = const [
    'Work / Demands',
    'Sleep Disruption',
    'Studies',
    'Social',
    'Health',
    'Overload',
  ];

  final List<String> _helpedOptions = const [
    'Walk',
    'Quiet time',
    'Breathing',
    'Talked',
    'Rest',
  ];

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hydrateFromTrace(ref.read(todayTraceProvider));
    });
  }

  void _hydrateFromTrace(MindTraceModel? trace) {
    if (_initializedFromTrace || trace == null) return;
    _initializedFromTrace = true;
    setState(() {
      _selectedMood = trace.overallMood;
      _moodIntensity = trace.moodIntensity.toDouble();
      _energyLevel = (trace.energyLevel ?? 5).toDouble();
      _anxietyLevel = (trace.anxietyLevel ?? 3).toDouble();
      _sleepHours = trace.sleepHours ?? 7.5;
      if (trace.journalText != null && _noteController.text.isEmpty) {
        _noteController.text = trace.journalText!;
      }
      if (trace.situation != null &&
          trace.situation!.isNotEmpty &&
          _selectedTriggers.isEmpty) {
        final parts = trace.situation!.split(',').map((s) => s.trim());
        _selectedTriggers.addAll(parts.where((p) => p.isNotEmpty));
      }
      if (trace.behavioralResponse != null &&
          trace.behavioralResponse!.isNotEmpty &&
          _selectedHelped.isEmpty) {
        final parts = trace.behavioralResponse!.split(',').map((s) => s.trim());
        _selectedHelped.addAll(parts.where((p) => p.isNotEmpty));
      }
    });
  }

  String _getMoodLabel(String key, AppStrings strings) {
    if (!strings.isArabic && !strings.isFrench) {
      switch (key) {
        case 'calm':
          return 'Calm';
        case 'anxious':
          return 'Anxious';
        case 'frustrated':
          return 'Frustrated';
        case 'heavy':
          return 'Heavy';
        case 'restless':
          return 'Restless';
        default:
          return key;
      }
    }
    switch (key) {
      case 'calm':
        return strings.moodCalm;
      case 'anxious':
        return strings.moodAnxious;
      case 'frustrated':
        return strings.moodFrustrated;
      case 'heavy':
        return strings.moodHeavy;
      case 'restless':
        return strings.moodRestless;
      default:
        return key;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveQuickCheckIn() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final today = ref.read(todayTraceProvider);
      final strings = ref.read(appStringsProvider);
      final authUser = ref.read(authControllerProvider).user;
      final userId = authUser?.id ?? 'local_user';

      final situationStr = _selectedTriggers.isNotEmpty ? _selectedTriggers.join(', ') : null;
      final helpedStr = _selectedHelped.isNotEmpty ? _selectedHelped.join(', ') : null;
      final noteText = _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null;

      // Layer 1 crisis pre-scan: Intercept Level 2 phrases immediately
      if (noteText != null && CrisisKeywords.evaluateText(noteText) == 2) {
        setState(() => _isSaving = false);
        if (mounted) {
          SafetyInterceptor.showCrisisPauseDialog(context);
        }
        return;
      }

      final trace = (today != null)
          ? today.copyWith(
              overallMood: _selectedMood,
              selectedEmotions: [_selectedMood],
              moodIntensity: _moodIntensity.toInt(),
              energyLevel: _energyLevel.toInt(),
              anxietyLevel: _anxietyLevel.toInt(),
              sleepHours: _sleepHours,
              situation: situationStr,
              behavioralResponse: helpedStr ?? today.behavioralResponse,
              journalText: noteText ?? today.journalText,
              updatedAt: now,
            )
          : MindTraceModel(
              id: const Uuid().v4(),
              userId: userId,
              date: DateTime(now.year, now.month, now.day),
              overallMood: _selectedMood,
              selectedEmotions: [_selectedMood],
              moodIntensity: _moodIntensity.toInt(),
              energyLevel: _energyLevel.toInt(),
              anxietyLevel: _anxietyLevel.toInt(),
              sleepHours: _sleepHours,
              situation: situationStr,
              behavioralResponse: helpedStr,
              journalText: noteText,
              createdAt: now,
              updatedAt: now,
            );

      await ref.read(mindTraceControllerProvider.notifier).recordCheckIn(trace, generateAi: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.tokens.surfaceSecondary,
            content: Text(
              strings.checkInSavedSnackbar,
              style: TextStyle(color: context.tokens.textPrimary, fontSize: 13),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final traces = ref.watch(mindTraceControllerProvider).value ?? const [];

    ref.listen<MindTraceModel?>(todayTraceProvider, (_, next) {
      if (!_initializedFromTrace && next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _hydrateFromTrace(next);
        });
      }
    });

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: tokens.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: tokens.textPrimary, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          strings.trackPageTitle,
          style: TextStyle(
            fontFamily: 'serif',
            color: tokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today_outlined, size: 20, color: tokens.textPrimary),
            tooltip: strings.calendarTitle,
            onPressed: () {
              HapticFeedback.lightImpact();
              _showObservationCalendarSheet(context, traces, tokens, strings);
            },
          ),
          const SupportButton(),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: tokens.accent,
          unselectedLabelColor: tokens.textSecondary,
          indicatorColor: tokens.accent,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: tokens.border,
          tabs: [
            Tab(text: strings.quickCheckInTab),
            Tab(text: strings.fullObservationTab),
            Tab(text: strings.traceHistoryTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Quick Check-In (Fast, comfortable self-observation matching Phone 3)
          _buildQuickCheckInView(tokens, strings),

          // 2. Detailed Mind Trace Stepper
          _buildDetailedTraceView(),

          // 3. Trace History & Past Investigations
          _buildHistoryView(tokens, strings),
        ],
      ),
    );
  }

  Widget _buildQuickCheckInView(MindTokens tokens, AppStrings strings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedMoodIndex = _moodOptions.indexWhere((m) => m.key == _selectedMood).clamp(0, 4);

    final dialMoodItems = _moodOptions.map((opt) {
      return MoodItem(
        key: opt.key,
        label: _getMoodLabel(opt.key, strings),
        icon: opt.icon,
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Question Header
          Text(
            strings.howFeelingRightNow,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),

          // 2. Radial Mood Dial with Concentric Ripples
          RadialMoodDial(
            moods: dialMoodItems,
            selectedIndex: selectedMoodIndex,
            showActiveLabel: false,
            onChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _selectedMood = _moodOptions[index].key);
            },
          ),
          const SizedBox(height: 12),

          // 3. Core State Selection
          Center(
            child: Text(
              strings.todaysCoreState,
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _moodOptions.map((opt) {
              final isSelected = _selectedMood == opt.key;
              final label = _getMoodLabel(opt.key, strings);
              final activeFg = isDark ? tokens.background : Colors.white;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: MindCard(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: isSelected ? tokens.accent : tokens.surface,
                    borderColor: isSelected ? tokens.accent : tokens.border,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMood = opt.key);
                    },
                    semanticLabel: label,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          opt.icon,
                          size: 20,
                          color: isSelected ? activeFg : tokens.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? activeFg : tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // 4. Optional Note Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18, color: tokens.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: tokens.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      hintText: strings.addNoteOptionalHint,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: tokens.textSecondary.withValues(alpha: 0.8),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 5. Influencing Factors / Triggers Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  strings.whatsInfluencingMood,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                strings.triggersContextHeader,
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
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
                label: trig,
                isSelected: isSel,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
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

          const SizedBox(height: 18),

          // 5b. What Helped Today? (Optional positive/calming factor pill)
          Text(
            strings.isArabic
                ? 'شنوّة اللي ساعدك اليوم؟ (اختياري)'
                : (strings.isFrench
                    ? 'Qu’est-ce qui vous a aidé ? (optionnel)'
                    : 'What helped today? (optional)'),
            style: TextStyle(
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
                label: item,
                isSelected: isSel,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
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

          const SizedBox(height: 20),

          // 6. Intensity & Telemetry Sliders
          MindCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSliderRow(
                  label: strings.moodIntensityLabel,
                  value: _moodIntensity,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  unit: '/10',
                  tokens: tokens,
                  onChanged: (v) => setState(() => _moodIntensity = v),
                ),
                const Divider(height: 20, thickness: 0.5),
                _buildSliderRow(
                  label: strings.sleepTrackingLabel,
                  value: _sleepHours,
                  min: 2,
                  max: 14,
                  divisions: 24,
                  unit: 'h',
                  tokens: tokens,
                  onChanged: (v) => setState(() => _sleepHours = v),
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
                  onChanged: (v) => setState(() => _energyLevel = v),
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
                  onChanged: (v) => setState(() => _anxietyLevel = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // 7. Save Entry Button (single crisp label, no redundant subText yapping)
          MindButton(
            text: strings.saveCheckInButton,
            isFullWidth: true,
            isLoading: _isSaving,
            leadingIcon: Icons.check_circle_outline,
            onPressed: _saveQuickCheckIn,
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                _tabController.animateTo(1);
              },
              icon: Icon(Icons.layers_outlined, size: 15, color: tokens.accent),
              label: Text(
                strings.deepenReflectionCta,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: tokens.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}$unit',
              style: TextStyle(
                color: tokens.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
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
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
          ),
          child: Slider(
            value: value,
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

  Widget _buildDetailedTraceView() {
    return Consumer(
      builder: (context, ref, _) {
        final todayTrace = ref.watch(todayTraceProvider);
        return DailyMindTraceStepper(
          initialTrace: todayTrace,
          onViewConstellation: () {
            _tabController.animateTo(2);
          },
          onReturnHome: () {
            _tabController.animateTo(0);
          },
        );
      },
    );
  }

  Widget _buildHistoryView(MindTokens tokens, AppStrings strings) {
    return Consumer(
      builder: (context, ref, _) {
        final traces = ref.watch(mindTraceControllerProvider).value ?? [];
        final cases = ref.watch(savedCasesProvider).value ?? [];

        if (traces.isEmpty && cases.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_edu_outlined, size: 40, color: tokens.textTertiary),
                  const SizedBox(height: 12),
                  Text(
                    strings.noCasesOnFile,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tokens.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Recent Cases Section
            if (cases.isNotEmpty) ...[
              Text(
                strings.recentCasesSection,
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              ...cases.take(4).map((c) => _buildCaseCard(c, tokens, strings)),
              const SizedBox(height: 20),
            ],

            // Daily Mind Traces
            if (traces.isNotEmpty) ...[
              Text(
                strings.isArabic
                    ? 'الملاحظات اليومية'
                    : (strings.isFrench ? 'OBSERVATIONS QUOTIDIENNES' : 'DAILY OBSERVATIONS'),
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              ...traces.take(10).map((t) => _buildTraceCard(t, tokens, strings)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCaseCard(CaseModel c, MindTokens tokens, AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MindCard(
        padding: const EdgeInsets.all(12),
        onTap: () => context.go('/case/${c.id}'),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tokens.accentSoft,
                borderRadius: BorderRadius.circular(tokens.chipRadius),
              ),
              child: Icon(Icons.psychology_outlined, size: 16, color: tokens.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.incidentDescription.isNotEmpty ? c.incidentDescription : strings.newInvestigation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.isCompleted
                        ? (strings.isArabic ? 'مكتمل' : (strings.isFrench ? 'Recadrage résolu' : 'Resolved Reframe'))
                        : (strings.isArabic ? 'قيد البحث' : (strings.isFrench ? 'En cours' : 'In Progress')),
                    style: TextStyle(color: tokens.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: tokens.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceCard(MindTraceModel t, MindTokens tokens, AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MindCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.dateKey,
                  style: TextStyle(color: tokens.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                MindBadge(label: _getMoodLabel(t.overallMood, strings).toUpperCase()),
              ],
            ),
            if (t.situation != null && t.situation!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                t.situation!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tokens.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              children: [
                if (t.sleepHours != null)
                  Text(
                    '${strings.isArabic ? "النوم" : (strings.isFrench ? "Sommeil" : "Sleep")}: ${t.sleepHours}h',
                    style: TextStyle(color: tokens.textTertiary, fontSize: 11),
                  ),
                if (t.energyLevel != null)
                  Text(
                    '${strings.isArabic ? "الطاقة" : (strings.isFrench ? "Énergie" : "Energy")}: ${t.energyLevel}/10',
                    style: TextStyle(color: tokens.textTertiary, fontSize: 11),
                  ),
                if (t.anxietyLevel != null)
                  Text(
                    '${strings.isArabic ? "القلق" : (strings.isFrench ? "Anxiété" : "Anxiety")}: ${t.anxietyLevel}/10',
                    style: TextStyle(color: tokens.textTertiary, fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showObservationCalendarSheet(
    BuildContext context,
    List<MindTraceModel> traces,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday; // Mon=1 .. Sun=7
    final byDay = <int, MindTraceModel>{};
    for (final t in traces) {
      if (t.date.year == now.year && t.date.month == now.month) {
        byDay[t.date.day] = t;
      }
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings.calendarTitle,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    MindBadge(label: '${now.year}-${now.month.toString().padLeft(2, '0')}'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  strings.calendarNoBreaksNote,
                  style: TextStyle(fontSize: 11.5, color: tokens.textSecondary),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: (firstWeekday - 1) + daysInMonth,
                  itemBuilder: (_, idx) {
                    if (idx < firstWeekday - 1) return const SizedBox.shrink();
                    final day = idx - (firstWeekday - 1) + 1;
                    final trace = byDay[day];
                    final isToday = day == now.day;

                    return InkWell(
                      onTap: trace == null
                          ? null
                          : () {
                              Navigator.of(ctx).pop();
                              _tabController.animateTo(2);
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: trace != null
                              ? tokens.accentSoft
                              : tokens.surfaceSecondary.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isToday
                                ? tokens.accent
                                : (trace != null ? tokens.accent.withValues(alpha: 0.4) : tokens.border),
                            width: isToday ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isToday || trace != null ? FontWeight.w700 : FontWeight.w500,
                                color: trace != null ? tokens.accent : tokens.textSecondary,
                              ),
                            ),
                            if (trace != null)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tokens.accent,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
