import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/mind_badge.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
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

  // Quick Check-in state
  String _selectedMood = 'calm';
  double _moodIntensity = 5.0;
  double _energyLevel = 5.0;
  double _anxietyLevel = 3.0;
  double _sleepHours = 7.5;
  final Set<String> _selectedTriggers = {};
  final TextEditingController _journalController = TextEditingController();
  bool _isSaving = false;

  final List<({String key, IconData icon, String label})> _moodOptions = const [
    (key: 'calm', icon: Icons.spa_outlined, label: 'Calm'),
    (key: 'anxious', icon: Icons.bolt_outlined, label: 'Anxious'),
    (key: 'frustrated', icon: Icons.local_fire_department_outlined, label: 'Frustrated'),
    (key: 'heavy', icon: Icons.grain_outlined, label: 'Heavy'),
    (key: 'restless', icon: Icons.air_outlined, label: 'Restless'),
  ];

  final List<String> _triggerOptions = const [
    'Work / Demands',
    'Interpersonal',
    'Sleep Disruption',
    'Health / Physical',
    'Cognitive Overload',
    'Routine Change',
    'Social Context',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _populateTodayExisting();
  }

  void _populateTodayExisting() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = ref.read(todayTraceProvider);
      if (today != null && mounted) {
        setState(() {
          _selectedMood = today.overallMood;
          _moodIntensity = today.moodIntensity.toDouble();
          _energyLevel = today.energyLevel.toDouble();
          _anxietyLevel = (today.anxietyLevel ?? 3).toDouble();
          _sleepHours = today.sleepHours ?? 7.5;
          if (today.journalText != null && today.journalText!.isNotEmpty) {
            _journalController.text = today.journalText!;
          }
          if (today.situation != null && today.situation!.isNotEmpty) {
            final parts = today.situation!.split(',').map((s) => s.trim());
            _selectedTriggers.addAll(parts.where((p) => p.isNotEmpty));
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _saveQuickCheckIn() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final today = ref.read(todayTraceProvider);
      final strings = ref.read(appStringsProvider);

      final situationStr = _selectedTriggers.isNotEmpty ? _selectedTriggers.join(', ') : null;

      final trace = (today != null)
          ? today.copyWith(
              overallMood: _selectedMood,
              moodIntensity: _moodIntensity.toInt(),
              energyLevel: _energyLevel.toInt(),
              anxietyLevel: _anxietyLevel.toInt(),
              sleepHours: _sleepHours,
              situation: situationStr,
              journalText: _journalController.text.trim().isNotEmpty
                  ? _journalController.text.trim()
                  : null,
              updatedAt: now,
            )
          : MindTraceModel(
              id: const Uuid().v4(),
              date: DateTime(now.year, now.month, now.day),
              overallMood: _selectedMood,
              moodIntensity: _moodIntensity.toInt(),
              energyLevel: _energyLevel.toInt(),
              anxietyLevel: _anxietyLevel.toInt(),
              sleepHours: _sleepHours,
              situation: situationStr,
              journalText: _journalController.text.trim().isNotEmpty
                  ? _journalController.text.trim()
                  : null,
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

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(strings.trackHubTitle),
        actions: const [
          SupportButton(),
          SizedBox(width: 8),
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
            Tab(text: strings.journalTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Quick Check-In (Fast, comfortable self-observation)
          _buildQuickCheckInView(tokens, strings),

          // 2. Detailed Mind Trace Stepper
          _buildDetailedTraceView(),

          // 3. Journal & Historical Case Vault
          _buildJournalAndArchiveView(tokens, strings),
        ],
      ),
    );
  }

  Widget _buildQuickCheckInView(MindTokens tokens, AppStrings strings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.trackHubSubtitle,
            style: TextStyle(color: tokens.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),

          // 1. Mood Selection
          Text(
            'TODAY\'S CORE STATE',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _moodOptions.map((opt) {
              final isSelected = _selectedMood == opt.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: MindCard(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: isSelected ? tokens.accentSoft : tokens.surface,
                    borderColor: isSelected ? tokens.accent : tokens.border,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMood = opt.key);
                    },
                    semanticLabel: opt.label,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          opt.icon,
                          size: 20,
                          color: isSelected ? tokens.accent : tokens.textSecondary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? tokens.accent : tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // 2. Intensity & Telemetry Sliders
          MindCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mood Intensity
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
                const Divider(height: 24, thickness: 0.5),

                // Sleep Duration
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
                const Divider(height: 24, thickness: 0.5),

                // Energy Level
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
                const Divider(height: 24, thickness: 0.5),

                // Anxiety / Stress
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

          const SizedBox(height: 20),

          // 3. Triggers & Context
          Text(
            strings.trackingTriggersLabel.toUpperCase(),
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _triggerOptions.map((trig) {
              final isSel = _selectedTriggers.contains(trig);
              return MindBadge(
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

          const SizedBox(height: 20),

          // 4. Today's Note
          Text(
            strings.todaysNoteLabel.toUpperCase(),
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _journalController,
            maxLines: 3,
            style: TextStyle(color: tokens.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: strings.todaysNoteHint,
            ),
          ),

          const SizedBox(height: 24),

          // Save Button
          MindButton(
            text: strings.saveCheckInButton,
            isFullWidth: true,
            isLoading: _isSaving,
            leadingIcon: Icons.check_circle_outline,
            onPressed: _saveQuickCheckIn,
          ),
          const SizedBox(height: 32),
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

  Widget _buildJournalAndArchiveView(MindTokens tokens, AppStrings strings) {
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
                'DAILY OBSERVATIONS',
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
                    c.incidentDescription.isNotEmpty ? c.incidentDescription : 'Deconstruction Case',
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
                    c.isCompleted ? 'Resolved Reframe' : 'In Progress',
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
                MindBadge(label: t.overallMood.toUpperCase()),
              ],
            ),
            if (t.journalText != null && t.journalText!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                t.journalText!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tokens.textPrimary, fontSize: 12.5),
              ),
            ],
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              children: [
                if (t.sleepHours != null)
                  Text('Sleep: ${t.sleepHours}h', style: TextStyle(color: tokens.textTertiary, fontSize: 11)),
                Text('Energy: ${t.energyLevel}/10', style: TextStyle(color: tokens.textTertiary, fontSize: 11)),
                if (t.anxietyLevel != null)
                  Text('Anxiety: ${t.anxietyLevel}/10', style: TextStyle(color: tokens.textTertiary, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
