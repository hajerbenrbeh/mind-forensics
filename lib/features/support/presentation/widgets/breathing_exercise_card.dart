import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../investigation/presentation/widgets/vagal_breathing_visualizer.dart';

/// Authoritative Box Breathing Pacer card:
/// - 4-4-4-4 vagal regulation rhythm
/// - Immediate Start, Pause, and Reset controls
/// - Zero fixed repetition penalty; stop anytime
/// - One-tap switch to Sensory Grounding alternative
class BreathingExerciseCard extends ConsumerStatefulWidget {
  const BreathingExerciseCard({
    super.key,
    required this.onSwitchToGrounding,
  });

  final VoidCallback onSwitchToGrounding;

  @override
  ConsumerState<BreathingExerciseCard> createState() =>
      _BreathingExerciseCardState();
}

class _BreathingExerciseCardState extends ConsumerState<BreathingExerciseCard> {
  bool _isActive = false;
  int _secondsLeft = 4;
  int _phase = 0; // 0: Inhale (4s), 1: Hold (4s), 2: Exhale (4s), 3: Hold (4s)
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleBreathing() {
    HapticFeedback.lightImpact();
    if (_isActive) {
      _stopBreathing();
    } else {
      _startBreathing();
    }
  }

  void _startBreathing() {
    setState(() {
      _isActive = true;
      _secondsLeft = 4;
      _phase = 0;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _secondsLeft = 4;
          _phase = (_phase + 1) % 4;
          if (_phase == 0) {
            HapticFeedback.mediumImpact();
          } else {
            HapticFeedback.selectionClick();
          }
        }
      });
    });
  }

  void _stopBreathing() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _secondsLeft = 4;
      _phase = 0;
    });
  }

  String _getPhaseText(int phase, AppStrings strings) {
    switch (phase) {
      case 0:
        return strings.isArabic
            ? 'شهيق عميق من الأنف...'
            : (strings.isFrench ? 'Inspiration lente...' : 'Slow Inhalation...');
      case 1:
        return strings.isArabic
            ? 'احبس النفس بلطف...'
            : (strings.isFrench ? 'Rétention paisible...' : 'Gentle Hold...');
      case 2:
        return strings.isArabic
            ? 'زفير ممتد من الفم...'
            : (strings.isFrench ? 'Expiration prolongée...' : 'Extended Exhalation...');
      case 3:
      default:
        return strings.isArabic
            ? 'سكون واستقرار...'
            : (strings.isFrench ? 'Repos au calme...' : 'Resting Stillness...');
    }
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  strings.breathingTitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: widget.onSwitchToGrounding,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: LabColors.sageGreen,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  strings.sensoryGroundingTitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isActive) ...[
            VagalBreathingVisualizer(
              phase: _phase,
              secondsLeft: _secondsLeft,
              phaseText: _getPhaseText(_phase, strings),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LabColors.beigeBackground(isDark: isDark),
                      border: Border.all(
                        color: LabColors.beigeBorder(isDark: isDark),
                      ),
                    ),
                    child: Icon(
                      Icons.air_rounded,
                      color: isDark ? LabColors.warmBeige : LabColors.warmBeigeDark,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.breathingDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _toggleBreathing,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isActive ? surfaceColor : textPrimary,
                foregroundColor: _isActive ? textPrimary : (isDark ? Colors.black : Colors.white),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: _isActive ? BorderSide(color: borderColor) : BorderSide.none,
                ),
              ),
              child: Text(
                _isActive
                    ? (strings.isArabic ? 'إيقاف التنفس' : 'Pause Exercise')
                    : (strings.isArabic ? 'بدء تنفس 4-4-4-4' : 'Begin 4-4-4-4 Breathing'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
