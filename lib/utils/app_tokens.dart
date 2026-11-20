import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semantic design tokens for the Heirloom Linen & Botanical Press aesthetic.
/// Centralizes all colors, surfaces, typography, spacing, radii, and soft shadows.
abstract class AppTokens {
  // --- COLOR PALETTE: DAYLIGHT (SUNLIT LINEN & PORCELAIN) ---
  static const Color bgLight = Color(0xFFF7F4EE); // Warm cotton paper cream
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure porcelain white
  static const Color surfaceWarmLight = Color(0xFFF2ECE1); // Soft oat linen
  static const Color surfaceMutedLight = Color(0xFFEDEAE4); // Dove parchment grey
  static const Color borderLight = Color(0xFFE4DFD5); // Warm stone hairline
  static const Color borderHoverLight = Color(0xFFD3CCC0); // Pressed stone edge

  static const Color textPrimaryLight = Color(0xFF23201C); // Espresso walnut ink
  static const Color textSecondaryLight = Color(0xFF6B665E); // Weathered pebble grey
  static const Color textMutedLight = Color(0xFF9C968D); // Soft dove ash

  // --- COLOR PALETTE: EVENING (CANDLELIT BASALT & WARM CHARCOAL) ---
  static const Color bgDark = Color(0xFF171614); // Deep warm charcoal
  static const Color surfaceDark = Color(0xFF211F1C); // Warm basalt stone
  static const Color surfaceWarmDark = Color(0xFF2A2722); // Smoked oat charcoal
  static const Color surfaceMutedDark = Color(0xFF2D2B27); // Matte ash track
  static const Color borderDark = Color(0xFF38342E); // Warm stone divider
  static const Color borderHoverDark = Color(0xFF4C473F); // Active ash divider

  static const Color textPrimaryDark = Color(0xFFF3EFE8); // Warm porcelain cream ink
  static const Color textSecondaryDark = Color(0xFFAFA99E); // Soft silver pebble
  static const Color textMutedDark = Color(0xFF7B756C); // Quiet ash stone

  // --- SINGLE ACCENT FAMILY: EUCALYPTUS & DRIED OLIVE SAGE ---
  static const Color primaryLight = Color(0xFF5D7261); // Eucalyptus sage
  static const Color primaryDark = Color(0xFF8FA893); // Moonlit eucalyptus sage
  static const Color onPrimaryLight = Color(0xFFFFFFFF); // Crisp white on sage
  static const Color onPrimaryDark = Color(0xFF171614); // Deep espresso on pale sage
  static const Color primaryContainerLight = Color(0xFFEAF0EA); // Whisper sage mist
  static const Color primaryContainerDark = Color(0xFF263128); // Deep smoked sage
  static const Color sageInkLight = Color(0xFF425446); // Deep dried olive for small labels
  static const Color sageInkDark = Color(0xFFAEC4B1); // Pale sage mist text

  // --- RESTRAINED NEUTRAL COMPLEMENT: WARM LINEN SAND (CHEF'S NOTE & PICKS) ---
  static const Color sandTintLight = Color(0xFFF3EDE2); // Unbleached linen sand
  static const Color sandTintDark = Color(0xFF2B2720); // Smoked linen sand
  static const Color sandBorderLight = Color(0xFFE3D9C8); // Sand hairline
  static const Color sandBorderDark = Color(0xFF403A30); // Dark sand hairline
  static const Color sandInkLight = Color(0xFF5C5243); // Warm driftwood ink
  static const Color sandInkDark = Color(0xFFD6CCBC); // Pale linen ink

  // --- RESTRAINED SEMANTIC STATUS ---
  static const Color errorLight = Color(0xFF9E473D); // Muted terracotta clay
  static const Color errorDark = Color(0xFFD07A70); // Soft clay

