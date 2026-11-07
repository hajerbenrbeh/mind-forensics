import 'package:flutter/material.dart';
import 'lab_colors.dart';
import 'mind_tokens.dart';

/// Mind Forensics Design System Theme.
///
/// Implements the calm, human, sophisticated, emotionally reassuring identity
/// using the Earth/Sage palette (Light #F7F8F5, Dark #151B19).
/// Precision 20px corner radii, subtle 1px hairline borders, balanced typography.
class LabTheme {
  static TextStyle monoStyle({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double letterSpacing = -0.2,
  }) {
    return TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Warm, thoughtful editorial style for prominent headings and foundational questions.
  static TextStyle serifStyle({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double letterSpacing = -0.2,
    double height = 1.3,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Secondary editorial style with calm pacing for reflective quotes and insights.
  static TextStyle editorialSerif({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double letterSpacing = 0.0,
    double height = 1.5,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontStyle: fontStyle,
    );
  }

  /// Daylight Theme (Calm Linen & Botanical Sage)
  static ThemeData get daylightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: LabColors.daylightBackground,
      extensions: const [MindTokens.light],
      colorScheme: const ColorScheme.light(
        primary: LabColors.daylightAccent,
        surface: LabColors.daylightSurface,
        onSurface: LabColors.daylightTextPrimary,
        outline: LabColors.daylightBorder,
        surfaceContainerHighest: LabColors.daylightSurfaceSubtle,
      ),
      cardTheme: CardThemeData(
        color: LabColors.daylightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: LabColors.daylightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LabColors.daylightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: LabColors.daylightTextSecondary, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LabColors.daylightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LabColors.daylightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LabColors.daylightAccent, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LabColors.daylightTextPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48), // Accessible touch target
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LabColors.daylightTextPrimary,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: LabColors.daylightBorder, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: LabColors.daylightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: LabColors.daylightTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Inter',
          color: LabColors.daylightTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          color: LabColors.daylightTextSecondary,
          fontSize: 13.5,
          height: 1.45,
        ),
      ),
    );
  }

  /// Night Theme (Deep Slate Botanical & Glowing Sage)
  static ThemeData get nightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: LabColors.nightBackground,
      extensions: const [MindTokens.dark],
      colorScheme: const ColorScheme.dark(
        primary: LabColors.nightAccent,
        surface: LabColors.nightSurface,
        onSurface: LabColors.nightTextPrimary,
        outline: LabColors.nightBorder,
        surfaceContainerHighest: LabColors.nightSurfaceSubtle,
      ),
      cardTheme: CardThemeData(
        color: LabColors.nightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: LabColors.nightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LabColors.nightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: LabColors.nightTextSecondary, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LabColors.nightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LabColors.nightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LabColors.nightAccent, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LabColors.nightAccent,
          foregroundColor: const Color(0xFF151B19),
          minimumSize: const Size(48, 48), // Accessible touch target
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LabColors.nightTextPrimary,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: LabColors.nightBorder, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: LabColors.nightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: LabColors.nightTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Inter',
          color: LabColors.nightTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          color: LabColors.nightTextSecondary,
          fontSize: 13.5,
          height: 1.45,
        ),
      ),
    );
  }
}
