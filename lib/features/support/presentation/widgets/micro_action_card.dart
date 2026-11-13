import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../journey/controllers/journey_controller.dart';

/// Micro-Action Behavioral Activation Card:
/// - Provides a 2-minute gentle micro-action to overcome inertia
/// - Options-first: user chooses 1 simple physical action
/// - Optional countdown timer with zero penalty for pause or early stop
/// - No compliance percentages or productivity tracking
class MicroActionCard extends ConsumerStatefulWidget {
  const MicroActionCard({super.key});

  @override
  ConsumerState<MicroActionCard> createState() => _MicroActionCardState();
}

class _MicroActionCardState extends ConsumerState<MicroActionCard> {
  int _selectedActionIndex = 0;
  bool _isTimerRunning = false;
  int _secondsLeft = 120; // 2 minutes
  Timer? _timer;
  bool _isFinished = false;

  final List<({String titleEn, String titleAr, String titleFr, IconData icon})> _actions = [
    (
      titleEn: 'Drink a glass of cold water mindfully',
      titleAr: 'اشرب كاس ماء بارد بوعي وهدوء',
      titleFr: 'Boire un verre d’eau fraîche en pleine conscience',
      icon: Icons.local_drink_outlined,
    ),
    (
      titleEn: 'Open a window and take 3 deep breaths of fresh air',
      titleAr: 'حل الشباك وتنفس هواء نقي 3 مرات',
      titleFr: 'Ouvrir une fenêtre et respirer l’air frais',
      icon: Icons.air_rounded,
    ),
    (
      titleEn: 'Clear one small surface near you (desk or table corner)',
      titleAr: 'نظف مساحة صغيرة بحذاك (قنت من البيرو أو الطاولة)',
      titleFr: 'Dégager un petit coin de table ou de bureau',
      icon: Icons.cleaning_services_outlined,
    ),
    (
      titleEn: 'Stand up and gently stretch your shoulders and neck',
      titleAr: 'قف وحرك كتافك ورقبتك برفق لتسريح التشنج',
      titleFr: 'Se lever et étirer doucement ses épaules et sa nuque',
      icon: Icons.accessibility_new_rounded,
    ),
    (
      titleEn: 'Step outside or look at the sky for 60 seconds',
      titleAr: 'اخرج أو اخزر للسماء لمدة دقيقة واحدة',
      titleFr: 'Regarder le ciel ou sortir un instant pendant une minute',
      icon: Icons.wb_sunny_outlined,
    ),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    HapticFeedback.lightImpact();
    if (_isTimerRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
      _isFinished = false;
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
          _timer?.cancel();
          _isTimerRunning = false;
          _isFinished = true;
          HapticFeedback.mediumImpact();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _completeNow() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _isFinished = true;
    });
  }

  String _formatTime(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final isAr = strings.isArabic;
    final isFr = strings.isFrench;

    final surfaceColor =
        isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final borderColor =
        isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary =
        isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary =
        isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    final action = _actions[_selectedActionIndex];
    final actionTitle = isAr
        ? action.titleAr
        : (isFr ? action.titleFr : action.titleEn);

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
                strings.needActionTitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: LabColors.sageGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isAr
                      ? '2 دقائق فقط'
                      : (isFr ? '2 MINUTES SEULEMENT' : '2 MINUTES ONLY'),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: LabColors.sageGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isAr
                ? 'اختر خطوة ميكرو-بسيطة تدوم دقيقتين لكسر الجمود:'
                : (isFr
                    ? 'Choisissez un petit geste doux de deux minutes pour relancer l’élan :'
                    : 'Select one gentle micro-step to break initial inertia:'),
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Action choices chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(_actions.length, (index) {
              final isSelected = index == _selectedActionIndex;
              final act = _actions[index];
              final label = isAr ? act.titleAr : (isFr ? act.titleFr : act.titleEn);
              return ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? (isDark ? Colors.black : Colors.white) : textPrimary,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedActionIndex = index;
                      _secondsLeft = 120;
                      _isFinished = false;
                      _timer?.cancel();
                      _isTimerRunning = false;
                    });
                  }
                },
                selectedColor: context.tokens.accent,
                backgroundColor: context.tokens.surfaceSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.tokens.chipRadius),
                  side: BorderSide(
                    color: isSelected ? context.tokens.accent : borderColor,
                    width: 1,
                  ),
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Selected active action display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(action.icon, size: 22, color: LabColors.sageGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    actionTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                Text(
                  _formatTime(_secondsLeft),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: LabColors.sageGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _isFinished ? null : _toggleTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTimerRunning ? surfaceColor : textPrimary,
                      foregroundColor: _isTimerRunning ? textPrimary : (isDark ? Colors.black : Colors.white),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: _isTimerRunning ? BorderSide(color: borderColor) : BorderSide.none,
                      ),
                    ),
                    child: Text(
                      _isTimerRunning
                          ? (isAr
                              ? 'إيقاف مؤقت'
                              : (isFr ? 'Mettre en pause' : 'Pause Timer'))
                          : (isAr
                              ? 'بدء الدقيقتين'
                              : (isFr
                                  ? 'Démarrer 2 minutes'
                                  : 'Start 2 Minutes')),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: _completeNow,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LabColors.sageGreen,
                    side: const BorderSide(color: LabColors.sageGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isAr ? 'أكملت الخطوة' : (isFr ? 'Terminé' : 'Done'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          if (_isFinished) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isAr
                        ? 'أحسنت. خطوة صغيرة واحدة تكسر الجمود بدون أي ضغط.'
                        : (isFr
                            ? 'Bravo. Un petit pas suffit à relancer l’élan sans pression.'
                            : 'Well done. One tiny step breaks inertia with zero pressure.'),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: LabColors.sageGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(journeyControllerProvider.notifier).addCustomDiscovery(
                          title: actionTitle,
                          notes: 'Completed 2-minute micro-action: $actionTitle',
                          category: 'Behavioral Strategy',
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAr
                                ? 'تم حفظ التجربة في اكتشافاتك'
                                : (isFr
                                    ? 'Stratégie enregistrée dans vos découvertes'
                                    : 'Strategy saved to Discoveries'),
                            style: const TextStyle(fontSize: 12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.bookmark_add_outlined, size: 14),
                  label: Text(
                    isAr
                        ? 'حفظ كاكتشاف'
                        : (isFr ? 'Enregistrer' : 'Save to Discoveries'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: LabColors.sageGreen,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