  // --- SEMANTIC ACCESSORS (CLEAN DARK/LIGHT RESOLUTION) ---
  static Color bg(bool isDark) => isDark ? bgDark : bgLight;
  static Color surface(bool isDark) => isDark ? surfaceDark : surfaceLight;
  static Color surfaceWarm(bool isDark) => isDark ? surfaceWarmDark : surfaceWarmLight;
  static Color surfaceMuted(bool isDark) => isDark ? surfaceMutedDark : surfaceMutedLight;
  static Color border(bool isDark) => isDark ? borderDark : borderLight;
  static Color textPrimary(bool isDark) => isDark ? textPrimaryDark : textPrimaryLight;
  static Color textSecondary(bool isDark) => isDark ? textSecondaryDark : textSecondaryLight;
  static Color textMuted(bool isDark) => isDark ? textMutedDark : textMutedLight;
  static Color primary(bool isDark) => isDark ? primaryDark : primaryLight;
  static Color onPrimary(bool isDark) => isDark ? onPrimaryDark : onPrimaryLight;
  static Color primaryContainer(bool isDark) => isDark ? primaryContainerDark : primaryContainerLight;
  static Color sageInk(bool isDark) => isDark ? sageInkDark : sageInkLight;
  static Color sandTint(bool isDark) => isDark ? sandTintDark : sandTintLight;
  static Color sandBorder(bool isDark) => isDark ? sandBorderDark : sandBorderLight;
  static Color sandInk(bool isDark) => isDark ? sandInkDark : sandInkLight;
  static Color error(bool isDark) => isDark ? errorDark : errorLight;

  // --- COMPATIBILITY ALIASES (mapped cleanly into the sage & linen palette) ---
  static const Color accentSun = sandInkLight;
  static const Color accentSunDark = sandInkDark;
  static const Color accentSunTintLight = sandTintLight;
  static const Color accentSunTintDark = sandTintDark;
  static const Color accentMintLight = primaryLight;
  static const Color accentMintDark = primaryDark;
  static const Color accentMintTintLight = primaryContainerLight;
  static const Color accentMintTintDark = primaryContainerDark;
  static const Color accentSkyLight = textSecondaryLight;
  static const Color accentSkyDark = textSecondaryDark;

  // --- SPACING TOKENS ---
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double spaceXxl = 48.0;

  // --- BORDER RADII ---
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 20.0;
  static const double radiusPill = 999.0;

  // --- DIFFUSED PAPER SHADOWS ---
  static List<BoxShadow> paperShadow(bool isDark) => isDark
      ? const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x0A23201C),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x0523201C),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A23201C),
      blurRadius: 18,
      offset: Offset(0, 5),
    ),
  ];

  // --- TYPOGRAPHY HELPERS (Fraunces Editorial Serif + DM Sans) ---
  /// Expressive heirloom editorial serif for headers, dish titles, and seasonal greetings
  static TextStyle display({
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.w500,
    FontStyle fontStyle = FontStyle.normal,
    Color? color,
    double height = 1.18,
    double letterSpacing = -0.4,
  }) {
    return GoogleFonts.fraunces(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Editorial italic serif for cookbook dish headers and numbered indices
  static TextStyle serifItalic({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 1.2,
    double letterSpacing = -0.3,
  }) {
    return GoogleFonts.fraunces(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: FontStyle.italic,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Backward-compatible alias for display serif typography
  static TextStyle serifDisplay({
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double height = 1.18,
    double letterSpacing = -0.4,
  }) {
    return display(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Tracked uppercase micro-kicker for sections, metadata, and quiet printed tags
  static TextStyle kicker({
    double fontSize = 10.5,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double letterSpacing = 1.3,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Clean, airy sans-serif for descriptions, ingredient lists, and instructions
  static TextStyle sansBody({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 1.5,
    double letterSpacing = 0.0,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Tabular-aligned numerals for weights, cook times, servings, and timers
  static TextStyle numeral({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double letterSpacing = -0.1,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
