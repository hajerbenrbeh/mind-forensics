import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/bouncing_widget.dart';
import '../../controllers/profile_controller.dart';
import '../../domain/profile_goals_catalog.dart';
import '../../domain/psychological_profile_model.dart';

class EditGoalsSheet extends ConsumerStatefulWidget {
  const EditGoalsSheet({super.key, required this.profile});

  final PsychologicalProfileModel profile;

  static Future<void> show(BuildContext context, PsychologicalProfileModel profile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditGoalsSheet(profile: profile),
    );
  }

  @override
  ConsumerState<EditGoalsSheet> createState() => _EditGoalsSheetState();
}

class _EditGoalsSheetState extends ConsumerState<EditGoalsSheet> {
  late Set<String> _selectedGoals;
  late TextEditingController _customGoalController;

  @override
  void initState() {
    super.initState();
    _selectedGoals = Set.from(widget.profile.selectedGoals);
    _customGoalController = TextEditingController(text: widget.profile.customGoal);
  }

  @override
  void dispose() {
    _customGoalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    await ref.read(profileControllerProvider.notifier).updateGoals(
      selectedGoals: _selectedGoals.toList(),
      customGoal: _customGoalController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);

    final bg = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final border = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                strings.sectionGoals,
                style: LabTheme.serifStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.isArabic
                    ? 'ما الذي ترغب في استيعابه أو تطويره من خلال Mind Forensics؟'
                    : 'What would you like to understand or improve through Mind Forensics?',
                style: TextStyle(fontSize: 11.5, color: textSecondary),
              ),

              const SizedBox(height: 12),
              Divider(color: border, height: 1),
              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ...ProfileGoalsCatalog.standardGoals.map((goal) {
                      final label = goal.localized(strings);
                      final isSelected = _selectedGoals.contains(label) ||
                          _selectedGoals.contains(goal.english) ||
                          _selectedGoals.contains(goal.arabic);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (isSelected) {
                                _selectedGoals.remove(label);
                                _selectedGoals.remove(goal.english);
                                _selectedGoals.remove(goal.arabic);
                              } else {
                                _selectedGoals.add(label);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.tokens.accentSoft
                                  : context.tokens.surfaceSecondary,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? context.tokens.accent : border,
                                width: isSelected ? 1.2 : 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  size: 16,
                                  color: isSelected ? context.tokens.accent : textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected
                                          ? context.tokens.accent
                                          : textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 14),

                    // Custom Goal Input
                    Text(
                      (strings.isArabic
                              ? 'هدف شخصي مخصص'
                              : (strings.isFrench
                                  ? 'OBJECTIF PERSONNEL PERSONNALISÉ'
                                  : 'CUSTOM PERSONAL GOAL'))
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _customGoalController,
                      style: TextStyle(fontSize: 12.5, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: strings.isArabic
                            ? 'أضف هدفاً إضافياً خاصاً بك...'
                            : (strings.isFrench
                                ? 'Saisissez tout autre objectif important pour vous...'
                                : 'Enter any other goal meaningful to you...'),
                        hintStyle: TextStyle(fontSize: 11.5, color: textSecondary.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: context.tokens.surfaceSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.tokens.accent)),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Save Button
              BouncingWidget(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: context.tokens.accent,
                    borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (strings.isArabic
                            ? 'حفظ الأهداف'
                            : (strings.isFrench
                                ? 'ENREGISTRER LES OBJECTIFS'
                                : 'SAVE GOALS'))
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark ? context.tokens.background : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

