import 'package:flutter/material.dart';
import '../../app/theme/lab_colors.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_pressable.dart';

enum MindButtonVariant {
  primary,
  secondary,
  soft,
  danger,
}

/// Accessible, minimum 48×48px tap target button with tactile micro-interaction.
class MindButton extends StatelessWidget {
  const MindButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = MindButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final MindButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null && !isLoading;

    Color bg;
    Color fg;
    Color border;

    switch (variant) {
      case MindButtonVariant.primary:
        bg = isDark ? tokens.accent : tokens.textPrimary;
        fg = isDark ? const Color(0xFF151B19) : Colors.white;
        border = Colors.transparent;
        break;
      case MindButtonVariant.secondary:
        bg = Colors.transparent;
        fg = tokens.textPrimary;
        border = tokens.border;
        break;
      case MindButtonVariant.soft:
        bg = tokens.accentSoft;
        fg = isDark ? tokens.accent : tokens.textPrimary;
        border = tokens.border;
        break;
      case MindButtonVariant.danger:
        bg = isDark ? LabColors.cherryBgDark : LabColors.cherryBgLight;
        fg = LabColors.cherryRed;
        border = isDark ? LabColors.cherryBorderDark : LabColors.cherryBorderLight;
        break;
    }

    if (!enabled) {
      bg = bg.withValues(alpha: 0.5);
      fg = fg.withValues(alpha: 0.5);
    }

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 16, color: fg),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            color: fg,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 16, color: fg),
        ],
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 48,
        minWidth: isFullWidth ? double.infinity : 48,
      ),
      child: MindPressable(
        onPressed: enabled ? onPressed : null,
        enabled: enabled,
        semanticLabel: text,
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
            border: Border.all(color: border, width: 1.0),
          ),
          child: content,
        ),
      ),
    );
  }
}

