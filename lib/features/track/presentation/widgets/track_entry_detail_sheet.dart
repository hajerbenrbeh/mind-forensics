import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/safety/crisis_keywords.dart';
import '../../../../core/safety/safety_interceptor.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../mind_trace/controllers/mind_trace_controller.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';
import 'track_mood_picker.dart';
import 'track_mood_utils.dart';

/// Detail inspector sheet for any Track entry with Edit, Explore with AI Guide,
/// and confirmation-gated Delete actions.
class TrackEntryDetailSheet extends ConsumerWidget {
  const TrackEntryDetailSheet({
    super.key,
    required this.trace,
    required this.onEdit,
    required this.onExploreWithAi,
    this.onDeleted,
  });

  final MindTraceModel trace;
  final VoidCallback onEdit;
  final VoidCallback onExploreWithAi;
  final VoidCallback? onDeleted;

  static Future<void> show(
    BuildContext context, {
    required MindTraceModel trace,
    required VoidCallback onEdit,
    required VoidCallback onExploreWithAi,
    VoidCallback? onDeleted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackEntryDetailSheet(
        trace: trace,
        onEdit: onEdit,
        onExploreWithAi: onExploreWithAi,
        onDeleted: onDeleted,
      ),
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
    MindTokens tokens,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: tokens.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            side: BorderSide(color: tokens.border),
          ),
          title: Text(
            strings.deleteTraceConfirmTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
          content: Text(
            strings.deleteTraceConfirmBody,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: tokens.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(
                strings.cancelActionLabel,
                style: TextStyle(color: tokens.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(
                strings.deleteEntryBtn,
                style: TextStyle(
                  color: tokens.safetyWarmth,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;
    HapticFeedback.mediumImpact();
    await ref.read(mindTraceControllerProvider.notifier).deleteCheckIn(trace.id);
    if (context.mounted) {
      Navigator.of(context).pop();
      onDeleted?.call();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final moodStyle = trackMoodOptionFor(trace.overallMood);
    final moodText = trackMoodLabel(trace.overallMood, strings);
    final hour = trace.createdAt.hour.toString().padLeft(2, '0');
    final minute = trace.createdAt.minute.toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(tokens.cardRadius)),
        border: Border.all(color: tokens.border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trace.dateKey} • $hour:$minute',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tokens.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: moodStyle.color.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: moodStyle.color.withValues(alpha: 0.65),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    moodStyle.icon,
                                    size: 16,
                                    color: moodStyle.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    moodText,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.surfaceSecondary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '${strings.moodIntensityLabel}: ${trace.moodIntensity}/10',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textPrimary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (trace.journalText != null &&
                  trace.journalText!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.surfaceSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Text(
                    trace.journalText!.trim(),
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.48,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
              ],
              if (trace.situation != null &&
                  trace.situation!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  strings.triggersContextHeader,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: strings.isArabic ? 0 : 0.6,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: trace.situation!
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.surfaceSecondary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tokens.border),
                          ),
                          child: Text(
                            strings.trackTriggerDisplay(item),
                            style: TextStyle(
                              fontSize: 12,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),
              MindButton(
                text: strings.exploreWithAiGuideBtn,
                isFullWidth: true,
                leadingIcon: Icons.forum_outlined,
                onPressed: () {
                  Navigator.of(context).pop();
                  onExploreWithAi();
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: MindPressable(
                      semanticLabel: strings.editEntryBtn,
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onEdit();
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: tokens.surfaceSecondary,
                          borderRadius:
                              BorderRadius.circular(tokens.buttonRadius),
                          border: Border.all(color: tokens.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: tokens.textPrimary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                strings.editEntryBtn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MindPressable(
                      semanticLabel: strings.deleteEntryBtn,
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                      onPressed: () =>
                          _confirmAndDelete(context, ref, strings, tokens),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: tokens.safetyWarmthSoft,
                          borderRadius:
                              BorderRadius.circular(tokens.buttonRadius),
                          border: Border.all(
                            color: tokens.safetyWarmth.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 17,
                              color: tokens.safetyWarmth,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                strings.deleteEntryBtn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.safetyWarmth,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal editor for historical traces so editing past entries never overwrites
/// today's live Check-In Today form.
class EditPastTraceSheet extends ConsumerStatefulWidget {
  const EditPastTraceSheet({super.key, required this.trace});

  final MindTraceModel trace;

  static Future<void> show(BuildContext context, MindTraceModel trace) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditPastTraceSheet(trace: trace),
    );
  }

  @override
  ConsumerState<EditPastTraceSheet> createState() => _EditPastTraceSheetState();
}

class _EditPastTraceSheetState extends ConsumerState<EditPastTraceSheet> {
  late String _mood;
  late double _intensity;
  late TextEditingController _noteCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _mood = widget.trace.overallMood;
    _intensity = widget.trace.moodIntensity.toDouble().clamp(1, 10);
    _noteCtrl = TextEditingController(text: widget.trace.journalText ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _noteCtrl.text.trim();
    if (text.isNotEmpty && CrisisKeywords.evaluateText(text) == 2) {
      if (mounted) SafetyInterceptor.showCrisisPauseDialog(context);
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = widget.trace.copyWith(
        overallMood: _mood,
        selectedEmotions: [_mood],
        moodIntensity: _intensity.round(),
        journalText: text.isNotEmpty ? text : null,
      );
      await ref
          .read(mindTraceControllerProvider.notifier)
          .updateCheckIn(updated);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(tokens.cardRadius)),
          border: Border.all(color: tokens.border),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 20),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${strings.editEntryTitle} (${widget.trace.dateKey})',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                TrackMoodPicker(
                  selectedMoodKey: _mood,
                  strings: strings,
                  onSelect: (key) => setState(() => _mood = key),
                ),
                const SizedBox(height: 16),
                TrackIntensitySlider(
                  value: _intensity,
                  strings: strings,
                  inCard: false,
                  onChanged: (v) => setState(() => _intensity = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    color: tokens.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: strings.whatsOnYourMindHint,
                    filled: true,
                    fillColor: tokens.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: tokens.border),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                MindButton(
                  text: strings.saveChangesBtn,
                  isFullWidth: true,
                  isLoading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

