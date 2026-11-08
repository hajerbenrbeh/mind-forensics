import 'package:flutter/material.dart';
import '../../features/investigation/domain/label_type.dart';

/// Mind Forensics Calm & Intelligent Design System Palette.
///
/// Implements the organic Earth/Sage palette:
/// - Light: Linen / Sage (#F7F8F5, #FFFFFF, #E5ECE6, #668274, #34443B)
/// - Dark: Deep Slate Botanical (#151B19, #202925, #303E37, #91AD9A, #F0F2EC)
///
/// Replaces harsh clinical pitch-black and cosmic metaphors with a grounded,
/// emotionally reassuring, accessible, and sophisticated visual identity.
class LabColors {
  // Constant Cognitive Epistemic Labels (Fact, Assumption, Interpretation)
  static const Color factBlue = Color(0xFF38BDF8); // Crisp Sky / Ice
  static const Color factBackgroundLight = Color(0xFFF0F9FF);
  static const Color factBackgroundDark = Color(0xFF0F2936);
  static const Color factBorderLight = Color(0xFFBAE6FD);
  static const Color factBorderDark = Color(0xFF164E63);

  static const Color assumptionAmber = Color(0xFFFBBF24); // Warm Gold
  static const Color assumptionBackgroundLight = Color(0xFFFFFBEB);
  static const Color assumptionBackgroundDark = Color(0xFF3B2A10);
  static const Color assumptionBorderLight = Color(0xFFFDE68A);
  static const Color assumptionBorderDark = Color(0xFF78350F);

  static const Color interpretationViolet = Color(0xFFA78BFA); // Soft Iris
  static const Color interpretationBackgroundLight = Color(0xFFF5F3FF);
  static const Color interpretationBackgroundDark = Color(0xFF281E3D);
  static const Color interpretationBorderLight = Color(0xFFDDD6FE);
  static const Color interpretationBorderDark = Color(0xFF4C1D95);

  // Convenience aliases for Epistemic Triage
  static const Color factBackground = factBackgroundLight;
  static const Color factBorder = factBorderLight;
  static const Color assumptionBackground = assumptionBackgroundLight;
  static const Color assumptionBorder = assumptionBorderLight;
  static const Color interpretationBackground = interpretationBackgroundLight;
  static const Color interpretationBorder = interpretationBorderLight;

  // ===========================================================================
  // DAYLIGHT PALETTE (Calm Organic Linen & Sage)
  // ===========================================================================
  static const Color daylightBackground = Color(0xFFF7F8F5); // Soft natural parchment
  static const Color daylightSurface = Color(0xFFFFFFFF); // Crisp clean surface
  static const Color daylightSurfaceSubtle = Color(0xFFE5ECE6); // Muted secondary surface
  static const Color daylightBorder = Color(0xFFD6DDD7); // Soft organic boundary
  static const Color daylightTextPrimary = Color(0xFF34443B); // Deep slate forest green
  static const Color daylightTextSecondary = Color(0xFF5A6F62); // Balanced neutral secondary
  static const Color daylightAccent = Color(0xFF668274); // Grounded botanical sage
  static const Color daylightAccentSoft = Color(0xFFE8EFEA);

  // ===========================================================================
  // NIGHT PALETTE (Deep Slate Botanical & Sage Glow)
  // ===========================================================================
  static const Color nightBackground = Color(0xFF151B19); // Deep calm botanical background
  static const Color nightSurface = Color(0xFF202925); // Elevated slate surface (Card)
  static const Color nightSurfaceElevated = Color(0xFF26322C); // Level 2 elevated surface
  static const Color nightSurfaceSubtle = Color(0xFF303E37); // Secondary surface
  static const Color nightBorder = Color(0xFF34433C); // Subtle boundary (1.0px)
  static const Color nightBorderSubtle = Color(0xFF25332C);
  static const Color nightTextPrimary = Color(0xFFF0F2EC); // Calm ivory primary text
  static const Color nightTextSecondary = Color(0xFF9EABA2); // Muted neutral secondary text
  static const Color nightAccent = Color(0xFF91AD9A); // Glowing sage interactive accent
  static const Color nightAccentBlue = Color(0xFF38BDF8);
  static const Color nightAccentSoft = Color(0xFF23322B);

  // ===========================================================================
  // HARMONIZED MOOD PALETTE (Distinct, dignified, grounded in nature)
  // ===========================================================================
  static const Color moodCalm = Color(0xFF91AD9A); // Botanical Sage
  static const Color moodAnxious = Color(0xFFD4976A); // Warm Sand / Desert Dune (replaces bright pink)
  static const Color moodFrustrated = Color(0xFFFBBF24); // Warm Amber Gold
  static const Color moodHeavy = Color(0xFFA78BFA); // Soft Iris Slate
  static const Color moodRestless = Color(0xFF38BDF8); // Mineral Mist / Crisp Sky

