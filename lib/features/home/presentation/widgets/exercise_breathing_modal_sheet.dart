import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../investigation/presentation/widgets/vagal_breathing_visualizer.dart';

/// Modal bottom sheet providing the 4-4-4-4 Vagal Breathing practice
/// triggered from the "Exercises for you" card on the Home dashboard.
class ExerciseBreathingModalSheet extends StatefulWidget {
  const ExerciseBreathingModalSheet({
    super.key,
    required this.strings,
  });

  final AppStrings strings;

  static Future<void> show(BuildContext context, AppStrings strings) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseBreathingModalSheet(strings: strings),
    );
  }

  @override
  State<ExerciseBreathingModalSheet> createState() => _ExerciseBreathingModalSheetState();
}

class _ExerciseBreathingModalSheetState extends State<ExerciseBreathingModalSheet> {
  Timer? _timer;
  int _secondsLeft = 4;
  int _phase = 0; // 0: Inhale (4s), 1: Hold (4s), 2: Exhale (4s), 3: Hold (4s)
  bool _isRunning = true;
  int _completedCycles = 0;

  @override
  void initState() {
    super.initState();
    _startPacer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPacer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _phase = (_phase + 1) % 4;
          _secondsLeft = 4;
          if (_phase == 0) {
            _completedCycles++;
          }
          HapticFeedback.lightImpact();
        }
      });
    });
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _startPacer();
      } else {
        _timer?.cancel();
      }
    });
  }

  String _getPhaseText(int phase) {
    final s = widget.strings;
    switch (phase) {
      case 0:
        return s.isArabic ? 'شهيق عميق من الأنف...' : (s.isFrench ? 'Inspiration lente...' : 'Slow Inhalation...');
      case 1:
        return s.isArabic ? 'احبس النفس بلطف...' : (s.isFrench ? 'Rétention paisible...' : 'Gentle Hold...');
      case 2:
        return s.isArabic ? 'زفير ممتد من الفم...' : (s.isFrench ? 'Expiration prolongée...' : 'Extended Exhalation...');
      case 3:
        return s.isArabic ? 'سكون واستقرار...' : (s.isFrench ? 'Repos au calme...' : 'Resting Stillness...');
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        border: Border(
          top: BorderSide(color: tokens.border, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 38,
            height: 4.5,
            decoration: BoxDecoration(
              color: tokens.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.strings.relieveStress,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.strings.breathingPractice,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: widget.strings.closeBtn,
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded, color: tokens.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Visualizer
          VagalBreathingVisualizer(
            phase: _phase,
            secondsLeft: _secondsLeft,
            phaseText: _getPhaseText(_phase),
            isDark: isDark,
          ),

          const SizedBox(height: 16),

          Text(
            widget.strings.isArabic
                ? 'الدورات المكتملة: $_completedCycles'
                : 'Completed Cycles: $_completedCycles',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // Controls
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _togglePause,
                  icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  label: Text(_isRunning ? 'PAUSE' : 'RESUME'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? tokens.accent : const Color(0xFF34443B),
                    foregroundColor: isDark ? const Color(0xFF151B19) : Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
