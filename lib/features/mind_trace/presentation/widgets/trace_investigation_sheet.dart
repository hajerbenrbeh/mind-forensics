import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../controllers/mind_trace_controller.dart';
import '../../domain/mind_trace_model.dart';
import '../../domain/thought_trace_investigation.dart';

/// Modal bottom sheet allowing users to deconstruct a saved thought trace
/// using Socratic reflective questions. Non-coercive, completely optional.
class TraceInvestigationSheet extends ConsumerStatefulWidget {
  const TraceInvestigationSheet({
    super.key,
    required this.trace,
  });

  final MindTraceModel trace;

  static Future<void> show(BuildContext context, MindTraceModel trace) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TraceInvestigationSheet(trace: trace),
    );
  }

  @override
  ConsumerState<TraceInvestigationSheet> createState() =>
      _TraceInvestigationSheetState();
}

class _TraceInvestigationSheetState
    extends ConsumerState<TraceInvestigationSheet> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final q in ThoughtTraceInvestigation.questions) {
      String initialVal = widget.trace.investigationAnswers[q.id] ?? '';
      if (initialVal.isEmpty) {
        if (q.id == 'trigger' && widget.trace.situation != null) {
          initialVal = widget.trace.situation!;
        } else if (q.id == 'response' &&
            widget.trace.behavioralResponse != null) {
          initialVal = widget.trace.behavioralResponse!;
        }
      }
      _controllers[q.id] = TextEditingController(text: initialVal);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final updatedAnswers = <String, String>{};
    for (final entry in _controllers.entries) {
      final text = entry.value.text.trim();
      if (text.isNotEmpty) {
        updatedAnswers[entry.key] = text;
      }
    }

    final updatedTrace = widget.trace.copyWith(
      investigationAnswers: updatedAnswers,
      situation: updatedAnswers['trigger'] ?? widget.trace.situation,
      behavioralResponse:
          updatedAnswers['response'] ?? widget.trace.behavioralResponse,
      updatedAt: DateTime.now(),
    );

    try {
      await ref
          .read(mindTraceControllerProvider.notifier)
          .updateCheckIn(updatedTrace);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: LabColors.surfaceElevated,
            content: Text(
              'Thought reflection saved to your record.',
              style: TextStyle(color: LabColors.textPrimary, fontSize: 13),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final media = MediaQuery.of(context);

    return Container(
      height: media.size.height * 0.90,
      decoration: const BoxDecoration(
        color: LabColors.surface0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: LabColors.borderSubtle, width: 1),
          left: BorderSide(color: LabColors.borderSubtle, width: 1),
          right: BorderSide(color: LabColors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: LabColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.isArabic
                            ? 'استكشاف الفكرة'
                            : (strings.isFrench
                                ? 'EXPLORATION DE LA PENSÉE'
                                : 'EXPLORE THIS THOUGHT'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: LabColors.burgundyRose,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.isArabic
                            ? 'استكشف هذه اللحظة بفضول ولطف. جميع الأسئلة اختيارية.'
                            : (strings.isFrench
                                ? 'Explorez ce moment avec curiosité. Toutes les questions sont facultatives.'
                                : 'Explore this moment with curiosity and compassion. Every question is optional.'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: LabColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: LabColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: LabColors.borderSubtle, height: 1),

          // Scrollable inquiry questions
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                // Thought preview anchor card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LabColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: LabColors.burgundyMaroon.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: LabColors.burgundyRose,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            strings.isArabic
                                ? 'الأثر قيد الفحص'
                                : (strings.isFrench
                                    ? 'EMPREINTE EN COURS D’EXAMEN'
                                    : 'ANCHOR THOUGHT UNDER INQUIRY'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: LabColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '“${widget.trace.thoughtPreview}”',
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: LabColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Render each of the 6 Socratic questions
                for (var i = 0;
                    i < ThoughtTraceInvestigation.questions.length;
                    i++) ...[
                  _buildQuestionSection(
                    ThoughtTraceInvestigation.questions[i],
                    index: i + 1,
                  ),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),

          // Bottom Action
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              12 + media.padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: LabColors.surface0,
              border: Border(
                top: BorderSide(color: LabColors.borderSubtle, width: 1),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LabColors.textPrimary,
                  foregroundColor: LabColors.surface0,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            LabColors.surface0,
                          ),
                        ),
                      )
                    : Text(
                        strings.isArabic
                            ? 'حفظ التأمل والتفكيك'
                            : (strings.isFrench
                                ? 'ENREGISTRER LA RÉFLEXION'
                                : 'SAVE REFLECTION TO TRACE'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection(
    ThoughtTraceInvestigationQuestion q, {
    required int index,
  }) {
    final controller = _controllers[q.id];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LabColors.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LabColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: LabColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: LabColors.borderSubtle),
                ),
                child: Text(
                  '0$index',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: LabColors.burgundyRose,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  q.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    color: LabColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            q.question,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: LabColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            q.hint,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: LabColors.textSecondary.withValues(alpha: 0.8),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(
              fontSize: 13,
              color: LabColors.textPrimary,
              height: 1.4,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Record your observation (optional)...',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: LabColors.textTertiary,
              ),
              filled: true,
              fillColor: LabColors.surface0,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: LabColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: LabColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: LabColors.burgundyRose),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