  // ===========================================================================
  // SAFETY & CRISIS WARMTH (Restrained Terracotta / Warm Clay)
  // Highly visible emergency support without harsh neon red or decorative pink
  // ===========================================================================
  static const Color safetyWarmth = Color(0xFFC04B22); // Rich Terracotta (Light contrast 5.2:1)
  static const Color safetyWarmthDark = Color(0xFFE57A58); // Terracotta Ember (Dark contrast 6.2:1)
  static const Color safetySoftBgLight = Color(0xFFFDF4EF);
  static const Color safetySoftBgDark = Color(0xFF2C1D17);
  static const Color safetyBorderLight = Color(0xFFF5D6C8);
  static const Color safetyBorderDark = Color(0xFF4D2F23);
  static const Color safetySoftBg = safetySoftBgLight;

  // Harmonized warm grounding accents (replaces cherry red & bright pink)
  static const Color cherryRed = Color(0xFFC04B22);
  static const Color cherryRedGlow = Color(0xFFD4976A); // Warm Sand / Ember (replaces #FB7185)
  static const Color cherryRedDeep = Color(0xFF8B3A1C);
  static const Color cherryBgDark = Color(0xFF2C1D17);
  static const Color cherryBorderDark = Color(0xFF4D2F23);
  static const Color cherryBgLight = Color(0xFFFDF4EF);
  static const Color cherryBorderLight = Color(0xFFF5D6C8);

  // Warm Cashmere Beige
  static const Color warmBeige = Color(0xFFD9B9A9);
  static const Color warmBeigeGlow = Color(0xFFF4E5DA);
  static const Color warmBeigeMuted = Color(0xFFC8B69B);
  static const Color warmBeigeDark = Color(0xFF8A7760);
  static const Color warmBeigeBgDark = Color(0xFF25201B);
  static const Color warmBeigeBorderDark = Color(0xFF3E362E);
  static const Color warmBeigeBgLight = Color(0xFFFAF7F2);
  static const Color warmBeigeBorderLight = Color(0xFFE8DECF);

  // Sage Green & Parasympathetic Equilibrium
  static const Color sageGreen = Color(0xFF91AD9A);
  static const Color sageGreenGlow = Color(0xFFA7C2B0);
  static const Color sageBgDark = Color(0xFF1E2B24);
  static const Color sageBorderDark = Color(0xFF2E4137);
  static const Color sageBgLight = Color(0xFFEBF1ED);
  static const Color sageBorderLight = Color(0xFFC7D7CC);

  // Backward compatibility tokens mapped directly to Earth/Sage palette
  static const Color surface0 = nightBackground;
  static const Color surface1 = nightSurface;
  static const Color surfaceElevated = nightSurfaceElevated;
  static const Color borderSubtle = nightBorder;
  static const Color textPrimary = nightTextPrimary;
  static const Color textSecondary = nightTextSecondary;
  static const Color textTertiary = Color(0xFF78887F);
  static const Color deepBurgundy = Color(0xFF2E3D36);
  static const Color darkWine = Color(0xFF202925);
  static const Color almostBlackBurgundy = Color(0xFF151B19);
  static const Color warmIvory = Color(0xFFF7F8F5);
  static const Color softBeige = Color(0xFFE5ECE6);
  static const Color champagneGold = Color(0xFF91AD9A); // Calm Sage Accent
  static const Color champagneGlow = Color(0xFFA7C2B0);
  static const Color wineBorder = Color(0xFF34433C); // Slate Border
  static const Color burgundyRose = Color(0xFF91AD9A);
  static const Color burgundyMaroon = Color(0xFF668274);
  static const Color burgundyDark = Color(0xFF202925);

  // Helper Methods
  static Color cherryBackground({bool isDark = false}) => isDark ? cherryBgDark : cherryBgLight;
  static Color cherryBorder({bool isDark = false}) => isDark ? cherryBorderDark : cherryBorderLight;
  static Color beigeBackground({bool isDark = false}) => isDark ? warmBeigeBgDark : warmBeigeBgLight;
  static Color beigeBorder({bool isDark = false}) => isDark ? warmBeigeBorderDark : warmBeigeBorderLight;
  static Color sageBackground({bool isDark = false}) => isDark ? sageBgDark : sageBgLight;
  static Color sageBorder({bool isDark = false}) => isDark ? sageBorderDark : sageBorderLight;

  static Color forLabel(LabelType label) {
    switch (label) {
      case LabelType.fact:
        return factBlue;
      case LabelType.assumption:
        return assumptionAmber;
      case LabelType.interpretation:
        return interpretationViolet;
    }
  }

  static Color labelBackground(LabelType label, {bool isDark = false}) {
    switch (label) {
      case LabelType.fact:
        return isDark ? factBackgroundDark : factBackgroundLight;
      case LabelType.assumption:
        return isDark ? assumptionBackgroundDark : assumptionBackgroundLight;
      case LabelType.interpretation:
        return isDark ? interpretationBackgroundDark : interpretationBackgroundLight;
    }
  }

  static Color labelBorder(LabelType label, {bool isDark = false}) {
    switch (label) {
      case LabelType.fact:
        return isDark ? factBorderDark : factBorderLight;
      case LabelType.assumption:
        return isDark ? assumptionBorderDark : assumptionBorderLight;
      case LabelType.interpretation:
        return isDark ? interpretationBorderDark : interpretationBorderLight;
    }
  }
}
