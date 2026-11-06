import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/lab_colors.dart';

/// Luxury "Slide-to-Anchor" tactile slider.
///
/// Replaces generic tap buttons with an intentional, somatic swipe gesture
/// that gives psychological finality and grounding when anchoring a reframe.
class SlideToAnchor extends StatefulWidget {
  const SlideToAnchor({
    super.key,
    required this.label,
    required this.onCompleted,
    this.accentColor = LabColors.warmBeige,
    this.backgroundColor,
    this.height = 54.0,
    this.isDark = true,
  });

  final String label;
  final Future<void> Function() onCompleted;
  final Color accentColor;
  final Color? backgroundColor;
  final double height;
  final bool isDark;

  @override
  State<SlideToAnchor> createState() => _SlideToAnchorState();
}

class _SlideToAnchorState extends State<SlideToAnchor> with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  late final AnimationController _resetController;
  late Animation<double> _resetAnimation;
  int _lastHapticStep = 0;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        setState(() => _dragPosition = _resetAnimation.value);
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isCompleted) return;

    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
      final progress = maxDrag > 0 ? _dragPosition / maxDrag : 0.0;

      // Progressive micro-haptics along the drag path
      final step = (progress * 4).floor();
      if (step != _lastHapticStep && step > 0) {
        _lastHapticStep = step;
        HapticFeedback.selectionClick();
      }
    });
  }

  Future<void> _onHorizontalDragEnd(DragEndDetails details, double maxDrag) async {
    if (_isCompleted) return;

    final progress = maxDrag > 0 ? _dragPosition / maxDrag : 0.0;
    if (progress >= 0.85) {
      // Snap to end
      setState(() {
        _dragPosition = maxDrag;
        _isCompleted = true;
      });
      HapticFeedback.heavyImpact();
      await widget.onCompleted();
    } else {
      // Snap back
      _lastHapticStep = 0;
      _resetAnimation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
      );
      _resetController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final trackHeight = widget.height;
    final thumbSize = trackHeight - 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = (constraints.maxWidth - thumbSize - 8.0).clamp(0.0, double.infinity);
        final progress = maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        final trackBg = widget.backgroundColor ??
            (isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF4F4F5));
        final borderColor = isDark ? const Color(0xFF242424) : const Color(0xFFE4E4E7);

        return Container(
          height: trackHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: trackBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Filled Progress Glow Track
              Container(
                width: _dragPosition + thumbSize + 4.0,
                height: trackHeight,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: isDark ? 0.22 : 0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),

              // Centered Prompt Label
              Center(
                child: Opacity(
                  opacity: (1.0 - (progress * 1.4)).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                      ),
                    ],
                  ),
                ),
              ),

              // Interactive Draggable Thumb
              Positioned(
                left: 4.0 + _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: (details) => _onHorizontalDragEnd(details, maxDrag),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: _isCompleted
                          ? widget.accentColor
                          : (isDark ? Colors.white : Colors.black),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: progress * 0.4),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isCompleted ? Icons.check_rounded : Icons.anchor_rounded,
                        size: 20,
                        color: _isCompleted
                            ? Colors.black
                            : (isDark ? Colors.black : Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

