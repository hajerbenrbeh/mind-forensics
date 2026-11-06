import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../../core/widgets/bouncing_widget.dart';
import '../../controllers/profile_controller.dart';
import '../../domain/condition_type.dart';
import '../../domain/diagnostic_status.dart';

/// Modal bottom sheet allowing users to set or edit the evaluation status
/// and personal notes for a selected condition or experience.
class ConditionStatusBottomSheet extends ConsumerStatefulWidget {
  const ConditionStatusBottomSheet({
    super.key,
    required this.condition,
    this.initialStatus = DiagnosticStatus.selfIdentifiedExploring,
    this.initialNote = '',
    this.isSelected = false,
  });

  final ConditionType condition;
  final DiagnosticStatus initialStatus;
  final String initialNote;
  final bool isSelected;

  static Future<void> show(
    BuildContext context, {
    required ConditionType condition,
    DiagnosticStatus initialStatus = DiagnosticStatus.selfIdentifiedExploring,
    String initialNote = '',
    bool isSelected = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConditionStatusBottomSheet(
        condition: condition,
        initialStatus: initialStatus,
        initialNote: initialNote,
        isSelected: isSelected,
      ),
    );
  }

  @override
  ConsumerState<ConditionStatusBottomSheet> createState() =>
      _ConditionStatusBottomSheetState();
}

class _ConditionStatusBottomSheetState
    extends ConsumerState<ConditionStatusBottomSheet> {
  late DiagnosticStatus _selectedStatus;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);

    final bg = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final border = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary =
        isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary =
        isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          border: Border.all(color: border, width: 1),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
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
              const SizedBox(height: 16),

              // Condition title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      strings.conditionName(widget.condition),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (widget.isSelected)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: LabColors.cherryRedGlow,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(profileControllerProvider.notifier)
                            .toggleCondition(widget.condition);
                        Navigator.pop(context);
                      },
                      child: Text(
                        strings.isArabic ? 'إزالة من الملف' : (strings.isFrench ? 'Retirer' : 'Remove'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                strings.conditionsSectionSubtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: textSecondary,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 18),

              // Status Selector
              Text(
                strings.statusTitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              Column(
                children: DiagnosticStatus.values.map((status) {
                  final isCurrent = _selectedStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedStatus = status);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? (isDark
                                  ? const Color(0xFF1C1C1C)
                                  : const Color(0xFFF0F0F2))
                              : (isDark
                                  ? const Color(0xFF0F0F0F)
                                  : const Color(0xFFFAFAFA)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? (isDark ? Colors.white : Colors.black)
                                : border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              strings.statusName(status),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isCurrent
                                    ? textPrimary
                                    : textSecondary,
                              ),
                            ),
                            if (isCurrent)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // Optional note input
              Text(
                strings.conditionNoteLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                style: TextStyle(fontSize: 12.5, color: textPrimary),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: strings.isArabic
                      ? 'ملاحظة خاصة إن وجدت (مثل: تتكرر في المواقف الاجتماعية)...'
                      : (strings.isFrench
                          ? 'Note personnelle (ex: principalement en public)...'
                          : 'Personal nuance (e.g., primarily in social contexts)...'),
                  hintStyle: TextStyle(
                    fontSize: 11.5,
                    color: textSecondary.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF121212)
                      : const Color(0xFFF4F4F5),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: textPrimary, width: 1),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Save button
              BouncingWidget(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  final notifier = ref.read(profileControllerProvider.notifier);
                  if (widget.isSelected) {
                    notifier.updateConditionStatus(
                      widget.condition,
                      _selectedStatus,
                      note: _noteController.text.trim(),
                    );
                  } else {
                    notifier.toggleCondition(
                      widget.condition,
                      status: _selectedStatus,
                    );
                    if (_noteController.text.trim().isNotEmpty) {
                      notifier.updateConditionStatus(
                        widget.condition,
                        _selectedStatus,
                        note: _noteController.text.trim(),
                      );
                    }
                  }
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.isSelected
                        ? (strings.isArabic ? 'تحديث الحالة' : (strings.isFrench ? 'Mettre à jour' : 'Update Status'))
                        : (strings.isArabic ? 'إضافة إلى الملف' : (strings.isFrench ? 'Ajouter au profil' : 'Add to Profile')),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: isDark ? Colors.black : Colors.white,
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

