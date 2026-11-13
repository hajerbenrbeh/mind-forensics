import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../core/widgets/fingerprint_thread_signature.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../journey/controllers/journey_controller.dart';
import '../../observatory/domain/default_symptom_library.dart';
import '../../observatory/domain/symptom_entry.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/domain/condition_type.dart';
import '../../profile/domain/diagnostic_status.dart';
import '../../profile/domain/psychological_profile_model.dart';

/// The 1-Question-Per-Screen Adaptive First-Launch Onboarding for Mind Forensics.
///
/// Focused strictly on understanding the user, their needs, and safety:
/// 0: Welcome & Privacy Philosophy (honest private on-device storage)
/// 1: Basic Information (Age range with minor safeguards, optional physiological context)
/// 2: Mental-Health Background (6 starting points; adaptive branching)
/// 3: Conditions (Searchable multi-select with Diagnosed vs. Suspected distinction;
///    adaptively bypassed for non-diagnosed users unless opted in)
/// 4: Symptoms & Difficulties (6 Inner Observatory domains + non-diagnostic notice)
/// 5: Personal Goals & Focus (curated goals + custom goal)
/// 6: Professional Support (Optional, non-clinical complement)
/// 7: User-Confirmed Review of Priorities (1-tap Edit per section & account completion)
///
/// Secondary configuration (biometrics, email credentials, advanced AI tones)
/// is managed in Settings and Profile.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final List<int> _history = [0];
  bool _editingFromSummary = false;

  // Step 1: Basic Information
  String _selectedAgeRange = '';
  String _selectedBiologicalSex = '';

  // Step 2: Mental-Health Background
  String _selectedBackground = '';

  // Step 3: Conditions & Diagnostic Status
  final Map<ConditionType, DiagnosticStatus> _selectedConditions = {};
  String _conditionSearchQuery = '';

  // Step 4: Current Symptoms across Inner Observatory Domains
  final Set<String> _selectedSymptoms = {};
  SymptomDomain? _activeSymptomDomain;

  // Step 5: Personal Goals & Focus
  final Set<String> _selectedGoals = {};
  final TextEditingController _customGoalController = TextEditingController();

  // Step 6: Professional Support
  String _selectedProfessionalSupport = '';

  final List<String> _ageRanges = const [
    'under_18',
    '18-24',
    '25-34',
    '35-44',
    '45-54',
    '55-64',
    '65+',
    'prefer_not_to_say',
  ];

  final List<String> _biologicalSexOptions = const [
    'female',
    'male',
    'intersex',
    'other',
    'prefer_not_to_say',
  ];

  final List<String> _defaultGoalOptions = const [
    'Understand recurring thought patterns',
    'Track and regulate intense emotions',
    'Manage anxiety and somatic tension',
    'Improve daily focus and overcome inertia',
    'Build sustainable coping strategies',
    'Recognize early triggers before distress spikes',
    'Reflect alongside professional therapy',
    'General self-awareness and mindful observation',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateFromExistingProfile();
    });
  }

  @override
  void dispose() {
    _customGoalController.dispose();
    super.dispose();
  }

  void _hydrateFromExistingProfile() {
    final profile = ref.read(profileControllerProvider).value;
    if (profile == null) return;

    setState(() {
      if (profile.ageRange.isNotEmpty) _selectedAgeRange = profile.ageRange;
      if (profile.biologicalSex.isNotEmpty) {
        _selectedBiologicalSex = profile.biologicalSex;
      }
      if (profile.mentalHealthBackground.isNotEmpty) {
        _selectedBackground = profile.mentalHealthBackground;
      }
      if (profile.professionalSupport.isNotEmpty) {
        _selectedProfessionalSupport = profile.professionalSupport;
      }

      if (profile.conditions.isNotEmpty) {
        _selectedConditions.clear();
        for (final entry in profile.conditions) {
          _selectedConditions[entry.condition] = entry.status;
        }
      }

      if (profile.selectedSymptoms.isNotEmpty) {
        _selectedSymptoms.addAll(profile.selectedSymptoms);
      }

      if (profile.selectedGoals.isNotEmpty) {
        _selectedGoals.addAll(profile.selectedGoals);
      }
      if (profile.customGoal.isNotEmpty) {
        _customGoalController.text = profile.customGoal;
      }

      // Resume saved progress if in valid range (1 through 7)
      if (profile.onboardingStep > 0 && profile.onboardingStep <= 7) {
        _currentStep = profile.onboardingStep;
        if (!_history.contains(_currentStep)) {
          _history.add(_currentStep);
        }
      }
    });
  }

  bool _isClinicalBackground(String bg) {
    return bg == 'diagnosed' || bg == 'suspected' || bg == 'being_assessed';
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_editingFromSummary) {
      _returnToSummary();
      return;
    }

    int next;
    switch (_currentStep) {
      case 0:
        next = 1;
        break;
      case 1:
        next = 2;
        break;
      case 2:
        // Adaptive branching: if non-clinical background, bypass conditions directly to symptoms
        if (_isClinicalBackground(_selectedBackground)) {
          next = 3;
        } else {
          next = 4;
        }
        break;
      case 3:
        next = 4;
        break;
      case 4:
        next = 5;
        break;
      case 5:
        next = 6;
        break;
      case 6:
        next = 7;
        break;
      case 7:
        _finishOnboarding();
        return;
      default:
        next = _currentStep + 1;
    }

    _goToStep(next);
  }

  void _previousStep() {
    HapticFeedback.lightImpact();
    if (_editingFromSummary) {
      _returnToSummary();
      return;
    }

    if (_history.length > 1) {
      _history.removeLast();
      final prev = _history.last;
      _goToStep(prev, addToHistory: false);
    } else if (_currentStep > 0) {
      _goToStep(0, addToHistory: false);
    }
  }

  void _goToStep(int step, {bool addToHistory = true}) {
    if (addToHistory && (_history.isEmpty || _history.last != step)) {
      _history.add(step);
    }
    setState(() {
      _currentStep = step;
    });
    _saveDraftProgress();
  }

  void _returnToSummary() {
    setState(() {
      _editingFromSummary = false;
      _currentStep = 7;
    });
    if (_history.isEmpty || _history.last != 7) {
      _history.add(7);
    }
    _saveDraftProgress();
  }

  void _editSection(int targetStep) {
    HapticFeedback.selectionClick();
    setState(() {
      _editingFromSummary = true;
      _currentStep = targetStep;
    });
    _history.add(targetStep);
  }

  Future<void> _saveDraftProgress() async {
    final conditionEntries = _selectedConditions.entries.map((e) {
      return UserConditionEntry(
        condition: e.key,
        status: e.value,
      );
    }).toList();

    final goalsList = _selectedGoals.toList();
    final customGoalText = _customGoalController.text.trim();
    final fullGoals = [
      ...goalsList,
      if (customGoalText.isNotEmpty) customGoalText,
    ].join(', ');

    final currentProfile = ref.read(profileControllerProvider).value;

    final profile = (currentProfile ??
            PsychologicalProfileModel.empty(
              userId:
                  ref.read(authControllerProvider).user?.id ?? 'local_user',
            ))
        .copyWith(
      ageRange: _selectedAgeRange,
      biologicalSex: _selectedBiologicalSex,
      mentalHealthBackground: _selectedBackground,
      conditions: conditionEntries,
      selectedSymptoms: _selectedSymptoms.toList(),
      selectedGoals: goalsList,
      customGoal: customGoalText,
      personalGoals: fullGoals,
      professionalSupport: _selectedProfessionalSupport,
      onboardingStep: _currentStep,
      updatedAt: DateTime.now(),
    );

    // Save draft asynchronously without blocking UI thread
    ref.read(profileControllerProvider.notifier).saveFullProfile(profile);
  }

  Future<void> _finishOnboarding() async {
    HapticFeedback.mediumImpact();

    // 1. Initialize the private on-device account
    final authCtrl = ref.read(authControllerProvider.notifier);
    await authCtrl.createAnonymousVault();
    await authCtrl.completeOnboarding();

    // 2. Build and persist user's psychological profile
    final conditionEntries = _selectedConditions.entries.map((e) {
      return UserConditionEntry(
        condition: e.key,
        status: e.value,
      );
    }).toList();

    final goalsList = _selectedGoals.toList();
    final customGoalText = _customGoalController.text.trim();
    final fullGoals = [
      ...goalsList,
      if (customGoalText.isNotEmpty) customGoalText,
    ].join(', ');

    final currentProfile = ref.read(profileControllerProvider).value;

    final profile = (currentProfile ??
            PsychologicalProfileModel.empty(
              userId:
                  ref.read(authControllerProvider).user?.id ?? 'local_user',
            ))
        .copyWith(
      ageRange: _selectedAgeRange,
      biologicalSex: _selectedBiologicalSex,
      mentalHealthBackground: _selectedBackground,
      conditions: conditionEntries,
      selectedSymptoms: _selectedSymptoms.toList(),
      selectedGoals: goalsList,
      customGoal: customGoalText,
      personalGoals: fullGoals,
      professionalSupport: _selectedProfessionalSupport,
      onboardingStep: 7,
      updatedAt: DateTime.now(),
    );

    await ref.read(profileControllerProvider.notifier).saveFullProfile(profile);

    // 3. Ensure initial journey is hydrated
    await ref.read(journeyControllerProvider.notifier).resetJourney();

    if (mounted) {
      context.go(AppRouter.home);
    }
  }

  bool get _isMinor =>
      _selectedAgeRange == 'under_18' || _selectedAgeRange == '<18';

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<PsychologicalProfileModel?>>(
      profileControllerProvider,
      (previous, next) {
        if (next.hasValue && next.value != null && _currentStep == 0) {
          _hydrateFromExistingProfile();
        }
      },
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);

    final bg =
        isDark ? LabColors.nightBackground : LabColors.daylightBackground;
    final surfaceColor =
        isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final borderColor =
        isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary =
        isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary =
        isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    final oliveAccent =
        isDark ? LabColors.nightAccent : LabColors.mutedOlive;
    final cardSelectedBg =
        isDark ? LabColors.nightSurfaceElevated : LabColors.mutedOliveSoft;
    final cardSelectedBorder =
        isDark ? LabColors.nightAccent : LabColors.mutedOlive;
    final buttonBg =
        isDark ? LabColors.nightTextPrimary : LabColors.mutedOlive;
    final buttonFg =
        isDark ? LabColors.nightBackground : LabColors.daylightBackground;

    final canGoBack = _currentStep > 0;
    final isOptionalStep =
        _currentStep == 1 || _currentStep == 3 || _currentStep == 6;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                color: textPrimary,
                tooltip: strings.backBtn,
                onPressed: _previousStep,
              )
            : null,
        title: Text(
          'Mind Forensics',
          style: LabTheme.serifStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: textPrimary,
          ),
        ),
        actions: [
          const SupportButton(),
          if (_editingFromSummary)
            TextButton(
              onPressed: _returnToSummary,
              child: Text(
                strings.returnToSummaryBtn,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: oliveAccent,
                ),
              ),
            )
          else if (isOptionalStep)
            TextButton(
              onPressed: _nextStep,
              child: Text(
                strings.onboardingSkip,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: textSecondary,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Return to Summary Banner if actively editing
            if (_editingFromSummary)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: oliveAccent.withValues(alpha: 0.12),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 16,
                      color: oliveAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editing section • Review will reflect changes',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _returnToSummary,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        child: Text(
                          strings.returnToSummaryBtn,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: oliveAccent,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Step Progress Ticks (7 core steps)
            if (_currentStep > 0)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: List.generate(7, (index) {
                    final stepNum = index + 1;
                    final isCompleted = stepNum < _currentStep;
                    final isCurrent = stepNum == _currentStep;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        height: 3.0,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? oliveAccent
                              : (isCompleted
                                  ? (isDark
                                      ? const Color(0xFF5A7264)
                                      : LabColors.daylightAccent)
                                  : (isDark
                                      ? LabColors.nightBorderSubtle
                                      : const Color(0xFFE2E7E3))),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

            // Main Adaptive Step Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildCurrentStep(
                  isDark,
                  surfaceColor,
                  borderColor,
                  textPrimary,
                  textSecondary,
                  oliveAccent,
                  cardSelectedBg,
                  cardSelectedBorder,
                  strings,
                ),
              ),
            ),

            // Bottom Action Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: bg,
                border: Border(top: BorderSide(color: borderColor, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    Text(
                      'Step $_currentStep of 7',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: textSecondary,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: buttonBg,
                      foregroundColor: buttonFg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 13),
                      elevation: 0,
                    ),
                    onPressed: _currentStep == 7
                        ? _finishOnboarding
                        : _nextStep,
                    child: Text(
                      _editingFromSummary
                          ? strings.returnToSummaryBtn.toUpperCase()
                          : (_currentStep == 7
                              ? strings.confirmAndStartBtn.toUpperCase()
                              : (_currentStep == 0
                                  ? 'GET STARTED'
                                  : strings.onboardingNext.toUpperCase())),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color oliveAccent,
    Color cardSelectedBg,
    Color cardSelectedBorder,
    AppStrings strings,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep(
          isDark,
          surfaceColor,
          borderColor,
          textPrimary,
          textSecondary,
          oliveAccent,
          strings,
        );
      case 1:
        return _buildBasicInfoStep(
          isDark,
          surfaceColor,
          borderColor,
          textPrimary,
          textSecondary,
          oliveAccent,
          cardSelectedBg,
          cardSelectedBorder,
          strings,
        );
      case 2:
        return _buildBackgroundStep(
          isDark,
          surfaceColor,
          borderColor,
          textPrimary,
          textSecondary,
          oliveAccent,
          cardSelectedBg,
          cardSelectedBorder,
          strings,
        );
      case 3:
        return _buildConditionsStep(
          isDark,
          surfaceColor,
          borderColor,
          textPrimary,
          textSecondary,
          oliveAccent,
          cardSelectedBg,
          cardSelectedBorder,
          strings,
        );
      case 4:
        return _buildSymptomsStep(
          isDark,
          surfaceColor,
          borderColor,
          textPrimary,
          textSecondary,
          oliveAccent,
          cardSelectedBg,
          cardSelectedBorder,
          strings,
        );
      case 5:
        return _buildGoalsStep(
          isDark,
          surfaceColor,
          borderColor,
          textPrimary,
          textSecondary,
          oliveAccent,
          cardSelectedBg,
          cardSelectedBorder,
          strings,
        );
      case 6:
        return _buildProfessionalSupportStep(
          isDark,
          surfaceColor,
          borderColor,
          textPrimary,
          textSecondary,
          oliveAccent,
          cardSelectedBg,
          cardSelectedBorder,
          strings,
        );
      case 7:
        return _buildSummaryStep(
          isDark,
          surfaceColor,
          borderColor,
          textPrimary,
          textSecondary,
          oliveAccent,
          cardSelectedBg,
          cardSelectedBorder,
          strings,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepBadge(
      String step, String label, bool isDark, Color textPrimary) {
    final badgeBg =
        isDark ? LabColors.nightSurface : LabColors.mutedOliveBadgeBg;
    final badgeBorder =
        isDark ? LabColors.nightBorder : const Color(0xFFD3DDD5);
    final badgeText =
        isDark ? LabColors.nightAccent : LabColors.mutedOlive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            step,
            style: TextStyle(
              color: badgeText.withValues(alpha: 0.7),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            '  •  ',
            style: TextStyle(
              color: badgeText.withValues(alpha: 0.4),
              fontSize: 9.5,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: badgeText,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 0: Welcome & Philosophy (Accurate, honest privacy guarantees)
  // ---------------------------------------------------------------------------
  Widget _buildWelcomeStep(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color oliveAccent,
    AppStrings strings,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('step_0_welcome'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBadge('00', 'PHILOSOPHY', isDark, textPrimary),
          const SizedBox(height: 28),
          const Center(
            child: FingerprintThreadSignature(size: 88),
          ),
          const SizedBox(height: 32),
          Text(
            'Every thought leaves a trace.',
            style: LabTheme.serifStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Mind Forensics is a quiet, personal space dedicated to observing the human mind. Here, you can examine your thoughts, emotions, and behavioral patterns at your own pace without judgment.',
            style: LabTheme.editorialSerif(
              fontSize: 14.5,
              height: 1.6,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? LabColors.nightSurface
                  : LabColors.warmIvorySurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? LabColors.nightBorder
                    : LabColors.warmIvoryBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: oliveAccent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Private on-device storage. No advertising trackers, no data brokers, and no recovery scores. Your entries remain strictly confidential on this device.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push(AppRouter.auth);
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      strings.alreadyHaveVaultPrompt,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    Text(
                      strings.signInPromptBtn,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: oliveAccent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: Basic Information (Age Range, Optional Sex, Under-18 Safeguards)
  // ---------------------------------------------------------------------------
  Widget _buildBasicInfoStep(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color oliveAccent,
    Color cardSelectedBg,
    Color cardSelectedBorder,
    AppStrings strings,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('step_1_basic_info'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBadge('01', 'BASIC INFORMATION', isDark, textPrimary),
          const SizedBox(height: 16),
          Text(
            strings.onboardingBasicInfoTitle,
            style: LabTheme.serifStyle(fontSize: 22, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            strings.onboardingBasicInfoSubtitle,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
          ),
          const SizedBox(height: 22),

          // Age Range
          Text(
            strings.ageRangeLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ageRanges.map((range) {
              final isSelected = _selectedAgeRange == range;
              return BouncingWidget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedAgeRange = range);
                  _saveDraftProgress();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? cardSelectedBg : surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? cardSelectedBorder : borderColor,
                      width: isSelected ? 1.4 : 1.0,
                    ),
                  ),
                  child: Text(
                    strings.ageRangeDisplayName(range),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? textPrimary : LabColors.mutedOlive)
                          : textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Minor Safeguard Notice if under 18
          if (_isMinor) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? LabColors.safetySoftBgDark
                    : LabColors.safetySoftBgLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? LabColors.safetyBorderDark
                      : LabColors.safetyBorderLight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: isDark
                        ? LabColors.safetyWarmthDark
                        : LabColors.safetyWarmth,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      strings.minorSupportNotice,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Physiological Context / Sex (Optional)
          Text(
            strings.biologicalSexLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.biologicalSexHelperNote,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _biologicalSexOptions.map((opt) {
              final isSelected = _selectedBiologicalSex == opt;
              return BouncingWidget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedBiologicalSex = opt);
                  _saveDraftProgress();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? cardSelectedBg : surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? cardSelectedBorder : borderColor,
                      width: isSelected ? 1.4 : 1.0,
                    ),
                  ),
                  child: Text(
                    strings.biologicalSexDisplayName(opt),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? textPrimary : LabColors.mutedOlive)
                          : textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Mental-Health Background (6 starting points)
  // ---------------------------------------------------------------------------
  Widget _buildBackgroundStep(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color oliveAccent,
    Color cardSelectedBg,
    Color cardSelectedBorder,
    AppStrings strings,
  ) {
    final backgrounds = [
      (
        key: 'diagnosed',
        title: strings.bgDiagnosedTitle,
        desc: strings.bgDiagnosedDesc,
        icon: Icons.verified_outlined,
      ),
      (
        key: 'suspected',
        title: strings.bgSuspectedTitle,
        desc: strings.bgSuspectedDesc,
        icon: Icons.lightbulb_outline_rounded,
      ),
      (
        key: 'being_assessed',
        title: strings.bgAssessedTitle,
        desc: strings.bgAssessedDesc,
        icon: Icons.hourglass_top_rounded,
      ),
      (
        key: 'difficulties_no_diagnosis',
        title: strings.bgDifficultiesTitle,
        desc: strings.bgDifficultiesDesc,
        icon: Icons.spa_outlined,
      ),
      (
        key: 'wellbeing_tracking',
        title: strings.bgWellbeingTitle,
        desc: strings.bgWellbeingDesc,
        icon: Icons.self_improvement_outlined,
      ),
      (
        key: 'unsure',
        title: strings.bgUnsureTitle,
        desc: strings.bgUnsureDesc,
        icon: Icons.help_outline_rounded,
      ),
    ];

    return SingleChildScrollView(
      key: const ValueKey('step_2_background'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBadge('02', 'STARTING POINT', isDark, textPrimary),
          const SizedBox(height: 16),
          Text(
            strings.onboardingBackgroundTitle,
            style: LabTheme.serifStyle(fontSize: 22, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            strings.onboardingBackgroundSubtitle,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
          ),
          const SizedBox(height: 18),
          ...backgrounds.map((bg) {
            final isSelected = _selectedBackground == bg.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BouncingWidget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedBackground = bg.key);
                  _saveDraftProgress();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? cardSelectedBg : surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? cardSelectedBorder : borderColor,
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
                              ? oliveAccent.withValues(
                                  alpha: isDark ? 0.20 : 0.12)
                              : (isDark
                                  ? LabColors.nightSurfaceSubtle
                                  : LabColors.mutedOliveBadgeBg),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          bg.icon,
                          size: 18,
                          color: isSelected ? oliveAccent : textSecondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bg.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bg.desc,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.35,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: isSelected
                            ? oliveAccent
                            : textSecondary.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3: Searchable Conditions with Diagnosed vs Suspected Toggles
  // ---------------------------------------------------------------------------
  Widget _buildConditionsStep(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color oliveAccent,
    Color cardSelectedBg,
    Color cardSelectedBorder,
    AppStrings strings,
  ) {
    final query = _conditionSearchQuery.trim().toLowerCase();
    final allConditions = ConditionType.values.where((c) {
      if (c == ConditionType.other ||
          c == ConditionType.stillExploring ||
          c == ConditionType.preferNotToSpecify) {
        return false;
      }
      if (query.isEmpty) return true;
      final name = strings.conditionName(c).toLowerCase();
      final defaultName = c.defaultDisplayName().toLowerCase();
      return name.contains(query) || defaultName.contains(query);
    }).toList();

    return SingleChildScrollView(
      key: const ValueKey('step_3_conditions'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBadge('03', 'CONDITIONS', isDark, textPrimary),
          const SizedBox(height: 16),
          Text(
            strings.conditionsSectionTitle,
            style: LabTheme.serifStyle(fontSize: 22, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            strings.conditionsSectionSubtitle,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
          ),
          const SizedBox(height: 14),

          // Non-diagnostic note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? LabColors.nightSurface
                  : LabColors.warmIvorySurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? LabColors.nightBorder
                    : LabColors.warmIvoryBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: oliveAccent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.conditionNonDiagnosticNote,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Live Search Bar
          TextField(
            onChanged: (q) => setState(() => _conditionSearchQuery = q),
            style: TextStyle(color: textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: strings.conditionSearchHint,
              hintStyle: TextStyle(
                color: textSecondary.withValues(alpha: 0.6),
                fontSize: 12,
              ),
              prefixIcon:
                  Icon(Icons.search_rounded, size: 18, color: textSecondary),
              filled: true,
              fillColor: surfaceColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: cardSelectedBorder,
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Condition List
          ...allConditions.map((condition) {
            final isSelected = _selectedConditions.containsKey(condition);
            final currentStatus = _selectedConditions[condition] ??
                (_selectedBackground == 'diagnosed'
                    ? DiagnosticStatus.professionallyDiagnosed
                    : DiagnosticStatus.selfIdentifiedExploring);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? cardSelectedBg : surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? cardSelectedBorder : borderColor,
                    width: isSelected ? 1.3 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (isSelected) {
                            _selectedConditions.remove(condition);
                          } else {
                            _selectedConditions[condition] =
                                _selectedBackground == 'diagnosed'
                                    ? DiagnosticStatus.professionallyDiagnosed
                                    : DiagnosticStatus.selfIdentifiedExploring;
                          }
                        });
                        _saveDraftProgress();
                      },
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                            size: 16,
                            color: isSelected ? oliveAccent : textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              strings.conditionName(condition),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildStatusToggleChip(
                            label: strings.statusDiagnosedTag,
                            isActive: currentStatus ==
                                DiagnosticStatus.professionallyDiagnosed,
                            onTap: () {
                              setState(() {
                                _selectedConditions[condition] =
                                    DiagnosticStatus.professionallyDiagnosed;
                              });
                              _saveDraftProgress();
                            },
                            isDark: isDark,
                            oliveAccent: oliveAccent,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            borderColor: borderColor,
                          ),
                          const SizedBox(width: 8),
                          _buildStatusToggleChip(
                            label: strings.statusSuspectedTag,
                            isActive: currentStatus ==
                                DiagnosticStatus.selfIdentifiedExploring,
                            onTap: () {
                              setState(() {
                                _selectedConditions[condition] =
                                    DiagnosticStatus.selfIdentifiedExploring;
                              });
                              _saveDraftProgress();
                            },
                            isDark: isDark,
                            oliveAccent: oliveAccent,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            borderColor: borderColor,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusToggleChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
    required Color oliveAccent,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                  ? oliveAccent.withValues(alpha: 0.25)
                  : LabColors.mutedOlive)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? oliveAccent : borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? (isDark ? oliveAccent : LabColors.daylightBackground)
                : textSecondary,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 4: Symptoms & Difficulties across Inner Observatory Domains
  // ---------------------------------------------------------------------------
  Widget _buildSymptomsStep(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color oliveAccent,
    Color cardSelectedBg,
    Color cardSelectedBorder,
    AppStrings strings,
  ) {
    final allEntries = DefaultSymptomLibrary.entries.where((s) {
      if (_activeSymptomDomain != null && s.domain != _activeSymptomDomain) {
        return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      key: const ValueKey('step_4_symptoms'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBadge('04', 'SYMPTOMS & DIFFICULTIES', isDark, textPrimary),
          const SizedBox(height: 16),
          Text(
            strings.symptomsSelectionTitle,
            style: LabTheme.serifStyle(fontSize: 22, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            strings.symptomsSelectionSubtitle,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
          ),
          const SizedBox(height: 16),

          // Domain Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(
                    strings.isArabic
                        ? 'الكل'
                        : (strings.isFrench ? 'Tout' : 'All'),
                  ),
                  selected: _activeSymptomDomain == null,
                  onSelected: (_) =>
                      setState(() => _activeSymptomDomain = null),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: _activeSymptomDomain == null
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _activeSymptomDomain == null
                        ? (isDark ? oliveAccent : LabColors.daylightBackground)
                        : textSecondary,
                  ),
                  backgroundColor: surfaceColor,
                  selectedColor: isDark
                      ? oliveAccent.withValues(alpha: 0.25)
                      : LabColors.mutedOlive,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(
                      color: _activeSymptomDomain == null
                          ? oliveAccent
                          : borderColor,
                    ),
                  ),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 6),
                ...SymptomDomain.values.map((d) {
                  final isSelected = _activeSymptomDomain == d;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ChoiceChip(
                      label: Text(d.localized(strings)),
                      selected: isSelected,
                      onSelected: (_) => setState(() =>
                          _activeSymptomDomain = isSelected ? null : d),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark
                                ? oliveAccent
                                : LabColors.daylightBackground)
                            : textSecondary,
                      ),
                      backgroundColor: surfaceColor,
                      selectedColor: isDark
                          ? oliveAccent.withValues(alpha: 0.25)
                          : LabColors.mutedOlive,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: isSelected ? oliveAccent : borderColor,
                        ),
                      ),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Symptom Cards
          ...allEntries.map((entry) {
            final isSelected = _selectedSymptoms.contains(entry.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BouncingWidget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedSymptoms.remove(entry.id);
                    } else {
                      _selectedSymptoms.add(entry.id);
                    }
                  });
                  _saveDraftProgress();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? cardSelectedBg : surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? cardSelectedBorder : borderColor,
                      width: isSelected ? 1.3 : 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 16,
                        color: isSelected ? oliveAccent : textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.localizedTitle(strings),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              entry.localizedDescription(strings),
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.35,
                                color: textSecondary,
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 5: Personal Goals & Exploration Focus
  // ---------------------------------------------------------------------------
  Widget _buildGoalsStep(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color oliveAccent,
    Color cardSelectedBg,
    Color cardSelectedBorder,
    AppStrings strings,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('step_5_goals'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBadge('05', 'EXPLORATION GOALS', isDark, textPrimary),
          const SizedBox(height: 16),
          Text(
            'What do you hope to explore?',
            style: LabTheme.serifStyle(fontSize: 22, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the areas of your inner world you would like to observe and understand.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
          ),
          const SizedBox(height: 18),
          ..._defaultGoalOptions.map((goal) {
            final isSelected = _selectedGoals.contains(goal);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BouncingWidget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedGoals.remove(goal);
                    } else {
                      _selectedGoals.add(goal);
                    }
                  });
                  _saveDraftProgress();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? cardSelectedBg : surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? cardSelectedBorder : borderColor,
                      width: isSelected ? 1.3 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: isSelected ? oliveAccent : textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          goal,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          TextField(
            controller: _customGoalController,
            onChanged: (_) => _saveDraftProgress(),
            style: TextStyle(fontSize: 12.5, color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Or add a custom personal goal...',
              hintStyle: TextStyle(
                fontSize: 12,
                color: textSecondary.withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(Icons.edit_outlined,
                  size: 16, color: textSecondary),
              filled: true,
              fillColor: surfaceColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: cardSelectedBorder, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 6: Professional Support (Optional, Complementary)
  // ---------------------------------------------------------------------------
  Widget _buildProfessionalSupportStep(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color oliveAccent,
    Color cardSelectedBg,
    Color cardSelectedBorder,
    AppStrings strings,
  ) {
    final supportOptions = [
      (
        key: 'therapist',
        title: strings.supportSystemOptionTitle('therapist'),
        icon: Icons.psychology_outlined,
      ),
      (
        key: 'psychiatrist',
        title: strings.supportSystemOptionTitle('psychiatrist'),
        icon: Icons.medical_services_outlined,
      ),
      (
        key: 'assessment',
        title: strings.supportSystemOptionTitle('assessment'),
        icon: Icons.pending_actions_rounded,
      ),
      (
        key: 'primary_care',
        title: strings.supportSystemOptionTitle('primary_care'),
        icon: Icons.health_and_safety_outlined,
      ),
      (
        key: 'coach',
        title: strings.supportSystemOptionTitle('coach'),
        icon: Icons.support_agent_rounded,
      ),
      (
        key: 'self_guided',
        title: strings.supportSystemOptionTitle('self_guided'),
        icon: Icons.self_improvement_rounded,
      ),
      (
        key: 'prefer_not_to_say',
        title: strings.supportSystemOptionTitle('prefer_not_to_say'),
        icon: Icons.visibility_off_outlined,
      ),
    ];

    return SingleChildScrollView(
      key: const ValueKey('step_6_support'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBadge('06', 'PROFESSIONAL CARE', isDark, textPrimary),
          const SizedBox(height: 16),
          Text(
            strings.supportSystemTitle,
            style: LabTheme.serifStyle(fontSize: 22, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            strings.supportSystemSubtitle,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
          ),
          const SizedBox(height: 18),
          ...supportOptions.map((opt) {
            final isSelected = _selectedProfessionalSupport == opt.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BouncingWidget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedProfessionalSupport = opt.key);
                  _saveDraftProgress();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? cardSelectedBg : surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? cardSelectedBorder : borderColor,
                      width: isSelected ? 1.4 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        opt.icon,
                        size: 18,
                        color: isSelected ? oliveAccent : textSecondary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          opt.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: isSelected
                            ? oliveAccent
                            : textSecondary.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 7: User-Confirmed Review of Priorities
  // ---------------------------------------------------------------------------
  Widget _buildSummaryStep(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color oliveAccent,
    Color cardSelectedBg,
    Color cardSelectedBorder,
    AppStrings strings,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('step_7_summary'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBadge('07', 'CONFIRMATION', isDark, textPrimary),
          const SizedBox(height: 16),
          Text(
            strings.summaryPrioritiesTitle,
            style: LabTheme.serifStyle(fontSize: 22, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            strings.summaryPrioritiesSubtitle,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
          ),
          const SizedBox(height: 20),

          // 1. Basic Info Review Card
          _buildSummarySectionCard(
            title: strings.onboardingBasicInfoTitle,
            onEdit: () => _editSection(1),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            oliveAccent: oliveAccent,
            strings: strings,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Age: ${_selectedAgeRange.isNotEmpty ? strings.ageRangeDisplayName(_selectedAgeRange) : "Not specified"}  •  Sex: ${_selectedBiologicalSex.isNotEmpty ? strings.biologicalSexDisplayName(_selectedBiologicalSex) : "Not specified"}',
                  style: TextStyle(fontSize: 12, color: textPrimary),
                ),
                if (_isMinor) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? LabColors.safetySoftBgDark
                          : LabColors.safetySoftBgLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Under-18 Safeguards Active',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? LabColors.safetyWarmthDark
                            : LabColors.safetyWarmth,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Mental-Health Background Review Card
          _buildSummarySectionCard(
            title: strings.onboardingBackgroundTitle,
            onEdit: () => _editSection(2),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            oliveAccent: oliveAccent,
            strings: strings,
            content: Text(
              _selectedBackground.isNotEmpty
                  ? strings.backgroundDisplayName(_selectedBackground)
                  : 'Not specified',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. Conditions Review Card
          _buildSummarySectionCard(
            title: strings.conditionsSectionTitle,
            onEdit: () => _editSection(3),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            oliveAccent: oliveAccent,
            strings: strings,
            content: _selectedConditions.isEmpty
                ? Text(
                    'No conditions specified (Self-guided exploration)',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: textSecondary,
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedConditions.entries.map((e) {
                      final isDiagnosed = e.value ==
                          DiagnosticStatus.professionallyDiagnosed;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDiagnosed
                              ? (isDark
                                  ? LabColors.nightSurfaceElevated
                                  : LabColors.mutedOliveBadgeBg)
                              : (isDark
                                  ? LabColors.nightSurface
                                  : const Color(0xFFF2F5F3)),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDiagnosed ? oliveAccent : borderColor,
                          ),
                        ),
                        child: Text(
                          '${strings.conditionName(e.key)} (${isDiagnosed ? "Diagnosed" : "Exploring"})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isDiagnosed
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isDiagnosed ? oliveAccent : textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 10),

          // 4. Symptoms Review Card
          _buildSummarySectionCard(
            title: strings.symptomsSelectionTitle,
            onEdit: () => _editSection(4),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            oliveAccent: oliveAccent,
            strings: strings,
            content: _selectedSymptoms.isEmpty
                ? Text(
                    'None selected for intake',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: textSecondary,
                    ),
                  )
                : Text(
                    '${_selectedSymptoms.length} symptom(s) marked for Inner Observatory focus',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
          ),
          const SizedBox(height: 10),

          // 5. Goals Review Card
          _buildSummarySectionCard(
            title: strings.sectionGoals,
            onEdit: () => _editSection(5),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            oliveAccent: oliveAccent,
            strings: strings,
            content: (_selectedGoals.isEmpty &&
                    _customGoalController.text.trim().isEmpty)
                ? Text(
                    'General mindful observation',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: textSecondary,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._selectedGoals.map((g) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '• $g',
                              style: TextStyle(
                                  fontSize: 11.5, color: textPrimary),
                            ),
                          )),
                      if (_customGoalController.text.trim().isNotEmpty)
                        Text(
                          '• ${_customGoalController.text.trim()}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: oliveAccent,
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),

          // 6. Professional Support Review Card
          _buildSummarySectionCard(
            title: strings.supportSystemTitle,
            onEdit: () => _editSection(6),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            oliveAccent: oliveAccent,
            strings: strings,
            content: Text(
              _selectedProfessionalSupport.isNotEmpty
                  ? strings.supportSystemOptionTitle(
                      _selectedProfessionalSupport)
                  : 'Self-guided (No current care)',
              style: TextStyle(fontSize: 12, color: textPrimary),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummarySectionCard({
    required String title,
    required VoidCallback onEdit,
    required Widget content,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color oliveAccent,
    required AppStrings strings,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: textSecondary,
                ),
              ),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 13,
                        color: oliveAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        strings.editSectionBtn,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: oliveAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}
