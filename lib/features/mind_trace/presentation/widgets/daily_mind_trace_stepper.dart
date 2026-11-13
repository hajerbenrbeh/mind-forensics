import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../core/safety/crisis_keywords.dart';
import '../../../../core/safety/safety_interceptor.dart';
import '../../../../core/widgets/bouncing_widget.dart';
import '../../../../core/widgets/fingerprint_thread_signature.dart';
import '../../../profile/controllers/profile_controller.dart';
import '../../controllers/mind_trace_controller.dart';
import '../../domain/dynamic_question_generator.dart';
import '../../domain/emotion_descriptors.dart';
import '../../domain/mind_trace_model.dart';
import 'trace_entry_detail_sheet.dart';

/// Multi-step, interactive Daily Mind Trace check-in wizard.
///
/// Steps:
/// 1. How are you feeling? (14 exact emotions + custom)
/// 2. Emotional intensity (1-10 interactive scale)
/// 3. How is your mind? (Racing thoughts, concentration, intrusive thoughts, mental clarity, disconnection)
/// 4. How is your body? (Energy level, sleep duration, sleep quality, physical tension)
///
/// Followed by a dedicated Completion Screen celebrating the recorded trace.
class DailyMindTraceStepper extends ConsumerStatefulWidget {
  const DailyMindTraceStepper({
    super.key,
    this.initialTrace,
    required this.onViewConstellation,
    this.onReturnHome,
  });

  final MindTraceModel? initialTrace;
  final VoidCallback onViewConstellation;
  final VoidCallback? onReturnHome;

  @override
  ConsumerState<DailyMindTraceStepper> createState() =>
      _DailyMindTraceStepperState();
}

class _DailyMindTraceStepperState extends ConsumerState<DailyMindTraceStepper> {
  int _currentStep = 0; // 0 to 3: Steps 1-4; 4: Completion Screen
  bool _isSaving = false;

  // Step 1: Emotions
  final Set<String> _selectedEmotions = {};
  String _overallMood = 'calm';

  // Step 2: Intensity
  double _moodIntensity = 5.0;

  // Step 3: Mind
  double _racingThoughts = 4.0;
  double _concentrationLevel = 6.0;
  double _intrusiveThoughts = 3.0;
  double _mentalClarity = 6.0;
  double _emotionalDisconnection = 2.0;
  final Map<String, TextEditingController> _dynamicQuestionControllers = {};

  // Step 4: Body
  double _energyLevel = 5.0;
  double _sleepHours = 7.0;
  int _sleepQuality = 4; // 1-5
  double _physicalTension = 4.0;
  bool _hasVoiceNote = false;

  // Completed saved trace cache
  MindTraceModel? _completedTrace;

  @override
  void initState() {
    super.initState();
    if (widget.initialTrace != null) {
      _hydrateFromTrace(widget.initialTrace!);
    }
  }

  void _hydrateFromTrace(MindTraceModel trace) {
    _overallMood = trace.overallMood;
    _selectedEmotions.clear();
    _selectedEmotions.addAll(trace.selectedEmotions);
    _moodIntensity = trace.moodIntensity.toDouble();
    _racingThoughts = (trace.racingThoughts ?? 4).toDouble();
    _concentrationLevel = (trace.concentrationLevel ?? 6).toDouble();
    _intrusiveThoughts = (trace.intrusiveThoughts ?? 3).toDouble();
    _mentalClarity = (trace.mentalClarity ?? 6).toDouble();
    _emotionalDisconnection = (trace.emotionalDisconnection ?? 2).toDouble();
    _energyLevel = (trace.energyLevel ?? 5).toDouble();
    _sleepHours = trace.sleepHours ?? 7.0;
    _sleepQuality = trace.sleepQuality ?? 4;
    _physicalTension = (trace.physicalTension ?? 4).toDouble();
    if (trace.voiceNotePath != null) {
      _hasVoiceNote = true;
    }
    for (final entry in trace.dynamicAnswers.entries) {
      _dynamicQuestionControllers[entry.key] =
          TextEditingController(text: entry.value);
    }
  }

