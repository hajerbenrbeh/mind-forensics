import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/security/app_lock_provider.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../core/widgets/fingerprint_thread_signature.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../journey/controllers/journey_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/domain/condition_type.dart';
import '../../profile/domain/diagnostic_status.dart';
import '../../profile/domain/psychological_profile_model.dart';

/// The 6-Step Master Onboarding Experience for Mind Forensics.
///
/// Steps:
/// 1. Welcome & Brand Philosophy
/// 2. Personal Mental Health Profile & Diagnostic Status
/// 3. Personal Exploration Goals
/// 4. AI Companion Communication Preferences
/// 5. Introduction to the Personalized Journey
/// 6. Privacy Shield & Granular Data Consent
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 2 State: Selected Conditions & Statuses
  final Map<ConditionType, DiagnosticStatus> _selectedConditions = {};

  // Step 3 State: Personal Goals
  final Set<String> _selectedGoals = {};
  final TextEditingController _customGoalController = TextEditingController();

  // Step 4 State: Communication Preference
  String _selectedCommunicationPref = 'analytical_reflective';

  // Step 6 State: Consent, Vault Security & Privacy
  bool _consentAiContext = true;
  bool _vaultIsAnonymous = true;
  final TextEditingController _onboardingEmailController = TextEditingController();
  final TextEditingController _onboardingPasswordController = TextEditingController();
  bool _enableBiometrics = false;

  final List<String> _defaultGoalOptions = const [
    'Understand my thoughts',
    'Understand my emotions',
    'Explore recurring patterns',
    'Understand my anxiety',
    'Work on emotional regulation',
    'Improve self-awareness',
    'Understand my behavior',
    'Build healthier coping strategies',
  ];

  final List<({String key, String title, String subtitle, IconData icon})>
      _communicationStyles = const [
    (
      key: 'gentle_supportive',
      title: 'Gentle & Supportive',
      subtitle: 'Warm, patient, and validating with gentle pacing',
      icon: Icons.favorite_border_rounded,
    ),
    (
      key: 'analytical_reflective',
      title: 'Analytical & Reflective',
      subtitle: 'Inquisitive, Socratic, identifying cognitive patterns',
      icon: Icons.psychology_outlined,
    ),
    (
      key: 'direct_honest',
      title: 'Direct & Honest',
      subtitle: 'Straightforward, focused on reality and clarity',
      icon: Icons.lens_blur_rounded,
    ),
    (
      key: 'detailed_educational',
      title: 'Detailed & Educational',
      subtitle: 'In-depth psychoeducation and cognitive breakdowns',
      icon: Icons.school_outlined,
    ),
    (
      key: 'short_practical',
      title: 'Short & Practical',
      subtitle: 'Bite-sized, action-oriented reflections',
      icon: Icons.bolt_outlined,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _customGoalController.dispose();
    _onboardingEmailController.dispose();
    _onboardingPasswordController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    HapticFeedback.mediumImpact();

    // 1. Establish the user's sovereign or cloud mental vault
    final authCtrl = ref.read(authControllerProvider.notifier);
    if (_vaultIsAnonymous) {
      await authCtrl.createAnonymousVault();
    } else {
      final email = _onboardingEmailController.text.trim();
      final password = _onboardingPasswordController.text.trim();
      if (email.isNotEmpty && password.length >= 6) {
        await authCtrl.signUpWithEmail(email, password);
      } else {
        await authCtrl.createAnonymousVault();
      }
    }
    await authCtrl.completeOnboarding();

    // 2. Enable biometric protection if opted in
    if (_enableBiometrics) {
      await ref.read(appLockProvider.notifier).toggleBiometrics(true);
    }

    // 3. Build and persist user's psychological profile
    final conditionEntries = _selectedConditions.entries.map((e) {
      return UserConditionEntry(
        condition: e.key,
        status: e.value,
      );
    }).toList();

    final goalsText = [
      ..._selectedGoals,
      if (_customGoalController.text.trim().isNotEmpty)
        _customGoalController.text.trim(),
    ].join(', ');

    final profile = PsychologicalProfileModel(
      conditions: conditionEntries,
      personalGoals: goalsText,
      communicationPreference: _selectedCommunicationPref,
      shareWithAiCompanion: _consentAiContext,
      updatedAt: DateTime.now(),
    );

    await ref.read(profileControllerProvider.notifier).saveFullProfile(profile);

    // 4. Ensure initial journey is hydrated
    await ref.read(journeyControllerProvider.notifier).resetJourney();

    if (mounted) {
      context.go(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);

    final bg = isDark ? LabColors.nightBackground : LabColors.daylightBackground;
    final surfaceColor = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final borderColor = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Mind Forensics',
          style: LabTheme.serifStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: textPrimary,
          ),
        ),
        actions: [
          const SupportButton(),
          if (_currentPage < 5)
            TextButton(
              onPressed: _finishOnboarding,
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
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildWelcomeStep(isDark, surfaceColor, borderColor, textPrimary, textSecondary, strings),
                  _buildProfileStep(isDark, surfaceColor, borderColor, textPrimary, textSecondary, strings),
                  _buildGoalsStep(isDark, surfaceColor, borderColor, textPrimary, textSecondary, strings),
                  _buildCommunicationStep(isDark, surfaceColor, borderColor, textPrimary, textSecondary, strings),
                  _buildJourneyStep(isDark, surfaceColor, borderColor, textPrimary, textSecondary, strings),
                  _buildPrivacyConsentStep(isDark, surfaceColor, borderColor, textPrimary, textSecondary, strings),
                ],
              ),
            ),
            // Bottom Progress & Action Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(6, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsetsDirectional.only(end: 6),
                        width: isActive ? 22 : 6,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive
                              ? LabColors.champagneGold
                              : (isDark ? const Color(0xFF262626) : const Color(0xFFD4D4D8)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    ),
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage == 5 ? 'ENTER MIND FORENSICS' : strings.onboardingNext.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        letterSpacing: 0.6,
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

  Widget _buildStepBadge(String step, String label, bool isDark, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? LabColors.darkWine : LabColors.warmIvory,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? LabColors.wineBorder : LabColors.champagneGold.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        '$step  •  ${label.toUpperCase()}',
        style: const TextStyle(
          color: LabColors.champagneGold,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // Step 1: Welcome & Brand Philosophy
  Widget _buildWelcomeStep(bool isDark, Color surfaceColor, Color borderColor, Color textPrimary, Color textSecondary, AppStrings strings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBadge('01', 'WELCOME', isDark, textPrimary),
          const SizedBox(height: 28),
          const Center(
            child: FingerprintThreadSignature(size: 88),
          ),
          const SizedBox(height: 32),
          Text(
            'Every thought leaves a trace.',
            style: LabTheme.serifStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Mind Forensics is an intelligent, personal space dedicated to observing the human mind. Here, you can examine your thoughts, emotions, and behavioral patterns at your own pace without judgment.',
            style: LabTheme.editorialSerif(
              fontSize: 14.5,
              height: 1.55,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? LabColors.darkWine.withValues(alpha: 0.4) : const Color(0xFFFBF8F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? LabColors.wineBorder : LabColors.champagneGold.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 20, color: LabColors.champagneGold),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No clinical labels forced. No competitive recovery scores. A private sanctuary built around understanding.',
                    style: TextStyle(fontSize: 12, height: 1.4, color: textPrimary),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings.alreadyHaveVaultPrompt,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      strings.signInPromptBtn,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: LabColors.champagneGold,
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

  // Step 2: Personal Profile & Diagnostic Status
  Widget _buildProfileStep(bool isDark, Color surfaceColor, Color borderColor, Color textPrimary, Color textSecondary, AppStrings strings) {
    final previewConditions = [
      ConditionType.depression,
      ConditionType.generalizedAnxiety,
      ConditionType.socialAnxiety,
      ConditionType.ocd,
      ConditionType.ptsd,
      ConditionType.adhd,
      ConditionType.autism,
      ConditionType.sleepDisorders,
      ConditionType.stillExploring,
      ConditionType.preferNotToSpecify,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBadge('02', 'PROFILE', isDark, textPrimary),
          const SizedBox(height: 16),
          Text(
            'What experiences are present?',
            style: LabTheme.serifStyle(fontSize: 22, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Select any mental health conditions or experiences relevant to you. Selecting does not assume a professional diagnosis.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: previewConditions.map((condition) {
              final isSelected = _selectedConditions.containsKey(condition);
              return BouncingWidget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedConditions.remove(condition);
                    } else {
                      _selectedConditions[condition] =
                          DiagnosticStatus.selfIdentifiedExploring;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? LabColors.darkWine : LabColors.warmIvory)
                        : surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? LabColors.champagneGold
                          : borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                        size: 14,
                        color: isSelected ? LabColors.champagneGold : textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        condition.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? textPrimary : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedConditions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'DIAGNOSTIC EVALUATION STATUS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: DiagnosticStatus.values.map((status) {
                  final currentStatus = _selectedConditions.values.firstOrNull ??
                      DiagnosticStatus.selfIdentifiedExploring;
                  final isSelected = currentStatus == status;
                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        for (final key in _selectedConditions.keys.toList()) {
                          _selectedConditions[key] = status;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? LabColors.darkWine : LabColors.warmIvory)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 15,
                            color: isSelected ? LabColors.champagneGold : textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              status.displayName,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
            ),
          ],
        ],
      ),
    );
  }

  // Step 3: Personal Exploration Goals
  Widget _buildGoalsStep(bool isDark, Color surfaceColor, Color borderColor, Color textPrimary, Color textSecondary, AppStrings strings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBadge('03', 'EXPLORATION GOALS', isDark, textPrimary),
          const SizedBox(height: 16),
          Text(
            'What do you hope to explore?',
            style: LabTheme.serifStyle(fontSize: 22, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the areas of your inner world you would like to understand and observe.',
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
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? LabColors.darkWine : LabColors.warmIvory)
                        : surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? LabColors.champagneGold : borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: isSelected ? LabColors.champagneGold : textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          goal,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
          const SizedBox(height: 10),
          TextField(
            controller: _customGoalController,
            style: TextStyle(fontSize: 12.5, color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Or add a custom personal goal...',
              hintStyle: TextStyle(fontSize: 12, color: textSecondary),
              prefixIcon: const Icon(Icons.edit_outlined, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Step 4: AI Communication Preferences
  Widget _buildCommunicationStep(bool isDark, Color surfaceColor, Color borderColor, Color textPrimary, Color textSecondary, AppStrings strings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBadge('04', 'COMPANION TONE', isDark, textPrimary),
          const SizedBox(height: 16),
          Text(
            'How should your AI companion speak?',
            style: LabTheme.serifStyle(fontSize: 22, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a conversational style. Your companion maintains psychological warmth and never judges.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
          ),
          const SizedBox(height: 18),
          ..._communicationStyles.map((style) {
            final isSelected = style.key == _selectedCommunicationPref;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BouncingWidget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCommunicationPref = style.key);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? LabColors.darkWine : LabColors.warmIvory)
                        : surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? LabColors.champagneGold : borderColor,
                      width: isSelected ? 1.2 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? LabColors.champagneGold.withValues(alpha: 0.15)
                              : (isDark ? const Color(0xFF141414) : const Color(0xFFF4F4F5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          style.icon,
                          size: 18,
                          color: isSelected ? LabColors.champagneGold : textSecondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              style.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              style.subtitle,
                              style: TextStyle(fontSize: 11.5, color: textSecondary, height: 1.3),
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

  // Step 5: Introduction to the Journey
  Widget _buildJourneyStep(bool isDark, Color surfaceColor, Color borderColor, Color textPrimary, Color textSecondary, AppStrings strings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBadge('05', 'MY JOURNEY', isDark, textPrimary),
          const SizedBox(height: 16),
          Text(
            'Your Personalized Exploration',
            style: LabTheme.serifStyle(fontSize: 22, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Mind Forensics structures exploration into 5 developmental phases without artificial deadlines.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: LabColors.sageGreenGlow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PHASE 1',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: LabColors.sageGreenGlow,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Self-Discovery',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Purpose: Understand your inner world, identify recurring thoughts, and recognize emotional patterns.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: textSecondary),
                ),
                const SizedBox(height: 14),
                _buildPhaseActivityRow('1.1', 'The Inner Observer', 'Observe automatic mental chatter'),
                const SizedBox(height: 8),
                _buildPhaseActivityRow('1.2', 'Thought vs. Reality', 'Distinguish narratives from tangible facts'),
                const SizedBox(height: 8),
                _buildPhaseActivityRow('1.3', 'Emotional Landscaping', 'Map physical sensations to feelings'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Phases 2 through 5 (Understanding Patterns, Awareness, Coping, Growth) unlock naturally as you reflect.',
            style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseActivityRow(String num, String title, String sub) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LabColors.champagneGold.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Text(
              num,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: LabColors.champagneGold),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(sub, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  // Step 6: Vault Authentication & Privacy Shield
  Widget _buildPrivacyConsentStep(bool isDark, Color surfaceColor, Color borderColor, Color textPrimary, Color textSecondary, AppStrings strings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBadge('06', 'VAULT & PRIVACY', isDark, textPrimary),
          const SizedBox(height: 16),
          Text(
            strings.onboardingVaultChoiceTitle,
            style: LabTheme.serifStyle(fontSize: 22, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            strings.onboardingVaultChoiceSubtitle,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
          ),
          const SizedBox(height: 20),

          // Choice Card 1: Anonymous Sovereign Vault
          BouncingWidget(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _vaultIsAnonymous = true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _vaultIsAnonymous
                    ? (isDark ? LabColors.darkWine.withValues(alpha: 0.35) : const Color(0xFFFBF8F6))
                    : surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _vaultIsAnonymous
                      ? LabColors.champagneGold
                      : borderColor,
                  width: _vaultIsAnonymous ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _vaultIsAnonymous
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 18,
                    color: _vaultIsAnonymous ? LabColors.champagneGold : textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              strings.anonymousOptionTitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: LabColors.sageGreenGlow.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                strings.anonymousChoiceBadge,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: LabColors.sageGreenGlow,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.anonymousOptionSubtitle,
                          style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Choice Card 2: Cloud-Synced Vault
          BouncingWidget(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _vaultIsAnonymous = false);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: !_vaultIsAnonymous
                    ? (isDark ? LabColors.darkWine.withValues(alpha: 0.35) : const Color(0xFFFBF8F6))
                    : surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: !_vaultIsAnonymous
                      ? LabColors.champagneGold
                      : borderColor,
                  width: !_vaultIsAnonymous ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        !_vaultIsAnonymous
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 18,
                        color: !_vaultIsAnonymous ? LabColors.champagneGold : textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  strings.vaultStatusCloud,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: LabColors.champagneGold.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    strings.cloudChoiceBadge,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                      color: LabColors.champagneGold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.linkEmailSubtitle,
                              style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!_vaultIsAnonymous) ...[
                    const SizedBox(height: 14),
                    Divider(color: borderColor, height: 1),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _onboardingEmailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textPrimary, fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: strings.emailFieldHint,
                        hintStyle: TextStyle(fontSize: 11.5, color: textSecondary.withValues(alpha: 0.6)),
                        prefixIcon: Icon(Icons.alternate_email_rounded, size: 16, color: textSecondary),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: LabColors.champagneGold)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _onboardingPasswordController,
                      obscureText: true,
                      style: TextStyle(color: textPrimary, fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: strings.passwordFieldHint,
                        hintStyle: TextStyle(fontSize: 11.5, color: textSecondary.withValues(alpha: 0.6)),
                        prefixIcon: Icon(Icons.lock_outline_rounded, size: 16, color: textSecondary),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: LabColors.champagneGold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Biometrics Option Toggle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.fingerprint_rounded, size: 18, color: LabColors.champagneGold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.biometricEnableToggle,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                ),
                Switch(
                  value: _enableBiometrics,
                  activeTrackColor: LabColors.champagneGold,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _enableBiometrics = val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Privacy Pillars
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPrivacyPillar(
                  icon: Icons.lock_outline_rounded,
                  title: 'Local On-Device Storage',
                  desc: 'All notes, journal entries, and check-ins are stored in your private local vault.',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 14),
                _buildPrivacyPillar(
                  icon: Icons.delete_outline_rounded,
                  title: 'Instant Erasure',
                  desc: 'You can export or permanently wipe all your data from Settings at any time.',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 14),
                _buildPrivacyPillar(
                  icon: Icons.visibility_off_outlined,
                  title: 'No Data Brokerage',
                  desc: 'Your entries are never used to train commercial models or shared with third parties.',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // AI Profile Context Toggle
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? LabColors.darkWine.withValues(alpha: 0.35) : const Color(0xFFFBF8F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? LabColors.wineBorder : LabColors.champagneGold.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Companion Profile Context',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Allow AI companion to adapt pacing and tone based on your selected profile conditions.',
                        style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _consentAiContext,
                  activeTrackColor: LabColors.champagneGold,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _consentAiContext = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPrivacyPillar({
    required IconData icon,
    required String title,
    required String desc,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: LabColors.champagneGold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(fontSize: 11.5, color: textSecondary, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}
