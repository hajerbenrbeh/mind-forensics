import 'dart:convert';
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
import '../../../core/widgets/mind_pressable.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/case_model.dart';
import '../../investigation/domain/case_stage.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../support/presentation/contextual_support_sheet.dart';
import 'widgets/home_active_case_card.dart';
import 'widgets/home_daily_check_in_card.dart';
import 'widgets/home_organic_exercise_art.dart';

/// The calm, uncluttered Home screen for v1.0:
/// Greeting, Daily Check-In, Active/Recent Investigations, and a single Breathing Reset shortcut.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

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

                const SizedBox(height: 18),

                // 2. DAILY CHECK-IN HERO
                _buildDailyCheckInCard(tokens, strings, isDark, todayTrace, traces),

                const SizedBox(height: 20),

                // 3. ACTIVE CASE OR START INVESTIGATION CARD
                if (activeCase != null && !activeCase.isCompleted)
                  _buildActiveCaseCard(activeCase, tokens, strings, isDark)
                else
                  _buildStartInvestigationCard(tokens, strings, isDark),

                const SizedBox(height: 20),

                // 4. GROUNDING & EXERCISES CARD (Single Clean Breathing Entry)
                _buildExercisesForYouCard(tokens, strings, isDark),

                const SizedBox(height: 22),

                // 5. RECENT INVESTIGATIONS SECTION (Up to 2 items)
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
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
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
