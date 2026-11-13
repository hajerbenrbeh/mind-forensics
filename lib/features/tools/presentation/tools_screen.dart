import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/safety_model.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../investigation/domain/label_type.dart';
import '../../investigation/presentation/widgets/vagal_breathing_visualizer.dart';

/// The Forensic Tools Lab screen: Vercel Luxury Dark & Minimalist Precision.
///
/// Features:
/// - Label Master: Trilingual interactive practice drills for cognitive distortions
/// - Box Breathing Pacer: 4-4-4-4 rhythm with minimalist geometric breathing ring
/// - Official Tunisian Crisis Helpline Hub
class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen> {
  // Practice drill state
  int _drillIndex = 0;
  LabelType? _selectedAnswer;
  bool _answered = false;

  List<Map<String, dynamic>> _getDrills(String lang) {
    if (lang == 'ar') {
      return [
        {
          'statement': '“ما جاوبنيش على الميساج متاعي عندو 4 سوايع.”',
          'correct': LabelType.fact,
          'explanation': 'هذي واقعة ملموسة ومثبتة في الوقت، أي إنسان ينجم يشوفها ويثبت فيها.',
        },
        {
          'statement': '“هو يتهرب مني خاطري قلت كلمة غالطة.”',
          'correct': LabelType.assumption,
          'explanation': 'هذا تخمين لنوايا الطرف الآخر من غير أي دليل حقيقي أو تأكيد مباشر.',
        },
        {
          'statement': '“أنا إنسان فاشل وعمري ما نصلح في علاقاتي.”',
          'correct': LabelType.interpretation,
          'explanation': 'هذا حكم قاسي وتأويل مدمر ألقيته على روحك انطلاقاً من مجرد موقف.',
        },
        {
          'statement': '“المسؤول في الخدمة طلب تعديلات على التقرير.”',
          'correct': LabelType.fact,
          'explanation': 'حدث واقعي طبيعي في سياق العمل، وطلب الملاحظات ماهوش دليل على فشلك.',
        },
        {
          'statement': '“البريزونتاسيون متاعي كانت كارثة ومصيبة كاملة.”',
          'correct': LabelType.interpretation,
          'explanation': 'تضخيم كارثي: إلصاق صفة سلبية قاسية على عرض عادي يحتاج تحسين.',
        },
      ];
    } else if (lang == 'fr') {
      return [
        {
          'statement': '« Il n’a pas répondu à mon message depuis 4 heures. »',
          'correct': LabelType.fact,
          'explanation': 'C’est un fait objectif et vérifiable que n’importe quel observateur peut constater.',
        },
        {
          'statement': '« Il m’évite parce que j’ai dit quelque chose de stupide. »',
          'correct': LabelType.assumption,
          'explanation': 'Vous présumez de ses intentions secrètes sans aucune preuve factuelle.',
        },
        {
          'statement': '« Je suis nul et je gâche toujours mes relations. »',
          'correct': LabelType.interpretation,
          'explanation': 'C’est un récit personnel sévère et dévalorisant plaqué sur une situation.',
        },
        {
          'statement': '« Le responsable a demandé des modifications sur la présentation. »',
          'correct': LabelType.fact,
          'explanation': 'Un événement professionnel courant. Demander des retouches n’est pas un signe d’échec.',
        },
        {
          'statement': '« Ma présentation a été une catastrophe absolue. »',
          'correct': LabelType.interpretation,
          'explanation': 'Dramatisation : étiquette émotionnelle extrême attribuée à une intervention ordinaire.',
        },
      ];
    }

    return [
      {
        'statement': '“He didn’t reply to my message for 4 hours.”',
        'correct': LabelType.fact,
        'explanation': 'This is an objective, verifiable event that can be clocked and observed by anyone.',
      },
      {
        'statement': '“He is avoiding me because I said something stupid.”',
        'correct': LabelType.assumption,
        'explanation': 'This assumes his private motivations without factual evidence or confirmation.',
      },
      {
        'statement': '“I am unlovable and always ruin my relationships.”',
        'correct': LabelType.interpretation,
        'explanation': 'This is a harsh personal narrative assigned onto a situational outcome.',
      },
      {
        'statement': '“The manager requested changes on the slide deck.”',
        'correct': LabelType.fact,
        'explanation': 'A clear factual occurrence. Requesting edits is standard workflow, not proof of failure.',
      },
      {
        'statement': '“My presentation was a complete catastrophe.”',
        'correct': LabelType.interpretation,
        'explanation': 'Catastrophizing: projecting an extreme negative emotional label on a normal presentation.',
      },
    ];
  }

