import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../../core/widgets/bouncing_widget.dart';
import '../../controllers/journal_memory_controller.dart';
import '../../domain/journal_memory_model.dart';

/// Bottom sheet displaying compressed journal memories with full user transparency and control.
///
/// Section 8 & Step 3.2:
/// - Shows what information has been retained from self-observation entries.
/// - Shows source observation count and time window.
/// - Allows the user to confirm, dismiss (reject), or delete any memory item.
/// - Strictly 0 emojis in UI (Vercel Luxury Dark aesthetic).
class JournalMemorySheet extends ConsumerWidget {
  const JournalMemorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const JournalMemorySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);

    final bg = isDark ? LabColors.nightBackground : LabColors.daylightBackground;
    final surface = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final border = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;
    final accent = isDark ? LabColors.nightAccent : LabColors.daylightAccent;

    final memoriesAsync = ref.watch(journalMemoryControllerProvider);
    final memories = memoriesAsync.value ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.isArabic ? 'خزينة الذاكرة' : 'MEMORY VAULT',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.isArabic
                          ? 'سياق ملخص ومحفوظ محلياً فقط على جهازك'
                          : 'Compact context synthesized locally on-device',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: textSecondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Informational Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 16, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.isArabic
                        ? 'تساعد هذه الملخصات المساعد الذكي على فهم مسارك دون قراءة نصوصك الحرة كاملة. يمكنك تأكيد أو رفض أي ملخص.'
                        : 'These summaries help the AI Companion understand your trajectory without transmitting raw journal texts. You have full sovereignty to affirm or dismiss any item.',
                    style: TextStyle(fontSize: 11, height: 1.4, color: textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // Memory Items List
          Expanded(
            child: memories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_outlined, size: 36, color: textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            strings.isArabic
                                ? 'لا توجد ذاكرة مضغوطة بعد'
                                : 'No compressed memories yet',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.isArabic
                                ? 'سيتم استخلاص الأنماط المتكررة بعد تسجيل أكثر من أثر يومي.'
                                : 'Recurring themes and context will be synthesized as you log daily check-ins.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: memories.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = memories[index];
                      return _buildMemoryCard(
                        context: context,
                        ref: ref,
                        item: item,
                        surface: surface,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        accent: accent,
                        isDark: isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard({
    required BuildContext context,
    required WidgetRef ref,
    required JournalMemoryModel item,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color accent,
    required bool isDark,
  }) {
    final statusColor = item.isConfirmed
        ? (isDark ? LabColors.sageGreen : LabColors.daylightAccent)
        : (item.isRejected ? (isDark ? LabColors.cherryRedGlow : LabColors.cherryRed) : textSecondary);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isRejected ? border.withValues(alpha: 0.4) : border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.category.displayName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: textPrimary,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.confirmationStatus.displayName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.summary,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: item.isRejected ? textSecondary : textPrimary,
              decoration: item.isRejected ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 12, color: textSecondary),
              const SizedBox(width: 4),
              Text(
                '${item.observationCount} observations • ${item.sourceEntryIds.length} source entries',
                style: TextStyle(fontSize: 10, color: textSecondary),
              ),
              const Spacer(),
              // Actions
              if (!item.isConfirmed)
                BouncingWidget(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(journalMemoryControllerProvider.notifier).confirmMemory(item.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'Confirm',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent),
                    ),
                  ),
                ),
              if (!item.isRejected)
                BouncingWidget(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(journalMemoryControllerProvider.notifier).rejectMemory(item.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'Dismiss',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: textSecondary,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(journalMemoryControllerProvider.notifier).deleteMemory(item.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
