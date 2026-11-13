import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/crisis_keywords.dart';
import '../../../core/safety/safety_interceptor.dart';
import '../../../core/security/encrypted_storage_helper.dart';
import '../../../core/security/secure_key_manager.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../core/widgets/fingerprint_thread_signature.dart';
import '../../../core/widgets/mind_badge.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/organic_wave_art.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../insights/data/pattern_awareness_service.dart';
import '../../insights/domain/personal_baseline_model.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/case_model.dart';
import '../../investigation/domain/case_stage.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../support/presentation/contextual_support_sheet.dart';
import 'widgets/home_active_case_card.dart';
import 'widgets/home_daily_check_in_card.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initializedFromTrace) return;
      final today = ref.read(todayTraceProvider);
      if (today != null) {
        setState(() {
          _hydrateFromTrace(today);
        });
      }
    });
  }

  void _hydrateFromTrace(MindTraceModel trace) {
    _initializedFromTrace = true;
    final moodIdx = _moodOptions.indexWhere((m) => m.key == trace.overallMood);
    if (moodIdx != -1) _selectedMoodIndex = moodIdx;
    _moodIntensity = trace.moodIntensity.toDouble();
    if (trace.journalText != null && trace.journalText!.isNotEmpty) {
      _todayNoteController.text = trace.journalText!;
    }
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
        _recentCases = all.take(2).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDailyCheckIn() async {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final activeMood = _moodOptions[_selectedMoodIndex].key;
    final intensity = _moodIntensity.toInt();
    final todayTrace = ref.read(todayTraceProvider);
    final strings = ref.read(appStringsProvider);
    final noteText = _todayNoteController.text.trim().isNotEmpty
        ? _todayNoteController.text.trim()
        : null;

    // Layer 1 crisis pre-scan: Intercept Level 2 phrases immediately
    if (noteText != null && CrisisKeywords.evaluateText(noteText) == 2) {
      SafetyInterceptor.showCrisisPauseDialog(context);
      return;
    }

    if (todayTrace != null) {
      // 1. Update existing trace for today
      final updated = todayTrace.copyWith(
        overallMood: activeMood,
        moodIntensity: intensity,
        selectedEmotions: [activeMood],
        journalText: noteText ?? todayTrace.journalText,
        updatedAt: now,
      );
      await ref.read(mindTraceControllerProvider.notifier).updateCheckIn(updated);
    } else {
      // 2. Create new options-first trace for today
      final newTrace = MindTraceModel(
        id: 'trace_${now.millisecondsSinceEpoch}',
        userId: ref.read(authControllerProvider).user?.id ?? 'local_user',
        date: now,
        overallMood: activeMood,
        moodIntensity: intensity,
        energyLevel: (10 - intensity).clamp(1, 9),
        selectedEmotions: [activeMood],
        journalText: noteText,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(mindTraceControllerProvider.notifier).recordCheckIn(newTrace, generateAi: false);
    }

    // 3. Keep cache synchronized with authenticated encryption at rest
    final prefs = await SharedPreferences.getInstance();
    final keyManager = ref.read(secureKeyManagerProvider);
    final authState = ref.read(authControllerProvider);
    final cipher = await keyManager.getCipherForUser(authState.user?.id);
    await EncryptedStorageHelper.writeEncrypted(
      prefs: prefs,
      key: 'mf_last_checkin_cache_v1',
      plaintext: jsonEncode({
        'mood': activeMood,
        'intensity': intensity,
        'timestamp': now.toIso8601String(),
      }),
      cipher: cipher,
    );
    await prefs.remove('mf_last_checkin_mood');
    await prefs.remove('mf_last_checkin_intensity');

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
        return LabColors.moodCalm;
      case 'anxious':
        return LabColors.moodAnxious; // Warm Sand / Desert Dune (replaces bright pink)
      case 'frustrated':
        return LabColors.moodFrustrated; // Warm Amber
      case 'heavy':
        return LabColors.moodHeavy; // Soft Iris
      case 'restless':
        return LabColors.moodRestless; // Mineral Mist
      default:
        return LabColors.moodCalm;
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
        : (strings.isArabic ? 'صديقي' : (strings.isFrench ? 'Ami' : 'Friend'));

    final activeCase = ref.watch(activeCaseControllerProvider).value;
    final traces = ref.watch(mindTraceControllerProvider).value ?? [];
    final todayTrace = traces.todayTrace;

    if (!_initializedFromTrace && todayTrace != null) {
      _initializedFromTrace = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _hydrateFromTrace(todayTrace);
        });
      });
    }

    // Build authentic map of dateKey -> moodColor from real user traces
    final Map<String, Color> recordedMoodDays = {
      for (final t in traces)
        t.dateKey: _getMoodColor(t.overallMood),
    };

    final String phaseTitle;
    final String phaseSubtitle;
    if (todayTrace != null) {
      phaseTitle = _getMoodLabel(todayTrace.overallMood, strings);
      phaseSubtitle = strings.isArabic
          ? 'شدة ${todayTrace.moodIntensity}/10 • مسجّل اليوم'
          : (strings.isFrench
              ? 'Intensité ${todayTrace.moodIntensity}/10 • Enregistré aujourd’hui'
              : 'Intensity ${todayTrace.moodIntensity}/10 • Logged today');
    } else if (traces.isNotEmpty) {
      phaseTitle = strings.isArabic ? 'مسار نشط' : (strings.isFrench ? 'Suivi actif' : 'Active Rhythm');
      phaseSubtitle = strings.isArabic
          ? '${traces.length} ملاحظات مسجّلة'
          : (strings.isFrench ? '${traces.length} observations enregistrées' : '${traces.length} observations recorded');
    } else {
      phaseTitle = strings.isArabic ? 'مستعد للرصد' : (strings.isFrench ? 'Prêt pour le bilan' : 'Ready to Check In');
      phaseSubtitle = strings.isArabic
          ? 'لحظة هادئة بلا أي ضغط'
          : (strings.isFrench ? 'Un moment calme sans pression' : 'A calm moment with zero pressure');
    }

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
            Flexible(
              child: Text(
                'Mind Forensics',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: tokens.textPrimary,
                ),
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
                // 1. TOP HEADER ROW (Crisp single greeting + Mind Assistant & Avatar)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.dearUserGreeting(userName),
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: tokens.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _getLocalizedGreeting(strings),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MindPressable(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.push(AppRouter.companion);
                          },
                          semanticLabel: strings.mindAssistantTitle,
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tokens.surface,
                                  border: Border.all(
                                    color: tokens.border,
                                    width: 1.0,
                                  ),
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 18,
                                  color: tokens.accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: tokens.accent,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: (profile?.preferredName.isNotEmpty == true && profile!.preferredName != 'Friend')
                              ? Text(
                                  profile.preferredName[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? tokens.background : Colors.white,
                                  ),
                                )
                              : Icon(
                                  Icons.person_outline_rounded,
                                  size: 19,
                                  color: isDark ? tokens.background : Colors.white,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (profile?.isMinor == true) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: tokens.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tokens.accent.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, size: 13, color: tokens.accent),
                        const SizedBox(width: 6),
                        Text(
                          strings.isArabic
                              ? 'مساحة استبصار آمنة • خطوط الطوارئ متاحة'
                              : (strings.isFrench
                                  ? 'Espace de réflexion sûr • Lignes d’aide disponibles'
                                  : 'Safe reflection space • Helplines available'),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tokens.accent),
                        ),
                      ],
                    ),
                  ),
                ],
                if (profile != null && (profile.selectedGoals.isNotEmpty || profile.personalGoals.isNotEmpty)) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: tokens.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tokens.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag_outlined, size: 13, color: tokens.accent),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  profile.selectedGoals.isNotEmpty
                                      ? profile.selectedGoals.first
                                      : profile.personalGoals.split(', ').first,
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
                ],

                const SizedBox(height: 18),

                // 2. AUTHENTIC CURRENT STATE CARD + JOURNEY ENTRY
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                    border: Border.all(
                      color: tokens.border,
                      width: 1.0,
                    ),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: tokens.textPrimary.withValues(alpha: 0.035),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.isArabic ? 'حالتك الحالية' : (strings.isFrench ? 'Votre état actuel' : 'Your current focus'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: tokens.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  phaseTitle,
                                  style: TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 23,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.3,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  phaseSubtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: tokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const OrganicWaveArt(height: 82),
                        ],
                      ),
                      PositionedDirectional(
                        bottom: 9,
                        end: 9,
                        child: MindPressable(
                          semanticLabel: strings.viewDetailsTooltip,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.push(AppRouter.journey);
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: tokens.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: isDark ? tokens.background : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 3. DAILY CHECK-IN HERO + MOOD-AWARE NEXT STEP
                _buildDailyCheckInCard(tokens, strings, isDark, todayTrace, traces),
                if (todayTrace != null) ...[
                  const SizedBox(height: 12),
                  _buildMoodAwareNextStepCard(todayTrace, tokens, strings, isDark),
                ],

                const SizedBox(height: 20),

                // 4. SEGMENTED TIME SWITCHER & WEEKLY RHYTHM
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

                const SizedBox(height: 16),

                HomeWeekMoodTracker(
                  selectedDay: _selectedDay,
                  recordedMoodDays: recordedMoodDays,
                  onDaySelected: (day) {
                    setState(() => _selectedDay = day);
                  },
                ),

                const SizedBox(height: 18),

                // 5. TWO-COLUMN METRIC CARDS (Real Data & Calibrating States)
                _buildTwoColumnMetricCards(tokens, strings, isDark, traces),

                const SizedBox(height: 22),

                // 6. GROUNDING & EXERCISES CARD (Single Clean Breathing Entry)
                _buildExercisesForYouCard(tokens, strings, isDark),

                const SizedBox(height: 22),

                // 7. ACTIVE CASE OR START INVESTIGATION CARD
                if (activeCase != null && !activeCase.isCompleted)
                  _buildActiveCaseCard(activeCase, tokens, strings, isDark)
                else
                  _buildStartInvestigationCard(tokens, strings, isDark),

                const SizedBox(height: 18),

                // 8. PATTERN AWARENESS DIVERGENCE BANNER
                _buildPatternAwarenessCard(tokens, strings, isDark, traces),

                const SizedBox(height: 22),

                // 9. RECENT INVESTIGATIONS SECTION (Up to 2 items)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        strings.recentCasesSection,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => context.push('/investigation'),
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
      return (dayTrace.anxietyLevel ?? (10 - (dayTrace.energyLevel ?? 5))).toDouble();
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
            ContextualSupportSheet.show(
              context,
              initialChoice: SupportChoice.settle,
            );
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

  Widget _buildMoodAwareNextStepCard(
    MindTraceModel todayTrace,
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
  ) {
    final mood = todayTrace.overallMood;
    final bool isAnxiousOrRestless = mood == 'anxious' || mood == 'restless';
    final bool isHeavyOrFrustrated = mood == 'heavy' || mood == 'frustrated';

    final String prompt = isAnxiousOrRestless
        ? strings.nextStepSettlePrompt
        : (isHeavyOrFrustrated ? strings.nextStepThoughtPrompt : strings.nextStepAnchorPrompt);
    final IconData icon = isAnxiousOrRestless
        ? Icons.air_rounded
        : (isHeavyOrFrustrated ? Icons.psychology_outlined : Icons.spa_outlined);

    return BouncingWidget(
      onTap: () {
        HapticFeedback.lightImpact();
        if (isAnxiousOrRestless) {
          ContextualSupportSheet.show(context, initialChoice: SupportChoice.settle);
        } else if (isHeavyOrFrustrated) {
          context.push(AppRouter.companion);
        } else {
          context.go(AppRouter.track);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.accentSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: tokens.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                prompt,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: tokens.accent),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyCheckInCard(
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
    MindTraceModel? todayTrace,
    List<MindTraceModel> traces,
  ) {
    return HomeDailyCheckInCard(
      tokens: tokens,
      strings: strings,
      isDark: isDark,
      todayTrace: todayTrace,
      traces: traces,
      selectedMoodIndex: _selectedMoodIndex,
      moodIntensity: _moodIntensity,
      todayNoteController: _todayNoteController,
      moodOptions: _moodOptions,
      onMoodSelected: (idx) => setState(() => _selectedMoodIndex = idx),
      onIntensityChanged: (val) => setState(() => _moodIntensity = val),
      onSave: _saveDailyCheckIn,
      getMoodLabel: _getMoodLabel,
      getMoodColor: _getMoodColor,
    );
  }

  Widget _buildActiveCaseCard(
    CaseModel c,
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
  ) {
    return HomeActiveCaseCard(
      caseModel: c,
      tokens: tokens,
      strings: strings,
      isDark: isDark,
      onResume: () async {
        await context.push('/investigation');
        _loadRecentCases();
      },
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
    List<MindTraceModel> traces,
  ) {
    final baseline = PersonalBaseline.fromTraces(traces);
    final divergences = PatternAwarenessService.detectDivergences(traces: traces, baseline: baseline);

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
                    : (strings.isFrench
                        ? 'Référence personnelle active • ${baseline.totalRecordedDays} jours enregistrés'
                        : 'Personal Baseline active • ${baseline.totalRecordedDays} observation days calibrated'),
                style: TextStyle(fontSize: 12, color: tokens.textSecondary),
              ),
            ),
            InkWell(
              onTap: () => context.push('/insights'),
              child: Text(
                (strings.isArabic
                        ? 'عرض'
                        : (strings.isFrench ? 'VOIR' : 'VIEW'))
                    .toUpperCase(),
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
            color: c.isCompleted ? tokens.accent : tokens.textSecondary,
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
