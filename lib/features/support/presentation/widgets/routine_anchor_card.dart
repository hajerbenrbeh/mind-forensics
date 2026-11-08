import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../journey/controllers/journey_controller.dart';

/// Low-pressure routine anchor card:
/// Helps the user establish one gentle, non-punitive anchor point in their day.
/// Adheres to Directive 11: Options-first, zero streak pressure, zero guilt.
class RoutineAnchorCard extends ConsumerStatefulWidget {
  const RoutineAnchorCard({super.key});

  @override
  ConsumerState<RoutineAnchorCard> createState() => _RoutineAnchorCardState();
}

class _RoutineAnchorCardState extends ConsumerState<RoutineAnchorCard> {
  int _selectedAnchorIndex = 0;
  bool _isAdopted = false;

  final List<({
    String titleEn,
    String titleFr,
    String titleAr,
    String descEn,
    String descFr,
    String descAr,
    IconData icon,
  })> _anchors = const [
    (
      titleEn: 'Daylight & Hydration',
      titleFr: 'Lumière & Hydratation',
      titleAr: 'ضوء النهار وشرب الماء',
      descEn: 'Drink a glass of water near a window within 30 minutes of waking.',
      descFr: 'Boire un grand verre d’eau près d’une fenêtre dans les 30 min du réveil.',
      descAr: 'شرب كأس ماء والتعرض لضوء النافذة في أول نصف ساعة بعد الاستيقاظ.',
      icon: Icons.wb_sunny_outlined,
    ),
    (
      titleEn: 'Somatic Posture Reset',
      titleFr: 'Pause Posture & Respiration',
      titleAr: 'إعادة ضبط وضعية الجسد',
      descEn: 'Release jaw tension, roll shoulders back, and take 3 slow grounding breaths.',
      descFr: 'Détendre la mâchoire, rouler les épaules et prendre 3 lentes respirations.',
      descAr: 'إرخاء الفك، تحريك الكتفين للخلف، وأخذ 3 أنفاس عميقة لتخفيف الشد.',
      icon: Icons.accessibility_new_rounded,
    ),
    (
      titleEn: 'Evening Digital Buffer',
      titleFr: 'Sas Numérique du Soir',
      titleAr: 'حاجز رقمي قبل النوم',
      descEn: 'Place your phone screen-down across the room 15 minutes before bed.',
      descFr: 'Poser son téléphone écran vers le bas loin du lit 15 min avant de dormir.',
      descAr: 'وضع الهاتف مقلوباً بعيداً عن السرير بـ 15 دقيقة قبل النوم لتهدئة الذهن.',
      icon: Icons.bedtime_outlined,
    ),
    (
      titleEn: 'Midday Quiet Moment',
      titleFr: 'Instant de Calme à Midi',
      titleAr: 'لحظة سكون في منتصف اليوم',
      descEn: 'Pause for 60 seconds with no notifications before eating lunch.',
      descFr: 'Une minute de silence sans écran ni notification avant le déjeuner.',
      descAr: 'دقيقة صمت واحدة دون شاشات أو إشعارات قبل بدء وجبة الغداء.',
      icon: Icons.pause_circle_outline_rounded,
    ),
  ];

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

    final current = _anchors[_selectedAnchorIndex];
    final title = isAr
        ? current.titleAr
        : (isFr ? current.titleFr : current.titleEn);
    final desc = isAr
        ? current.descAr
        : (isFr ? current.descFr : current.descEn);

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
                strings.needRoutineTitle.toUpperCase(),
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
                  isAr ? 'نقطة توازن واحدة' : 'ONE GENTLE ANCHOR',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: LabColors.sageGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isAr
                ? 'لا داعي لإصلاح روتينك بالكامل. اختر نقطة ارتكاز صغيرة تثبتك اليوم بدون أي التزام أو ضغط.'
                : 'No need to overhaul your life. Choose one small physical anchor to steady your day without streak pressure.',
            style: TextStyle(fontSize: 12, color: textSecondary, height: 1.35),
          ),
          const SizedBox(height: 16),

          // Anchor choice pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_anchors.length, (idx) {
              final a = _anchors[idx];
              final isSelected = idx == _selectedAnchorIndex;
              final pillTitle = isAr ? a.titleAr : (isFr ? a.titleFr : a.titleEn);

              return ChoiceChip(
                label: Text(pillTitle),
                selected: isSelected,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedAnchorIndex = idx;
                    _isAdopted = false;
                  });
                },
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? textPrimary : textSecondary,
                ),
                backgroundColor: isDark
                    ? LabColors.nightSurfaceElevated
                    : LabColors.daylightSurfaceSubtle,
                selectedColor: LabColors.sageGreen.withValues(alpha: 0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(
                    color: isSelected ? LabColors.sageGreen : borderColor,
                  ),
                ),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              );
            }),
          ),
          const SizedBox(height: 16),

          // Featured Anchor Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isAdopted ? LabColors.sageGreen : borderColor,
                width: _isAdopted ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: LabColors.sageGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(current.icon, size: 22, color: LabColors.sageGreen),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Action button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() => _isAdopted = true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _isAdopted ? LabColors.sageGreen : textPrimary,
                foregroundColor: _isAdopted
                    ? Colors.black
                    : (isDark ? Colors.black : Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isAdopted
                    ? (isAr ? 'تم اعتماد نقطة التوازن لليوم' : 'Adopted for Today')
                    : (isAr ? 'اعتماد هذه النقطة لليوم' : 'Adopt as My Anchor Today'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ),
          if (_isAdopted) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await ref.read(journeyControllerProvider.notifier).addCustomDiscovery(
                        title: title,
                        notes: desc,
                        category: 'Daily Routine Anchor',
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isAr ? 'تم حفظ نقطة التوازن في اكتشافاتك' : 'Routine anchor saved to Discoveries',
                          style: const TextStyle(fontSize: 12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.bookmark_add_outlined, size: 14),
                label: Text(
                  isAr ? 'حفظ نقطة التوازن في اكتشافاتي' : 'Save Anchor to Discoveries',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: LabColors.sageGreen,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