  // Breathing pacer state
  bool _isBreathingActive = false;
  int _breathingPhase = 0; // 0: Inhale, 1: Hold, 2: Exhale, 3: Rest
  int _breathingSecondsLeft = 4;
  Timer? _breathingTimer;

  void _nextDrill(int totalDrills) {
    HapticFeedback.lightImpact();
    setState(() {
      _drillIndex = (_drillIndex + 1) % totalDrills;
      _selectedAnswer = null;
      _answered = false;
    });
  }

  void _toggleBreathing() {
    HapticFeedback.mediumImpact();
    if (_isBreathingActive) {
      _stopBreathing();
    } else {
      _startBreathing();
    }
  }

  void _startBreathing() {
    setState(() {
      _isBreathingActive = true;
      _breathingPhase = 0;
      _breathingSecondsLeft = 4;
    });
    _breathingTimer?.cancel();
    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_breathingSecondsLeft > 1) {
          _breathingSecondsLeft--;
        } else {
          _breathingPhase = (_breathingPhase + 1) % 4;
          _breathingSecondsLeft = 4;
          HapticFeedback.lightImpact();
        }
      });
    });
  }

  void _stopBreathing() {
    _breathingTimer?.cancel();
    setState(() {
      _isBreathingActive = false;
      _breathingPhase = 0;
      _breathingSecondsLeft = 4;
    });
  }

  @override
  void dispose() {
    _breathingTimer?.cancel();
    super.dispose();
  }

  Future<void> _callHotline(String phone) async {
    HapticFeedback.mediumImpact();
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _getBreathingPhaseText(int phase, AppStrings strings) {
    switch (phase) {
      case 0:
        return strings.breatheIn;
      case 1:
        return strings.breatheHold;
      case 2:
        return strings.breatheOut;
      case 3:
        return strings.breatheRest;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = ref.watch(localeControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final drills = _getDrills(locale.languageCode);
    final currentDrill = drills[_drillIndex % drills.length];

    final bg = isDark ? LabColors.nightBackground : LabColors.daylightBackground;
    final surfaceColor = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final borderColor = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          strings.toolsTitle.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1.2,
            color: textPrimary,
          ),
        ),
        actions: const [
          SupportButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toolkit (v1 Placeholder) Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: context.tokens.surfaceSecondary,
                  borderRadius: BorderRadius.circular(context.tokens.cardRadius),
                  border: Border.all(
                    color: context.tokens.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: LabColors.beigeBackground(isDark: isDark),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: LabColors.beigeBorder(isDark: isDark)),
                      ),
                      child: Icon(
                        Icons.handyman_outlined,
                        size: 16,
                        color: isDark ? LabColors.warmBeige : LabColors.warmBeigeDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                strings.toolkitPlaceholderV1.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: LabColors.cherryBackground(isDark: isDark),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: LabColors.cherryBorder(isDark: isDark)),
                                ),
                                child: const Text(
                                  'v1 SCOPE',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                    color: LabColors.cherryRedGlow,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            strings.toolkitV2Notice,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // TOOL 1: Label Master Drill
              _toolSectionHeader(strings.labelMasterTitle.toUpperCase(), strings.labelMasterDesc, textSecondary),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: LabColors.beigeBackground(isDark: isDark),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: LabColors.beigeBorder(isDark: isDark)),
                          ),
                          child: Text(
                            strings.drillCounter((_drillIndex % drills.length) + 1, drills.length),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isDark ? LabColors.warmBeigeGlow : LabColors.warmBeigeDark,
                            ),
                          ),
                        ),
                        if (_answered)
                          InkWell(
                            onTap: () => _nextDrill(drills.length),
                            child: Row(
                              children: [
                                Text(strings.nextDrill, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: textPrimary)),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, size: 14, color: textPrimary),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentDrill['statement'] as String,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.35, letterSpacing: -0.2, color: textPrimary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildChoicePill(LabelType.fact, currentDrill['correct'] as LabelType, isDark, textPrimary, textSecondary, strings),
                        const SizedBox(width: 8),
                        _buildChoicePill(LabelType.assumption, currentDrill['correct'] as LabelType, isDark, textPrimary, textSecondary, strings),
                        const SizedBox(width: 8),
                        _buildChoicePill(LabelType.interpretation, currentDrill['correct'] as LabelType, isDark, textPrimary, textSecondary, strings),
                      ],
                    ),
                    if (_answered) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (_selectedAnswer == currentDrill['correct'])
                              ? context.tokens.accentSoft
                              : context.tokens.safetyWarmthSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: (_selectedAnswer == currentDrill['correct'])
                                ? context.tokens.accent.withValues(alpha: 0.45)
                                : context.tokens.safetyWarmth.withValues(alpha: 0.45),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          currentDrill['explanation'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // TOOL 2: Interactive Box Breathing Pacer
              _toolSectionHeader(strings.breathingTitle.toUpperCase(), strings.breathingDesc, textSecondary),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  children: [
                    if (_isBreathingActive) ...[
                      VagalBreathingVisualizer(
                        phase: _breathingPhase,
                        secondsLeft: _breathingSecondsLeft,
                        phaseText: _getBreathingPhaseText(_breathingPhase, strings),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: LabColors.beigeBackground(isDark: isDark),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: LabColors.beigeBorder(isDark: isDark)),
                            ),
                            child: Icon(
                              Icons.air_rounded,
                              color: isDark ? LabColors.warmBeige : LabColors.warmBeigeDark,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.breathingTitle,
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  strings.pacerSub,
                                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: BouncingWidget(
                        onTap: _toggleBreathing,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _isBreathingActive
                                ? context.tokens.surfaceSecondary
                                : context.tokens.accent,
                            foregroundColor: _isBreathingActive
                                ? textPrimary
                                : (isDark ? context.tokens.background : Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: context.tokens.border),
                          ),
                          onPressed: _toggleBreathing,
                          icon: Icon(_isBreathingActive ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 18),
                          label: Text(
                            _isBreathingActive ? strings.stopPacer : strings.startPacer,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // TOOL 3: Official Crisis & Emergency Helpline Hub (Tunisia)
              _toolSectionHeader(strings.tunisianHotlinesTitle.toUpperCase(), strings.tunisianHotlinesDesc, textSecondary),
              const SizedBox(height: 10),
              ...CrisisResource.tunisianResources.where((r) => r.phone.isNotEmpty).map(
                    (res) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: isDark ? LabColors.safetySoftBgDark : LabColors.safetySoftBgLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.phone_in_talk_outlined,
                                color: isDark ? LabColors.safetyWarmthDark : LabColors.safetyWarmth, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  res.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  res.description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: isDark ? LabColors.safetyWarmthDark : LabColors.safetyWarmth,
                              foregroundColor: isDark ? LabColors.nightBackground : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () => _callHotline(res.phone),
                            child: Text(
                              res.phone == '80105050' ? '80 10 50 50' : res.phone,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolSectionHeader(String title, String desc, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildChoicePill(
    LabelType label,
    LabelType correctAnswer,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    AppStrings strings,
  ) {
    final tokens = context.tokens;
    final isSelected = _selectedAnswer == label;
    final isCorrect = label == correctAnswer;

    Color bg = tokens.surfaceSecondary;
    Color border = tokens.border;
    Color fg = textSecondary;

    if (_answered) {
      if (isCorrect) {
        bg = tokens.accentSoft;
        border = tokens.accent;
        fg = tokens.accent;
      } else if (isSelected) {
        bg = tokens.safetyWarmthSoft;
        border = tokens.safetyWarmth;
        fg = tokens.safetyWarmth;
      }
    } else if (isSelected) {
      bg = tokens.accentSoft;
      border = tokens.accent;
      fg = textPrimary;
    }

    return Expanded(
      child: BouncingWidget(
        onTap: _answered
            ? null
            : () {
                setState(() {
                  _selectedAnswer = label;
                  _answered = true;
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border, width: 1),
          ),
          child: Center(
            child: Text(
              '${label.letter} ${strings.localizedLabelName(label)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected || (_answered && isCorrect) ? FontWeight.w800 : FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
