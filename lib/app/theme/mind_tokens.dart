import 'package:flutter/material.dart';
import 'lab_colors.dart';

/// Semantic token extension for Mind Forensics following the project-owned
/// design system discipline (avoiding raw hex values across widgets).
class MindTokens extends ThemeExtension<MindTokens> {
  const MindTokens({
    required this.background,
    required this.surface,
    required this.surfaceSecondary,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentSoft,
    required this.safetyWarmth,
    required this.safetyWarmthSoft,
    required this.cardRadius,
    required this.buttonRadius,
    required this.chipRadius,
  });

  final Color background;
  final Color surface;
  final Color surfaceSecondary;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color accentSoft;
  final Color safetyWarmth;
  final Color safetyWarmthSoft;
  final double cardRadius;
  final double buttonRadius;
  final double chipRadius;

  static const MindTokens light = MindTokens(
    background: LabColors.daylightBackground,
    surface: LabColors.daylightSurface,
    surfaceSecondary: LabColors.daylightSurfaceSubtle,
    border: LabColors.daylightBorder,
    textPrimary: LabColors.daylightTextPrimary,
    textSecondary: LabColors.daylightTextSecondary,
    textTertiary: Color(0xFF8A948D),
    accent: LabColors.daylightAccent,
    accentSoft: LabColors.daylightAccentSoft,
    safetyWarmth: LabColors.safetyWarmth,
    safetyWarmthSoft: LabColors.safetySoftBgLight,
    cardRadius: 20.0,
    buttonRadius: 18.0,
    chipRadius: 20.0,
  );

  static const MindTokens dark = MindTokens(
    background: LabColors.nightBackground,
    surface: LabColors.nightSurface,
    surfaceSecondary: LabColors.nightSurfaceSubtle,
    border: LabColors.nightBorder,
    textPrimary: LabColors.nightTextPrimary,
    textSecondary: LabColors.nightTextSecondary,
    textTertiary: LabColors.textTertiary,
    accent: LabColors.nightAccent,
    accentSoft: LabColors.nightAccentSoft,
    safetyWarmth: LabColors.safetyWarmthDark,
    safetyWarmthSoft: LabColors.safetySoftBgDark,
    cardRadius: 20.0,
    buttonRadius: 18.0,
    chipRadius: 20.0,
  );

  @override
  MindTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceSecondary,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? accentSoft,
    Color? safetyWarmth,
    Color? safetyWarmthSoft,
    double? cardRadius,
    double? buttonRadius,
    double? chipRadius,
  }) {
    return MindTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      safetyWarmth: safetyWarmth ?? this.safetyWarmth,
      safetyWarmthSoft: safetyWarmthSoft ?? this.safetyWarmthSoft,
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      chipRadius: chipRadius ?? this.chipRadius,
    );
  }

  @override
  MindTokens lerp(ThemeExtension<MindTokens>? other, double t) {
    if (other is! MindTokens) return this;
    return MindTokens(
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceSecondary: Color.lerp(surfaceSecondary, other.surfaceSecondary, t) ?? surfaceSecondary,
      border: Color.lerp(border, other.border, t) ?? border,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t) ?? textTertiary,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t) ?? accentSoft,
      safetyWarmth: Color.lerp(safetyWarmth, other.safetyWarmth, t) ?? safetyWarmth,
      safetyWarmthSoft: Color.lerp(safetyWarmthSoft, other.safetyWarmthSoft, t) ?? safetyWarmthSoft,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      buttonRadius: buttonRadius + (other.buttonRadius - buttonRadius) * t,
      chipRadius: chipRadius + (other.chipRadius - chipRadius) * t,
    );
  }
}

extension MindTokensBuildContext on BuildContext {
  MindTokens get tokens => Theme.of(this).extension<MindTokens>() ??
      (Theme.of(this).brightness == Brightness.dark ? MindTokens.dark : MindTokens.light);
}

