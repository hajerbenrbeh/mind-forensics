import 'package:flutter/material.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_pressable.dart';

/// Semantic, calm card primitive for Mind Forensics.
///
/// Implements 10px corner radius, hairline 1.0px border, zero decorative elevation,
/// and optional tactile press feedback.
class MindCard extends StatelessWidget {
  const MindCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.semanticLabel,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cardRadius = BorderRadius.circular(radius ?? tokens.cardRadius);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? tokens.surface,
        borderRadius: cardRadius,
        border: Border.all(
          color: borderColor ?? tokens.border,
          width: 1.0,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      content = MindPressable(
        onPressed: onTap,
        borderRadius: cardRadius,
        semanticLabel: semanticLabel,
        child: content,
      );
    } else if (semanticLabel != null) {
      content = Semantics(
        container: true,
        label: semanticLabel,
        child: content,
      );
    }

    return content;
  }
}

