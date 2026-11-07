import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../core/widgets/fingerprint_thread_signature.dart';
import '../../../core/widgets/mind_badge.dart';
import '../../../core/widgets/neural_waveform_visualizer.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../insights/data/pattern_awareness_service.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/case_model.dart';
import '../../investigation/domain/case_stage.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../profile/controllers/profile_controller.dart';
import 'widgets/exercise_breathing_modal_sheet.dart';
import 'widgets/home_metric_sparkline.dart';
import 'widgets/home_organic_exercise_art.dart';
import 'widgets/home_stress_bar_chart.dart';
import 'widgets/home_time_segmented_switcher.dart';
import 'widgets/home_week_mood_tracker.dart';

/// The Home Dashboard screen: Calm, Human, Sophisticated Mental Health Companion.
///
/// Features:
/// - Real Data Integrity: Mood stability and stress bar charts strictly derive from
///   authentic user observations without fabricated values.
/// - Unified Check-in: Connected directly to [MindTraceController] and [todayTraceProvider].
/// - 7-day calendar mood tracker reflecting real daily check-in momentum.
/// - Two-column metric cards (20px radius) with authentic empty/calibrating states.
/// - Featured "Exercises for you" card with organic vector art and 4-4-4-4 Vagal Breathing.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTimeIndex = 1; // 0: Month, 1: Week, 2: Day
  DateTime _selectedDay = DateTime.now();

  int _selectedMoodIndex = 0;
  double _moodIntensity = 5.0;
  List<CaseModel> _recentCases = [];
  bool _isLoading = true;
  bool _initializedFromTrace = false;

  // Step 6: Daily Check-in & Note State
  final TextEditingController _todayNoteController = TextEditingController();

  final List<({String key, IconData icon})> _moodOptions = const [
    (key: 'calm', icon: Icons.spa_outlined),
    (key: 'anxious', icon: Icons.bolt_outlined),
    (key: 'frustrated', icon: Icons.local_fire_department_outlined),
    (key: 'heavy', icon: Icons.grain_outlined),
    (key: 'restless', icon: Icons.air_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentCases();
  }

  @override
  void dispose() {
    _todayNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentCases() async {
    final repo = ref.read(caseRepositoryProvider);
    final all = await repo.getAllCases();

    if (mounted) {
      setState(() {
        _recentCases = all.take(3).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDailyCheckIn() async {
    HapticFeedback.mediumImpact();
    final activeMood = _moodOptions[_selectedMoodIndex].key;
    final intensity = _moodIntensity.toInt();
    final note = _todayNoteController.text.trim();
    final todayTrace = ref.read(todayTraceProvider);
    final strings = ref.read(appStringsProvider);

    if (todayTrace != null) {
      // 1. Update existing trace for today
      final updated = todayTrace.copyWith(
        overallMood: activeMood,
        moodIntensity: intensity,
        journalText: note.isNotEmpty ? note : null,
        selectedEmotions: [activeMood],
        updatedAt: DateTime.now(),
      );
      await ref.read(mindTraceControllerProvider.notifier).updateCheckIn(updated);
    } else {
      // 2. Create new trace for today
      final now = DateTime.now();
      final newTrace = MindTraceModel(
        id: 'trace_${now.millisecondsSinceEpoch}',
        userId: ref.read(authControllerProvider).user?.id ?? 'local_user',
        date: now,
        overallMood: activeMood,
        moodIntensity: intensity,
        energyLevel: (10 - intensity).clamp(1, 9),
        selectedEmotions: [activeMood],
        journalText: note.isNotEmpty ? note : null,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(mindTraceControllerProvider.notifier).recordCheckIn(newTrace, generateAi: false);
    }

    // 3. Keep cache synchronized for backwards compatibility
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mf_last_checkin_mood', activeMood);
    await prefs.setInt('mf_last_checkin_intensity', intensity);
    await prefs.setString('mf_last_checkin_note', note);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF202925)
              : const Color(0xFF34443B),
          content: Text(
            strings.checkInSavedSnackbar,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _getLocalizedGreeting(AppStrings strings) {
    final hour = DateTime.now().hour;
    if (hour < 12) return strings.greetingMorning;
    if (hour < 18) return strings.greetingAfternoon;
    return strings.greetingEvening;
  }

  String _getMoodLabel(String key, AppStrings strings) {
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

  Color _getMoodColor(String key) {
    switch (key) {
      case 'calm':
        return const Color(0xFF91AD9A);
      case 'anxious':
        return const Color(0xFFFB7185);
      case 'frustrated':
        return const Color(0xFFFBBF24);
      case 'heavy':
        return const Color(0xFFA78BFA);
      case 'restless':
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFF91AD9A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final profile = ref.watch(profileControllerProvider).value;
    final userName = profile?.preferredName.isNotEmpty == true
        ? profile!.preferredName
        : (strings.isArabic ? 'صديقي' : 'Friend');

    final activeCase = ref.watch(activeCaseControllerProvider).value;
    final traces = ref.watch(mindTraceControllerProvider).value ?? [];
    final todayTrace = ref.watch(todayTraceProvider);

    // Hydrate local check-in fields once from today's saved trace
    if (!_initializedFromTrace && todayTrace != null) {
      _initializedFromTrace = true;
      final moodIdx = _moodOptions.indexWhere((m) => m.key == todayTrace.overallMood);
      if (moodIdx != -1) _selectedMoodIndex = moodIdx;
      _moodIntensity = todayTrace.moodIntensity.toDouble();
      if (todayTrace.journalText != null && _todayNoteController.text.isEmpty) {
        _todayNoteController.text = todayTrace.journalText!;
      }
    }

    // Build authentic map of dateKey -> moodColor from real user traces
    final Map<String, Color> recordedMoodDays = {
      for (final t in traces)
        t.dateKey: _getMoodColor(t.overallMood),
    };

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: tokens.background,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FingerprintThreadSignature(size: 18, animated: false),
            const SizedBox(width: 6),
            Text(
              'Mind Forensics',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
        actions: const [
          SupportButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadRecentCases();
            ref.invalidate(mindTraceControllerProvider);
          },
          color: tokens.accent,
          backgroundColor: tokens.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP HEADER: "Dear [Name], \n good morning"
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.dearUserGreeting(userName),
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w500,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getLocalizedGreeting(strings),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 2. SEGMENTED TIME SWITCHER: "Month | Week | Day" (30px radius)
                HomeTimeSegmentedSwitcher(
                  selectedIndex: _selectedTimeIndex,
                  onChanged: (index) {
                    setState(() => _selectedTimeIndex = index);
                  },
                  labels: [
                    strings.timeSwitcherMonth,
                    strings.timeSwitcherWeek,
                    strings.timeSwitcherDay,
                  ],
                ),

                const SizedBox(height: 18),

                // 3. HORIZONTAL 7-DAY MOOD TRACKER (Real recorded moods only)
                HomeWeekMoodTracker(
                  selectedDay: _selectedDay,
                  recordedMoodDays: recordedMoodDays,
                  onDaySelected: (day) {
                    setState(() => _selectedDay = day);
                  },
                ),

                const SizedBox(height: 22),

                // 4. TWO-COLUMN METRIC CARDS (20px radius, Real Data & Empty States)
                _buildTwoColumnMetricCards(tokens, strings, isDark, traces),

                const SizedBox(height: 24),

                // 5. "EXERCISES FOR YOU" / "SUGGESTED FOR YOU" CARD (20px radius)
                _buildExercisesForYouCard(tokens, strings, isDark),

                const SizedBox(height: 24),

                // 6. STEP 6: DAILY CHECK-IN & NOTE (20px radius, Unified with Mind Trace)
                _buildDailyCheckInCard(tokens, strings, isDark, todayTrace, traces),

                const SizedBox(height: 24),

                // 7. ACTIVE CASE OR START INVESTIGATION CARD (20px radius)
                if (activeCase != null && !activeCase.isCompleted)
                  _buildActiveCaseCard(activeCase, tokens, strings, isDark)
                else
                  _buildStartInvestigationCard(tokens, strings, isDark),

                const SizedBox(height: 20),

                // 8. PATTERN AWARENESS DIVERGENCE BANNER (20px radius)
                _buildPatternAwarenessCard(tokens, strings, isDark),

                const SizedBox(height: 20),

                // 9. QUICK ACCESS ACTIONS (16px radius)
                _buildQuickAccessGrid(tokens, strings, isDark),

                const SizedBox(height: 24),

                // 10. RECENT INVESTIGATIONS SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings.recentCasesSection,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: tokens.textSecondary,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/journal'),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          strings.viewAll.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_recentCases.isEmpty)
                  _buildNoCasesCard(tokens, strings)
                else
                  ..._recentCases.map((c) => _buildRecentCaseTile(c, tokens, strings, isDark)),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION BUILDERS
  // ===========================================================================

  Widget _buildTwoColumnMetricCards(
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
    List<MindTraceModel> traces,
  ) {
    // 1. Mood stability sparkline (Real data derivation)
    final recentTraces = traces.take(7).toList();
    final hasSufficientMoodData = recentTraces.length >= 2;
    final List<double> sparklineValues = hasSufficientMoodData
        ? recentTraces.map((t) => t.moodIntensity.toDouble()).toList().reversed.toList()
        : const [];

    String moodHeadline;
    String moodSubtitle;

    if (!hasSufficientMoodData) {
      moodHeadline = strings.calibratingBaseline;
      moodSubtitle = strings.needsTwoEntries;
    } else {
      final mean = sparklineValues.reduce((a, b) => a + b) / sparklineValues.length;
      final variance = sparklineValues
              .map((v) => (v - mean) * (v - mean))
              .reduce((a, b) => a + b) /
          sparklineValues.length;
      final stdDev = math.sqrt(variance);
      final isStable = stdDev <= 1.5;
      moodHeadline = isStable ? strings.moodStable : strings.moodUnstable;
      moodSubtitle = '${sparklineValues.length} ${strings.isArabic ? "تسجيلات" : "entries"} (${strings.lastWeekLabel})';
    }

    // 2. Weekly stress bar chart (Monday to Sunday authentic records)
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 7));

    final weekTraces = traces.where((t) {
      return !t.date.isBefore(weekStart) && t.date.isBefore(weekEnd);
    }).toList();

    final List<double?> stressBarValues = List<double?>.generate(7, (i) {
      final targetDate = weekStart.add(Duration(days: i));
      final dayTrace = weekTraces.where((t) =>
          t.date.year == targetDate.year &&
          t.date.month == targetDate.month &&
          t.date.day == targetDate.day).firstOrNull;
      if (dayTrace == null) return null;
      return (dayTrace.anxietyLevel ?? (10 - dayTrace.energyLevel)).toDouble();
    });

    String stressHeadline;
    String stressSubtitle;

    final loggedStressValues = stressBarValues.whereType<double>().toList();
    if (loggedStressValues.isEmpty) {
      stressHeadline = strings.noEntriesThisWeek;
      stressSubtitle = strings.avgStressLevel;
    } else {
      final avgStress = loggedStressValues.reduce((a, b) => a + b) / loggedStressValues.length;
      final percent = (avgStress / 10.0 * 100).round();
      stressHeadline = '$percent% ${strings.inAWeek}';
      stressSubtitle = '${loggedStressValues.length}/7 ${strings.isArabic ? "أيام مسجلة" : "days tracked"}';
    }

    return Row(
      children: [
        // Left Card: Mood Stability
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: tokens.border, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeMetricSparkline(
                  values: sparklineValues,
                  lineColor: tokens.accent,
                  height: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  moodSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  moodHeadline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: tokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Right Card: Average Stress Level
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: tokens.border, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeStressBarChart(
                  values: stressBarValues,
                  isDark: isDark,
                  height: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  stressSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stressHeadline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: tokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExercisesForYouCard(
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.exercisesForYou,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        BouncingWidget(
          onTap: () {
            HapticFeedback.mediumImpact();
            ExerciseBreathingModalSheet.show(context, strings);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: tokens.border, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Calming Organic Vector Art (ZERO emojis)
                HomeOrganicExerciseArt(
                  size: 64,
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.relieveStress,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        strings.breathingPractice,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.hourglass_empty_rounded,
                            size: 13,
                            color: tokens.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            strings.duration5Min,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: tokens.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyCheckInCard(
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
    MindTraceModel? todayTrace,
    List<MindTraceModel> traces,
  ) {
    final activeMood = _moodOptions[_selectedMoodIndex].key;
    final activeMoodColor = _getMoodColor(activeMood);
    final hasLoggedToday = todayTrace != null;

    // Retrieve previous historical trace if today is not yet logged
    final previousTrace = traces.firstOrNull;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: tokens.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Authentic History Indicator: Today's recorded status or previous trace
          if (hasLoggedToday) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF26322C) : const Color(0xFFE5ECE6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.accent.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 15, color: tokens.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${strings.todayCheckInRecorded}: ${_getMoodLabel(todayTrace.overallMood, strings)} (${todayTrace.moodIntensity}/10)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/mind-trace'),
                    child: Text(
                      (strings.isArabic ? 'عرض' : 'VIEW').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (previousTrace != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF26322C) : const Color(0xFFE5ECE6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 15, color: tokens.accent),
                  const SizedBox(width: 8),
                  Text(
                    '${strings.lastMoodLabel.toUpperCase()}: ${_getMoodLabel(previousTrace.overallMood, strings)} (${previousTrace.moodIntensity}/10)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  if (previousTrace.journalText != null && previousTrace.journalText!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '•  "${previousTrace.journalText!}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${strings.moodIntensityLabel.toUpperCase()}: ${_moodIntensity.toInt()}/10',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: tokens.textSecondary,
                ),
              ),
              Icon(
                _moodOptions[_selectedMoodIndex].icon,
                size: 20,
                color: activeMoodColor,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeMoodColor,
              thumbColor: activeMoodColor,
              inactiveTrackColor: isDark ? const Color(0xFF303E37) : const Color(0xFFE5ECE6),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _moodIntensity,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() => _moodIntensity = val);
              },
            ),
          ),
          const SizedBox(height: 10),

          // Real-time animated neural waveform canvas
          NeuralWaveformVisualizer(
            intensity: _moodIntensity,
            moodColor: activeMoodColor,
            isDark: isDark,
            strings: strings,
          ),

          const SizedBox(height: 14),

          // Emotion selector pills (24px radius)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_moodOptions.length, (index) {
                final option = _moodOptions[index];
                final isSelected = index == _selectedMoodIndex;
                final label = _getMoodLabel(option.key, strings);
                final moodColor = _getMoodColor(option.key);

                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: BouncingWidget(
                    onTap: () {
                      setState(() => _selectedMoodIndex = index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF303E37) : const Color(0xFFE5ECE6))
                            : tokens.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? moodColor : tokens.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            option.icon,
                            size: 15,
                            color: isSelected ? moodColor : tokens.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? tokens.textPrimary : tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          // Free-text "Today's Note"
          Text(
            strings.todaysNoteLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _todayNoteController,
            maxLines: 2,
            minLines: 1,
            style: TextStyle(fontSize: 13, color: tokens.textPrimary),
            decoration: InputDecoration(
              hintText: strings.todaysNoteHint,
              hintStyle: TextStyle(fontSize: 12.5, color: tokens.textSecondary.withValues(alpha: 0.7)),
              filled: true,
              fillColor: isDark ? const Color(0xFF151B19) : const Color(0xFFF7F8F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: tokens.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: tokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: tokens.accent, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Save / Update Action Button (20px pill radius)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: _saveDailyCheckIn,
              icon: Icon(
                hasLoggedToday ? Icons.refresh_rounded : Icons.check_circle_outline_rounded,
                size: 16,
              ),
              label: Text(hasLoggedToday ? strings.updateCheckInButton : strings.saveCheckInButton),
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? tokens.accent : const Color(0xFF34443B),
                foregroundColor: isDark ? const Color(0xFF151B19) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCaseCard(
    CaseModel c,
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
  ) {
    final progress = c.currentStage.stepNumber / 6.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: tokens.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MindBadge(
                label: '${strings.formatSessionNumber(c.caseNumber)}  •  ${strings.stageNumberLabel(c.currentStage.stepNumber)}',
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: tokens.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            c.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: tokens.surfaceSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(tokens.accent),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await context.push('/investigation');
                _loadRecentCases();
              },
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? tokens.accent : const Color(0xFF34443B),
                foregroundColor: isDark ? const Color(0xFF151B19) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                strings.resumeInvestigation,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartInvestigationCard(
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: tokens.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF303E37) : const Color(0xFFE5ECE6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.bolt_rounded, color: tokens.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.startInvestigation,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.startInvestigationSub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: tokens.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await context.push('/investigation');
                _loadRecentCases();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(strings.newInvestigation),
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? tokens.accent : const Color(0xFF34443B),
                foregroundColor: isDark ? const Color(0xFF151B19) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickCatalystPill(
                  label: strings.catalystUnanswered,
                  icon: Icons.mark_email_unread_outlined,
                  tokens: tokens,
                ),
                const SizedBox(width: 8),
                _buildQuickCatalystPill(
                  label: strings.catalystCritique,
                  icon: Icons.chat_bubble_outline_rounded,
                  tokens: tokens,
                ),
                const SizedBox(width: 8),
                _buildQuickCatalystPill(
                  label: strings.catalystOverload,
                  icon: Icons.timer_outlined,
                  tokens: tokens,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCatalystPill({
    required String label,
    required IconData icon,
    required MindTokens tokens,
  }) {
    return BouncingWidget(
      onTap: () async {
        HapticFeedback.mediumImpact();
        await ref.read(activeCaseControllerProvider.notifier).startNewCase(label);
        await ref.read(activeCaseControllerProvider.notifier).advanceStage(CaseStage.evidence);
        if (mounted) {
          await context.push('/investigation');
          _loadRecentCases();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: tokens.surfaceSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: tokens.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternAwarenessCard(
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
  ) {
    final divergences = ref.watch(patternDivergencesProvider);
    final baseline = ref.watch(personalBaselineProvider);

    if (divergences.isEmpty) {
      if (!baseline.hasSufficientData) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 18, color: tokens.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                strings.isArabic
                    ? 'خط الأساس الشخصي نشط • ${baseline.totalRecordedDays} أيام مسجلة'
                    : 'Personal Baseline active • ${baseline.totalRecordedDays} observation days calibrated',
                style: TextStyle(fontSize: 12, color: tokens.textSecondary),
              ),
            ),
            InkWell(
              onTap: () => context.push('/insights'),
              child: Text(
                (strings.isArabic ? 'عرض' : 'VIEW').toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tokens.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    final d = divergences.first;
    return InkWell(
      onTap: () => context.push('/insights'),
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: tokens.accent.withValues(alpha: 0.6), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_outlined, size: 18, color: tokens.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d.title,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: tokens.textPrimary),
                  ),
                ),
                MindBadge(label: d.timeWindow),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              d.baselineComparison,
              style: TextStyle(fontSize: 12, color: tokens.textSecondary, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
  ) {
    final actions = [
      (
        title: strings.isArabic ? 'كتابة فكرة' : 'Write a thought',
        subtitle: strings.isArabic ? 'تفكيك معرفي' : 'Case deconstruction',
        icon: Icons.edit_note_rounded,
        onTap: () => context.push('/investigation'),
      ),
      (
        title: strings.isArabic ? 'محادثة الرفيق' : 'Talk to AI',
        subtitle: strings.isArabic ? 'حوار استكشافي' : 'Exploration dialogue',
        icon: Icons.psychology_outlined,
        onTap: () => context.push('/investigation'),
      ),
      (
        title: strings.isArabic ? 'تتبّع ورصد' : 'Track & Observe',
        subtitle: strings.isArabic ? 'النوم، المزاج، المحفزات' : 'Sleep, mood, triggers',
        icon: Icons.edit_calendar_outlined,
        onTap: () => context.push('/track'),
      ),
      (
        title: strings.isArabic ? 'التحليلات والأنماط' : 'Insights & Patterns',
        subtitle: strings.isArabic ? 'خط الأساس والتغيرات' : 'Baseline & trends',
        icon: Icons.insights_outlined,
        onTap: () => context.push('/insights'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (strings.isArabic ? 'وصول سريع' : 'QUICK ACCESS').toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildQuickActionCard(actions[0], tokens)),
            const SizedBox(width: 10),
            Expanded(child: _buildQuickActionCard(actions[1], tokens)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildQuickActionCard(actions[2], tokens)),
            const SizedBox(width: 10),
            Expanded(child: _buildQuickActionCard(actions[3], tokens)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    ({String title, String subtitle, IconData icon, VoidCallback onTap}) action,
    MindTokens tokens,
  ) {
    return BouncingWidget(
      onTap: () {
        HapticFeedback.lightImpact();
        action.onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          children: [
            Icon(action.icon, size: 18, color: tokens.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  Text(
                    action.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: tokens.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCasesCard(MindTokens tokens, AppStrings strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: tokens.border, width: 1),
      ),
      child: Center(
        child: Text(
          strings.noCasesOnFile,
          style: TextStyle(fontSize: 11.5, letterSpacing: 0.5, fontWeight: FontWeight.w600, color: tokens.textSecondary),
        ),
      ),
    );
  }

  Widget _buildRecentCaseTile(
    CaseModel c,
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: tokens.border, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tokens.surfaceSecondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            c.isCompleted ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
            size: 18,
            color: c.isCompleted ? tokens.accent : const Color(0xFFFB7185),
          ),
        ),
        title: Text(
          c.title,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: tokens.textPrimary),
        ),
        subtitle: Text(
          '${strings.formatSessionNumber(c.caseNumber)}  •  ${strings.stageNumberLabel(c.currentStage.stepNumber)}',
          style: TextStyle(
            fontSize: 11,
            color: tokens.textSecondary,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: tokens.textSecondary),
        onTap: () async {
          HapticFeedback.lightImpact();
          if (c.isCompleted) {
            await context.push('/case/${c.id}');
          } else {
            ref.read(activeCaseControllerProvider.notifier).resumeCase(c);
            await context.push('/investigation');
          }
          _loadRecentCases();
        },
      ),
    );
  }
}
