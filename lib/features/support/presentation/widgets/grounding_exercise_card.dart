import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';

/// 5-4-3-2-1 Sensory Grounding Card:
/// - Reorients cognitive attention to immediate environment
/// - Sensory grounding alternative for individuals who experience breath-holding anxiety
/// - Step-by-step taps, options-first, 0 emojis
class GroundingExerciseCard extends ConsumerStatefulWidget {
  const GroundingExerciseCard({
    super.key,
    required this.onSwitchToBreathing,
  });

  final VoidCallback onSwitchToBreathing;

  @override
  ConsumerState<GroundingExerciseCard> createState() =>
      _GroundingExerciseCardState();
}

class _GroundingExerciseCardState extends ConsumerState<GroundingExerciseCard> {
  int _currentStep = 0; // 0: See (5), 1: Touch (4), 2: Hear (3), 3: Smell (2), 4: Taste (1), 5: Complete

  void _nextStep() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_currentStep < 5) {
        _currentStep++;
      } else {
        _currentStep = 0;
      }
    });
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

    final steps = [
      (
        count: '5',
        title: strings.groundingSee,
        cue: strings.isArabic
            ? 'انظر حولك ولاحظ خمسة تفاصيل مرئية: إضاءة، لون، شكل هندسي، ظل، أو جسم قريب.'
            : (strings.isFrench
                ? 'Regardez autour de vous et observez cinq détails visuels, ombres ou textures.'
                : 'Look around and notice five distinct visual objects, shadows, or textures in your space.'),
        icon: Icons.visibility_outlined,
      ),
      (
        count: '4',
        title: strings.groundingTouch,
        cue: strings.isArabic
            ? 'المس أربعة أسطح ملموسة: ملمس ثيابك، برودة سطح الطاولة، قدميك على الأرض، أو هاتفك.'
            : (strings.isFrench
                ? 'Touchez quatre textures concrètes : votre vêtement, le bureau, vos pieds au sol ou votre téléphone.'
                : 'Feel four physical textures: your clothing fabric, the desk surface, feet on the floor, or your phone.'),
        icon: Icons.touch_app_outlined,
      ),
      (
        count: '3',
        title: strings.groundingHear,
        cue: strings.isArabic
            ? 'أنصت لثلاثة أصوات في محيطك: صوت تكييف، صوت في الشارع، أو صوت تنفسك.'
            : (strings.isFrench
                ? 'Écoutez trois sons réels autour de vous : le bruit ambiant, la rue au loin ou votre respiration.'
                : 'Listen for three real sounds: ambient room tone, traffic in the distance, or your own breath.'),
        icon: Icons.hearing_outlined,
      ),
      (
        count: '2',
        title: strings.groundingSmell,
        cue: strings.isArabic
            ? 'لاحظ رائحتين في الهواء أو استرجع رائحة مهدئة تألفها.'
            : (strings.isFrench
                ? 'Remarquez deux odeurs dans l’air ou évoquez un parfum familier et apaisant.'
                : 'Notice two scents in the air, or recall a familiar grounding scent like coffee or fresh rain.'),
        icon: Icons.filter_vintage_outlined,
      ),
      (
        count: '1',
        title: strings.groundingTaste,
        cue: strings.isArabic
            ? 'لاحظ طعماً في فمك أو خذ رشفة ماء وابقَ حاضراً في هذه اللحظة.'
            : (strings.isFrench
                ? 'Prenez une petite gorgée d’eau ou portez attention à l’air frais dans votre bouche.'
                : 'Take a gentle sip of water or focus on the physical sensation of cool air entering your mouth.'),
        icon: Icons.eco_outlined,
      ),
    ];

    final isFinished = _currentStep == 5;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.sensoryGroundingTitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: textSecondary,
                ),
              ),
              TextButton(
                onPressed: widget.onSwitchToBreathing,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: LabColors.sageGreen,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  strings.breathingTitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isFinished) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: LabColors.sageGreen.withValues(alpha: 0.15),
                        border: Border.all(color: LabColors.sageGreen),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: LabColors.sageGreen,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.isArabic
                          ? 'أنت حاضر في مكانك الآن'
                          : (strings.isFrench
                              ? 'Vous êtes ancré et présent'
                              : 'You are grounded and present'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.isArabic
                          ? 'أخذت لحظة لتذكير جهازك العصبي بأنك في أمان واقعي.'
                          : (strings.isFrench
                              ? 'Vous avez offert à votre système nerveux un point d’ancrage concret.'
                              : 'You gave your nervous system a calm point of physical orientation.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Row(
              children: List.generate(5, (index) {
                final isPassed = index < _currentStep;
                final isCurrent = index == _currentStep;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: index == 4 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: isPassed
                          ? LabColors.sageGreen
                          : (isCurrent ? textPrimary : borderColor),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: LabColors.beigeBackground(isDark: isDark),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: LabColors.beigeBorder(isDark: isDark)),
                  ),
                  child: Center(
                    child: Text(
                      steps[_currentStep].count,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? LabColors.warmBeige : LabColors.warmBeigeDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    steps[_currentStep].title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              steps[_currentStep].cue,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 18),
          ],
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: textPrimary,
                foregroundColor: isDark ? Colors.black : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isFinished
                    ? (strings.isArabic
                        ? 'إعادة التمرين'
                        : (strings.isFrench
                            ? 'Recommencer l’ancrage'
                            : 'Restart Grounding'))
                    : (strings.isArabic
                        ? 'لاحظت هذا • التالي'
                        : (strings.isFrench
                            ? 'Observé • Étape suivante'
                            : 'Noticed • Next Step')),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

