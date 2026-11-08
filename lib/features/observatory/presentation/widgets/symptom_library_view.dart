import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../profile/controllers/profile_controller.dart';
import '../../controllers/observatory_controllers.dart';
import '../../domain/symptom_entry.dart';
import 'custom_symptom_sheet.dart';
import 'symptom_assessment_sheet.dart';

class SymptomLibraryView extends ConsumerWidget {
  const SymptomLibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final isAr = strings.isArabic;

    final surfaceColor = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final borderColor = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    final filteredSymptoms = ref.watch(filteredSymptomsProvider);
    final selectedIds = ref.watch(selectedSymptomIdsProvider);
    final activeDomain = ref.watch(selectedDomainFilterProvider);
    final profile = ref.watch(profileControllerProvider).value;

    return Column(
      children: [
        // 1. Search Bar & Add Custom Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (q) => ref.read(symptomSearchQueryProvider.notifier).setQuery(q),
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isAr
                        ? 'ابحث في كافة الأعراض والتجارب...'
                        : 'Search across all symptoms...',
                    hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: textSecondary),
                    filled: true,
                    fillColor: surfaceColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      borderSide: const BorderSide(color: LabColors.sageGreen, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: isAr ? 'إضافة تجربة خاصة' : 'Add custom symptom',
                icon: const Icon(Icons.add_rounded, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => CustomSymptomSheet.show(context),
              ),
            ],
          ),
        ),

        // 2. Domain / Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ChoiceChip(
                label: Text(isAr ? 'الكل' : 'All'),
                selected: activeDomain == null,
                onSelected: (_) =>
                    ref.read(selectedDomainFilterProvider.notifier).select(null),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: activeDomain == null ? FontWeight.w700 : FontWeight.w500,
                  color: activeDomain == null ? textPrimary : textSecondary,
                ),
                backgroundColor: surfaceColor,
                selectedColor: LabColors.sageGreen.withValues(alpha: 0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(
                    color: activeDomain == null ? LabColors.sageGreen : borderColor,
                  ),
                ),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              ...SymptomDomain.values.map((d) {
                final isSelected = activeDomain == d;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(d.localized(strings)),
                    selected: isSelected,
                    onSelected: (_) =>
                        ref.read(selectedDomainFilterProvider.notifier).select(
                            isSelected ? null : d),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? textPrimary : textSecondary,
                    ),
                    backgroundColor: surfaceColor,
                    selectedColor: LabColors.sageGreen.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(
                        color: isSelected ? LabColors.sageGreen : borderColor,
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
        const SizedBox(height: 10),

        // 3. Symptoms List
        Expanded(
          child: filteredSymptoms.isEmpty
              ? Center(
                  child: Text(
                    isAr ? 'لم يتم العثور على أعراض مطابقة' : 'No matching symptoms found',
                    style: TextStyle(color: textSecondary, fontSize: 12.5),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filteredSymptoms.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final symptom = filteredSymptoms[index];
                    final isSelected = selectedIds.contains(symptom.id);

                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(selectedSymptomIdsProvider.notifier).toggle(symptom.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? LabColors.sageGreen.withValues(alpha: 0.12)
                              : surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? LabColors.sageGreen : borderColor,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: isSelected,
                              activeColor: LabColors.sageGreen,
                              checkColor: Colors.black,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (_) {
                                ref.read(selectedSymptomIdsProvider.notifier).toggle(symptom.id);
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          symptom.title(strings),
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (symptom.isCustom)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: LabColors.warmBeige.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isAr ? 'خاص' : 'CUSTOM',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ),
                                      if (profile?.selectedSymptoms.contains(symptom.id) == true) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: LabColors.sageGreenGlow.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isAr ? 'من ملفك' : 'INTAKE',
                                            style: const TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.3,
                                              color: LabColors.sageGreenGlow,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    symptom.description(strings),
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
                    );
                  },
                ),
        ),

        // 4. Floating Multi-Symptom Action Bar
        if (selectedIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: borderColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr
                              ? '${selectedIds.length} تجارب محددة'
                              : '${selectedIds.length} symptoms selected',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              ref.read(selectedSymptomIdsProvider.notifier).clear(),
                          child: Text(
                            isAr ? 'إلغاء التحديد' : 'Clear selection',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      final all = ref.read(filteredSymptomsProvider);
                      final selected =
                          all.where((s) => selectedIds.contains(s.id)).toList();
                      SymptomAssessmentSheet.show(context, selectedSymptoms: selected);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: textPrimary,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: Text(
                      isAr ? 'تقييم الأعراض الآن' : 'Assess Symptoms',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
