import 'package:flutter/material.dart';
import '../../domain/mind_trace_model.dart';
import 'thought_trace_detail_sheet.dart';

export 'thought_trace_detail_sheet.dart';

/// Legacy alias for ThoughtTraceDetailSheet preserving backwards compatibility.
class TraceEntryDetailSheet extends StatelessWidget {
  const TraceEntryDetailSheet({
    super.key,
    required this.trace,
    this.onEdit,
  });

  final MindTraceModel trace;
  final VoidCallback? onEdit;

  static Future<void> show(
    BuildContext context, {
    required MindTraceModel trace,
    VoidCallback? onEdit,
  }) {
    return ThoughtTraceDetailSheet.show(
      context,
      trace: trace,
      onEdit: onEdit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThoughtTraceDetailSheet(trace: trace, onEdit: onEdit);
  }
}