  @override
  void dispose() {
    for (final c in _dynamicQuestionControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitTrace() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final now = DateTime.now();
    final todayKey =
        'trace_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final mergedDynamicAnswers = <String, String>{
      if (widget.initialTrace != null) ...widget.initialTrace!.dynamicAnswers,
    };
    for (final entry in _dynamicQuestionControllers.entries) {
      final text = entry.value.text.trim();
      if (text.isNotEmpty) {
        mergedDynamicAnswers[entry.key] = text;
      } else {
        // Intentionally cleared/deleted by user in this session:
        mergedDynamicAnswers.remove(entry.key);
      }
    }

    // Layer 1 crisis pre-scan: Intercept Level 2 phrases immediately
    for (final answer in mergedDynamicAnswers.values) {
      if (CrisisKeywords.evaluateText(answer) == 2) {
        setState(() => _isSaving = false);
        if (mounted) {
          SafetyInterceptor.showCrisisPauseDialog(context);
        }
        return;
      }
    }

    final effectiveMood = _selectedEmotions.isNotEmpty
        ? _selectedEmotions.first.toLowerCase()
        : _overallMood;

    final voicePath = _hasVoiceNote
        ? (widget.initialTrace?.voiceNotePath ??
            'memo_${now.millisecondsSinceEpoch}.m4a')
        : widget.initialTrace?.voiceNotePath;

    final trace = widget.initialTrace != null
        ? widget.initialTrace!.copyWith(
            overallMood: effectiveMood,
            selectedEmotions: _selectedEmotions.toList(),
            moodIntensity: _moodIntensity.toInt(),
            energyLevel: _energyLevel.toInt(),
            sleepHours: _sleepHours,
            sleepQuality: _sleepQuality,
            physicalTension: _physicalTension.toInt(),
            concentrationLevel: _concentrationLevel.toInt(),
            mentalClarity: _mentalClarity.toInt(),
            racingThoughts: _racingThoughts.toInt(),
            intrusiveThoughts: _intrusiveThoughts.toInt(),
            emotionalDisconnection: _emotionalDisconnection.toInt(),
            dynamicAnswers: mergedDynamicAnswers,
            voiceNotePath: voicePath,
            isCompleted: true,
            updatedAt: now,
          )
        : MindTraceModel(
            id: todayKey,
            date: now,
            overallMood: effectiveMood,
            selectedEmotions: _selectedEmotions.toList(),
            moodIntensity: _moodIntensity.toInt(),
            energyLevel: _energyLevel.toInt(),
            sleepHours: _sleepHours,
            sleepQuality: _sleepQuality,
            physicalTension: _physicalTension.toInt(),
            concentrationLevel: _concentrationLevel.toInt(),
            mentalClarity: _mentalClarity.toInt(),
            racingThoughts: _racingThoughts.toInt(),
            intrusiveThoughts: _intrusiveThoughts.toInt(),
            emotionalDisconnection: _emotionalDisconnection.toInt(),
            dynamicAnswers: mergedDynamicAnswers,
            voiceNotePath: voicePath,
            isCompleted: true,
            createdAt: now,
            updatedAt: now,
          );

    try {
      await ref.read(mindTraceControllerProvider.notifier).recordCheckIn(
            trace,
            generateAi: false, // Prevents fabricated AI diagnostics if unconfigured
          );

      if (mounted) {
        setState(() {
          _completedTrace = trace;
          _currentStep = 4; // Move to Completion Screen
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _promptCustomEmotion(AppStrings strings, bool isDark) {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final border = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
        final bg = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
        final textPrimary =
            isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.isArabic ? 'إضافة شعور مخصص' : 'Custom Emotion',
                  style: LabTheme.serifStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  autofocus: true,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: strings.isArabic
                        ? 'دوّن الإحساس بدقة (مثال: حنين، سكينة)...'
                        : 'Enter nuanced feeling (e.g. yearning, grounded)...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF141414) : const Color(0xFFF4F4F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: LabColors.champagneGold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        strings.isArabic ? 'إلغاء' : 'Cancel',
                        style: TextStyle(color: isDark ? Colors.grey : Colors.black54),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        final val = textController.text.trim();
                        if (val.isNotEmpty) {
                          setState(() {
                            _selectedEmotions.add(val);
                          });
                        }
                        Navigator.pop(ctx);
                      },
                      child: Text(strings.isArabic ? 'إضافة' : 'Add Emotion'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);

    final surfaceColor =
        isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final borderColor =
        isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary =
        isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary =
        isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    if (_currentStep == 4) {
      return _buildCompletionScreen(
        isDark: isDark,
        strings: strings,
        surfaceColor: surfaceColor,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Progress Bar
          _buildProgressBar(isDark, borderColor),

          const SizedBox(height: 16),

          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStepTitle(_currentStep, strings).toUpperCase(),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: LabColors.champagneGold,
                ),
              ),
              Text(
                '${strings.isArabic ? 'خطوة' : 'STEP'} ${_currentStep + 1}/4',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Render active step
          if (_currentStep == 0)
            _buildStep1Emotions(isDark, strings, surfaceColor, borderColor, textPrimary, textSecondary)
          else if (_currentStep == 1)
            _buildStep2Intensity(isDark, strings, surfaceColor, borderColor, textPrimary, textSecondary)
          else if (_currentStep == 2)
            _buildStep3Mind(isDark, strings, surfaceColor, borderColor, textPrimary, textSecondary)
          else if (_currentStep == 3)
            _buildStep4Body(isDark, strings, surfaceColor, borderColor, textPrimary, textSecondary),

          const SizedBox(height: 28),

          // Navigation Controls
          _buildNavigationRow(isDark, strings, borderColor, textPrimary, textSecondary),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProgressBar(bool isDark, Color borderColor) {
    final progress = (_currentStep + 1) / 4.0;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFE4E4E7),
            valueColor: const AlwaysStoppedAnimation<Color>(LabColors.champagneGold),
          ),
        ),
      ],
    );
  }

  String _getStepTitle(int step, AppStrings strings) {
    switch (step) {
      case 0:
        return strings.isArabic ? '1. كيف تشعر اليوم؟' : '1. How Are You Feeling?';
      case 1:
        return strings.isArabic ? '2. شدة المشاعر' : '2. Emotional Intensity';
      case 2:
        return strings.isArabic ? '3. حالة ذهنك وأفكارك' : '3. How Is Your Mind?';
      case 3:
        return strings.isArabic ? '4. حالة جسدك وطاقتك' : '4. How Is Your Body?';
      default:
        return '';
    }
  }

  // ===========================================================================
  // STEP 1: HOW ARE YOU FEELING? (14 EMOTIONS)
  // ===========================================================================
  Widget _buildStep1Emotions(
    bool isDark,
    AppStrings strings,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.isArabic
              ? 'اختر المشاعر التي تعبّر عن حالتك الآن'
              : 'Select all emotions that reflect your inner state right now.',
          style: LabTheme.serifStyle(
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          strings.isArabic
              ? 'يمكنك اختيار أكثر من شعور أو إضافة شعور شخصي خاص.'
              : 'Multi-selection enabled. Nuanced mixtures welcome.',
          style: TextStyle(fontSize: 11.5, color: textSecondary),
        ),
        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.7,
          ),
          itemCount: EmotionDescriptor.library.length,
          itemBuilder: (context, index) {
            final desc = EmotionDescriptor.library[index];
            final isCustom = desc.key == 'custom';
            final isSelected = _selectedEmotions.contains(desc.localized(strings)) ||
                _selectedEmotions.contains(desc.englishLabel) ||
                _selectedEmotions.contains(desc.arabicLabel);

            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                if (isCustom) {
                  _promptCustomEmotion(strings, isDark);
                } else {
                  final label = desc.localized(strings);
                  setState(() {
                    if (isSelected) {
                      _selectedEmotions.remove(label);
                      _selectedEmotions.remove(desc.englishLabel);
                      _selectedEmotions.remove(desc.arabicLabel);
                    } else {
                      _selectedEmotions.add(label);
                    }
                  });
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? LabColors.darkWine : const Color(0xFFFBE8E9))
                      : surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? LabColors.champagneGold
                        : borderColor,
                    width: isSelected ? 1.2 : 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      desc.icon,
                      size: 16,
                      color: isSelected
                          ? LabColors.champagneGold
                          : (isDark ? Colors.grey : Colors.grey.shade700),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        desc.localized(strings),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? LabColors.warmIvory : LabColors.deepBurgundy)
                              : textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: LabColors.champagneGold,
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        // Custom emotions chips if any added
        if (_selectedEmotions.any((e) =>
            !EmotionDescriptor.library.any((d) =>
                d.englishLabel == e ||
                d.arabicLabel == e ||
                d.frenchLabel == e))) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: _selectedEmotions
                .where((e) => !EmotionDescriptor.library.any((d) =>
                    d.englishLabel == e ||
                    d.arabicLabel == e ||
                    d.frenchLabel == e))
                .map((custom) => Chip(
                      label: Text(
                        custom,
                        style: const TextStyle(fontSize: 11, color: LabColors.warmIvory),
                      ),
                      backgroundColor: LabColors.darkWine,
                      deleteIcon: const Icon(Icons.close, size: 12, color: Colors.white70),
                      onDeleted: () {
                        setState(() => _selectedEmotions.remove(custom));
                      },
                      side: const BorderSide(color: LabColors.champagneGold, width: 0.8),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // STEP 2: EMOTIONAL INTENSITY (1-10)
  // ===========================================================================
  Widget _buildStep2Intensity(
    bool isDark,
    AppStrings strings,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final intensityVal = _moodIntensity.toInt();
    String intensityDesc = strings.isArabic ? 'متوسط / معتاد' : 'Moderate / Present';
    if (intensityVal <= 3) {
      intensityDesc = strings.isArabic ? 'خفيف / هادئ' : 'Mild / Low Arousal';
    } else if (intensityVal >= 8) {
      intensityDesc = strings.isArabic ? 'مرتفع / شديد' : 'High / Intense Arousal';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.isArabic ? 'ما مدى شدة هذه المشاعر الآن؟' : 'How intensely do you feel this right now?',
          style: LabTheme.serifStyle(
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          strings.isArabic
              ? 'مقياس إدراكي من 1 (شعور طفيف جداً) إلى 10 (استثارة انفعالية قوية).'
              : 'Interactive 1 to 10 scale tracking arousal.',
          style: TextStyle(fontSize: 11.5, color: textSecondary),
        ),
        const SizedBox(height: 24),

        // Big Display Card
        Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF12080A) : const Color(0xFFFAF5F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: LabColors.wineBorder,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$intensityVal',
                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    color: intensityVal >= 8
                        ? LabColors.cherryRedGlow
                        : (intensityVal <= 3
                            ? LabColors.champagneGold
                            : (isDark ? Colors.white : Colors.black)),
                  ),
                ),
                Text(
                  '/ 10',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? LabColors.safetySoftBgDark : LabColors.safetySoftBgLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LabColors.wineBorder),
                  ),
                  child: Text(
                    intensityDesc.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: LabColors.champagneGold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Discrete numbers row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(10, (idx) {
            final val = idx + 1;
            final isCurrent = val == intensityVal;
            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _moodIntensity = val.toDouble());
              },
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 28,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? (isDark ? Colors.white : Colors.black)
                      : surfaceColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCurrent
                        ? (isDark ? Colors.white : Colors.black)
                        : borderColor,
                  ),
                ),
                child: Text(
                  '$val',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                    color: isCurrent
                        ? (isDark ? Colors.black : Colors.white)
                        : textSecondary,
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 16),

        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: LabColors.champagneGold,
            inactiveTrackColor: isDark ? const Color(0xFF222222) : const Color(0xFFE4E4E7),
            thumbColor: LabColors.warmIvory,
            overlayColor: LabColors.champagneGold.withValues(alpha: 0.2),
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
      ],
    );
  }

  // ===========================================================================
  // STEP 3: HOW IS YOUR MIND? (OPTIONAL COGNITIVE CHECK)
  // ===========================================================================
  Widget _buildStep3Mind(
    bool isDark,
    AppStrings strings,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final profile = ref.watch(profileControllerProvider).value;
    final locale = ref.watch(localeControllerProvider);
    final traces = ref.watch(mindTraceControllerProvider).value ?? [];

    final dynamicQuestions = DynamicQuestionGenerator.getQuestionsForUser(
      profile: profile,
      recentTraces: traces,
      languageCode: locale.languageCode,
    );

    for (final q in dynamicQuestions) {
      _dynamicQuestionControllers.putIfAbsent(q.id, () => TextEditingController());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                strings.isArabic ? 'كيف تبدو وتيرة أفكارك اليوم؟' : 'How is your mind operating today?',
                style: LabTheme.serifStyle(
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF181818) : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                strings.isArabic ? 'اختياري' : 'OPTIONAL',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          strings.isArabic
              ? 'ملاحظة الأفكار التلقائية وسرعتها وتشتتها دون إصدار أحكام.'
              : 'Observe cognitive speed, focus, and clarity without judgment.',
          style: TextStyle(fontSize: 11.5, color: textSecondary),
        ),
        const SizedBox(height: 20),

        // 1. Racing thoughts
        _buildMetricSlider(
          label: strings.isArabic ? 'تسارع وتزاحم الأفكار' : 'Racing Thoughts',
          subtitle: strings.isArabic ? 'أفكار متسارعة يصعب إيقافها' : 'Thoughts racing rapidly',
          value: _racingThoughts,
          onChanged: (v) => setState(() => _racingThoughts = v),
          isDark: isDark,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 12),

        // 2. Concentration
        _buildMetricSlider(
          label: strings.isArabic ? 'التركيز والقدرة على الانتباه' : 'Concentration & Focus',
          subtitle: strings.isArabic ? 'سهولة البقاء في مهمة واحدة' : 'Ability to stay on task',
          value: _concentrationLevel,
          onChanged: (v) => setState(() => _concentrationLevel = v),
          isDark: isDark,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 12),

        // 3. Intrusive thoughts
        _buildMetricSlider(
          label: strings.isArabic ? 'الأفكار المتسللة المزعجة' : 'Intrusive Thoughts',
          subtitle: strings.isArabic ? 'أفكار غير مرغوبة تلح على الذهن' : 'Unwanted repetitive thoughts',
          value: _intrusiveThoughts,
          onChanged: (v) => setState(() => _intrusiveThoughts = v),
          isDark: isDark,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 12),

        // 4. Mental clarity
        _buildMetricSlider(
          label: strings.isArabic ? 'الوضوح الذهني' : 'Mental Clarity',
          subtitle: strings.isArabic ? 'صفاء التفكير وغياب الضبابية' : 'Clarity versus brain fog',
          value: _mentalClarity,
          onChanged: (v) => setState(() => _mentalClarity = v),
          isDark: isDark,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 12),

        // 5. Emotional disconnection
        _buildMetricSlider(
          label: strings.isArabic ? 'الانفصال الذهني أو الشعوري' : 'Emotional Disconnection',
          subtitle: strings.isArabic ? 'الشعور بالتبلد أو الغربة عن الواقع' : 'Numbness or detachment',
          value: _emotionalDisconnection,
          onChanged: (v) => setState(() => _emotionalDisconnection = v),
          isDark: isDark,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),

        // Tailored inquiries if any
        if (dynamicQuestions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            strings.isArabic ? 'أسئلة استبصار مخصصة' : 'TAILORED INQUIRIES',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: LabColors.champagneGold,
            ),
          ),
          const SizedBox(height: 10),
          ...dynamicQuestions.map((q) {
            final controller = _dynamicQuestionControllers[q.id]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.questionText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller,
                      maxLines: 2,
                      style: TextStyle(fontSize: 12, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: strings.isArabic
                            ? 'دوّن إجابتك بحرية (اختياري)...'
                            : 'Optional brief reflection...',
                        hintStyle: TextStyle(
                            fontSize: 11,
                            color: textSecondary.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF101010)
                            : const Color(0xFFF4F4F5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  // ===========================================================================
  // STEP 4: HOW IS YOUR BODY? (OPTIONAL SOMATIC CHECK)
  // ===========================================================================
  Widget _buildStep4Body(
    bool isDark,
    AppStrings strings,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final qualityLabels = strings.isArabic
        ? ['ضعيف جداً', 'متقطع', 'مقبول', 'جيد', 'مريح ومجدد']
        : ['Very Poor', 'Restless', 'Fair', 'Good', 'Restful'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                strings.isArabic ? 'ماذا يخبرك جسدك اليوم؟' : 'What is your body communicating?',
                style: LabTheme.serifStyle(
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF181818) : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                strings.isArabic ? 'اختياري' : 'OPTIONAL',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          strings.isArabic
              ? 'مستويات النشاط، جودة النوم، والتوتر العضلي.'
              : 'Physical energy, sleep metrics, and somatic tension.',
          style: TextStyle(fontSize: 11.5, color: textSecondary),
        ),
        const SizedBox(height: 20),

        // 1. Energy level
        _buildMetricSlider(
          label: strings.isArabic ? 'مستوى الطاقة والنشاط' : 'Energy Level',
          subtitle: strings.isArabic ? 'من الإرهاق التام إلى الحيوية العالية' : 'Exhausted to high vitality',
          value: _energyLevel,
          onChanged: (v) => setState(() => _energyLevel = v),
          isDark: isDark,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 16),

        // 2. Sleep duration
        Container(
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
                    strings.isArabic ? 'مدة النوم الليلة الماضية' : 'Sleep Duration',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    '${_sleepHours.toStringAsFixed(1)} ${strings.isArabic ? 'ساعة' : 'hours'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: LabColors.champagneGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: LabColors.champagneGold,
                  inactiveTrackColor: isDark ? const Color(0xFF222222) : const Color(0xFFE4E4E7),
                  thumbColor: textPrimary,
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: _sleepHours,
                  min: 0,
                  max: 14,
                  divisions: 28,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _sleepHours = v);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Sleep quality (1-5)
        Container(
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
                    strings.isArabic ? 'جودة النوم' : 'Sleep Quality',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    qualityLabels[_sleepQuality - 1],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: LabColors.champagneGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (idx) {
                  final score = idx + 1;
                  final isSelected = score == _sleepQuality;
                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _sleepQuality = score);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 52,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? LabColors.darkWine : const Color(0xFFFBE8E9))
                            : (isDark ? const Color(0xFF141414) : const Color(0xFFF4F4F5)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? LabColors.champagneGold : borderColor,
                        ),
                      ),
                      child: Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? LabColors.champagneGold : textSecondary,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Physical tension
        _buildMetricSlider(
          label: strings.isArabic ? 'التوتر الجسدي الملحوظ' : 'Physical Tension',
          subtitle: strings.isArabic ? 'تشنج العضلات أو ثقل الصدر' : 'Muscle clenching or body tightness',
          value: _physicalTension,
          onChanged: (v) => setState(() => _physicalTension = v),
          isDark: isDark,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
      ],
    );
  }

  // ===========================================================================
  // COMPLETION SCREEN
  // ===========================================================================
  Widget _buildCompletionScreen({
    required bool isDark,
    required AppStrings strings,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final trace = _completedTrace;
    final emotions = trace?.selectedEmotions ?? _selectedEmotions.toList();
    final intensity = trace?.moodIntensity ?? _moodIntensity.toInt();
    final journal = trace?.journalText?.trim();
    final hasJournal = journal != null && journal.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Celestial Starlight Badge
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E0B10) : const Color(0xFFFBE8E9),
              border: Border.all(color: LabColors.champagneGold, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: LabColors.champagneGold.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: FingerprintThreadSignature(size: 38, animated: true),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            strings.isArabic
                ? 'تم توثيق أثر اليوم بنجاح'
                : "Today's trace has been recorded.",
            textAlign: TextAlign.center,
            style: LabTheme.serifStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.isArabic
                ? 'تم حفظ أثر فكرتك بأمان في أرشيفك الشخصي.'
                : 'Your thought trace is recorded in your personal archive on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta: Emotions & Intensity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      (strings.isArabic ? 'الحالة المعاشة' : 'LIVED STATE').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: LabColors.champagneGold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141414) : const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        '${strings.isArabic ? 'الشدة' : 'Intensity'}: $intensity/10',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Emotions Badges
                if (emotions.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: emotions.map((emotion) {
                      final icon = EmotionDescriptor.iconForLabel(emotion);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F6),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 12, color: LabColors.champagneGold),
                            const SizedBox(width: 5),
                            Text(
                              emotion,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 14),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 14),

                // Grounding Reflection (No fabricated AI diagnostics)
                Text(
                  (strings.isArabic ? 'تأمل ورسوّ' : 'GROUNDED REFLECTION').toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasJournal
                      ? '“$journal”'
                      : (strings.isArabic
                          ? '«ملاحظتك لمشاعرك وتسميتها دون لوم ذاتي هو أول خطوة لاستعادة التوازن والوضوح الإدراكي. أثرك مسجل بأمان.»'
                          : '“Noticing and naming your emotional experiences creates valuable space between impulse and response. Your trace is safely preserved.”'),
                  style: LabTheme.editorialSerif(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Primary Button: View in The Thought Trace
          BouncingWidget(
            onTap: widget.onViewConstellation,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fingerprint_rounded,
                    size: 16,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (strings.isArabic
                            ? 'استكشاف أثر الأفكار'
                            : 'VIEW IN THE THOUGHT TRACE')
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Secondary: Review full entry sheet
          if (trace != null)
            BouncingWidget(
              onTap: () {
                TraceEntryDetailSheet.show(context, trace: trace);
              },
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                alignment: Alignment.center,
                child: Text(
                  (strings.isArabic ? 'مراجعة تفاصيل الأثر' : 'REVIEW ENTRY DETAILS')
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: textPrimary,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 10),

          // Return Home
          if (widget.onReturnHome != null)
            TextButton(
              onPressed: widget.onReturnHome,
              child: Text(
                strings.isArabic ? 'العودة إلى الصفحة الرئيسية' : 'Return to Home',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // NAVIGATION CONTROLS ROW
  // ===========================================================================
  Widget _buildNavigationRow(
    bool isDark,
    AppStrings strings,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isLastStep = _currentStep == 3;

    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _currentStep--);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                alignment: Alignment.center,
                child: Text(
                  strings.isArabic ? 'السابق' : 'BACK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Optional Skip button for optional steps (Step 2: Mind, Step 3: Body)
        if (_currentStep >= 2 && !isLastStep) ...[
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _currentStep++);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              child: Text(
                strings.isArabic ? 'تخطي' : 'Skip',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],

        // Next or Submit Primary Button
        Expanded(
          flex: 4,
          child: BouncingWidget(
            onTap: _isSaving
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    if (isLastStep) {
                      _submitTrace();
                    } else {
                      setState(() => _currentStep++);
                    }
                  },
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: _isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    )
                  : Text(
                      isLastStep
                          ? strings.recordTraceBtn
                          : (strings.isArabic ? 'متابعة' : 'CONTINUE')
                              .toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricSlider({
    required String label,
    required String subtitle,
    required double value,
    required ValueChanged<double> onChanged,
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? LabColors.nightSurface : LabColors.daylightSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: textSecondary),
                  ),
                ],
              ),
              Text(
                '${value.toInt()}/10',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: LabColors.champagneGold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: LabColors.champagneGold,
              inactiveTrackColor: isDark ? const Color(0xFF222222) : const Color(0xFFE4E4E7),
              thumbColor: textPrimary,
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
