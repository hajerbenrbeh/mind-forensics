import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../controllers/profile_controller.dart';
import '../../domain/condition_type.dart';
import '../../domain/diagnostic_status.dart';
import '../../domain/psychological_profile_model.dart';
import 'condition_status_bottom_sheet.dart';

class EditExperiencesSheet extends ConsumerWidget {
  const EditExperiencesSheet({super.key, required this.profile});

  final PsychologicalProfileModel profile;

  static Future<void> show(BuildContext context, PsychologicalProfileModel profile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditExperiencesSheet(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveProfile = ref.watch(profileControllerProvider).value ?? profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);

    final bg = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final border = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    return Container(
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.sectionExperiences,
                        style: LabTheme.serifStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strings.conditionsSectionSubtitle,
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    strings.isArabic ? 'تم' : 'Done',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: border, height: 1),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: ExperienceCategory.values.map((cat) {
                  final catTitle = strings.isArabic ? cat.arabicTitle : cat.englishTitle;
                  final conditionsInCat = cat.conditions;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catTitle.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: LabColors.champagneGold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: conditionsInCat.map((cond) {
                            final entry = liveProfile.getEntry(cond);
                            final isSelected = entry != null;

                            return InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ConditionStatusBottomSheet.show(
                                  context,
                                  condition: cond,
                                  initialStatus: entry?.status ??
                                      DiagnosticStatus.selfIdentifiedExploring,
                                  initialNote: entry?.note ?? '',
                                  isSelected: isSelected,
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? LabColors.darkWine : const Color(0xFFFBE8E9))
                                      : (isDark ? const Color(0xFF101010) : const Color(0xFFFAFAFA)),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected ? LabColors.champagneGold : border,
                                    width: isSelected ? 1 : 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      const Icon(Icons.check_rounded, size: 12, color: LabColors.champagneGold),
                                      const SizedBox(width: 5),
                                    ],
                                    Text(
                                      strings.conditionName(cond),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected
                                            ? (isDark ? LabColors.warmIvory : LabColors.deepBurgundy)
                                            : textSecondary,
                                      ),
                                    ),
                                    if (isSelected && entry.status != DiagnosticStatus.preferNotToSay) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF181818) : Colors.white,
                                          borderRadius: BorderRadius.circular(3),
                                          border: Border.all(color: border, width: 0.6),
                                        ),
                                        child: Text(
                                          strings.statusName(entry.status),
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w600,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

