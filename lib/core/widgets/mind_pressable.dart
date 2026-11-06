import 'package:flutter/material.dart';

/// House tactile pressable for Mind Forensics.
///
/// Replaces stock Material ink splash ripples with subtle, organic scale/sink motion.
/// Respects accessibility reduce-motion settings via [MediaQuery.disableAnimationsOf].
class MindPressable extends StatefulWidget {
  const MindPressable({
    super.key,
    required this.child,
    this.onPressed,
    this.enabled = true,
    this.semanticLabel,
    this.pressScale = 0.98,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;
  final String? semanticLabel;
  final double pressScale;
  final BorderRadius? borderRadius;

  @override
  State<MindPressable> createState() => _MindPressableState();
}

class _MindPressableState extends State<MindPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool interactive = widget.enabled && widget.onPressed != null;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final Duration duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 90);
    final bool isPressed = _pressed && interactive;

    Widget result = AnimatedScale(
      scale: isPressed ? widget.pressScale : 1.0,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: widget.child,
    );

    if (widget.borderRadius != null) {
      result = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: result,
      );
    }

    result = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: interactive ? (_) => setState(() => _pressed = true) : null,
      onTapUp: interactive ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: interactive ? () => setState(() => _pressed = false) : null,
      onTap: interactive ? widget.onPressed : null,
      child: result,
    );

    if (widget.semanticLabel != null) {
      return Semantics(
        button: true,
        enabled: interactive,
        label: widget.semanticLabel,
        child: result,
      );
    }

    return result;
  }
}
