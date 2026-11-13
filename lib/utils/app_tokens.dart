import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semantic design tokens for Solaris Gourmet aesthetic.
/// Centralizes all colors, spacing, typography, radii, gradients, and shadows.
abstract class AppTokens {
  // --- COLOR PALETTE: LIGHT (SOLARIS GOURMET: SUNLIT LINEN) ---
  static const Color bgLight = Color(0xFFFFFDF9); // Sunlit warm linen
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure snow white
  static const Color surfaceMutedLight = Color(0xFFF8F5EE); // Morning oat
  static const Color borderLight = Color(0xFFEDE7DC); // Sun-bleached hairline divider
  static const Color borderHoverLight = Color(0xFFDFD7C8);

  static const Color textPrimaryLight = Color(0xFF1A1815); // Espresso roast
  static const Color textSecondaryLight = Color(0xFF6E685F); // Warm sunlit pebble
  static const Color textMutedLight = Color(0xFFA39C93); // Soft stone

  // --- COLOR PALETTE: DARK (MIDNIGHT AZURE TWILIGHT) ---
  static const Color bgDark = Color(0xFF0E131F); // Midnight azure ground
  static const Color surfaceDark = Color(0xFF172033); // Twilight slate card
  static const Color surfaceMutedDark = Color(0xFF1F2B44); // Elevated slate
  static const Color borderDark = Color(0xFF2A3854); // Slate hairline divider
  static const Color borderHoverDark = Color(0xFF3D4F73);

  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Pure moonlight
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Soft silver
  static const Color textMutedDark = Color(0xFF64748B); // Slate grey

  // --- ACCENTS: SUNBURST TANGERINE & FRESH HERBS ---
  static const Color primaryLight = Color(0xFFFF643D); // Sunburst Tangerine
  static const Color primaryDark = Color(0xFFFF7A45); // Radiant Coral
  static const Color primaryContainerLight = Color(0xFFFFF0EB); // Soft peach mist
  static const Color primaryContainerDark = Color(0xFF381D14);

  // Limoncello / Golden Nectar
  static const Color accentSun = Color(0xFFFFB300); // Sunny Limoncello
  static const Color accentSunDark = Color(0xFFFFC107);
  static const Color accentSunTintLight = Color(0xFFFFF9E6); // Honey sunlight
  static const Color accentSunTintDark = Color(0xFF33270A);

  // Fresh Basil & Mint
  static const Color accentMintLight = Color(0xFF10B981); // Fresh Basil Mint
  static const Color accentMintDark = Color(0xFF34D399);
  static const Color accentMintTintLight = Color(0xFFE8F8F2); // Herb mist
  static const Color accentMintTintDark = Color(0xFF102E24);

  // Coastal Azure
  static const Color accentSkyLight = Color(0xFF0284C7); // Coastal Azure
  static const Color accentSkyDark = Color(0xFF38BDF8);
  static const Color accentSkyTintLight = Color(0xFFE0F2FE); // Seafoam sky mist
  static const Color accentSkyTintDark = Color(0xFF0C2C45);

  // Compatibility aliases
  static const Color accentClayLight = primaryLight;
  static const Color accentClayDark = primaryDark;
  static const Color accentClayTintLight = primaryContainerLight;
  static const Color accentClayTintDark = primaryContainerDark;
  static const Color accentGold = accentSun;
  static const Color accentGoldTint = accentSunTintLight;

  static const Color errorLight = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFF87171);

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
  static const double radiusMd = 16.0;
  static const double radiusLg = 22.0;
  static const double radiusPill = 999.0;

  // --- GRADIENTS ---
  static const LinearGradient sunburstGradient = LinearGradient(
    colors: [Color(0xFFFF7A45), Color(0xFFFF5226)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldenNectarGradient = LinearGradient(
    colors: [Color(0xFFFFC02E), Color(0xFFFF9E00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient azureGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- SHADOWS ---
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> sunGlowShadow = [
    BoxShadow(
      color: Color(0x38FF643D),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  // --- TYPOGRAPHY HELPERS (Outfit + Plus Jakarta Sans) ---
  /// Modern energetic headline font for titles, dish titles, and banners
  static TextStyle display({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double height = 1.2,
    double letterSpacing = -0.5,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Backward-compatible alias for display typography
  static TextStyle serifDisplay({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double height = 1.2,
    double letterSpacing = -0.5,
  }) {
    return display(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Tracked uppercase kicker for category pills, section tags, and micro badges
  static TextStyle kicker({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double letterSpacing = 1.2,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Modern, crisp, airy body text for descriptions, ingredients, and instructions
  static TextStyle sansBody({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 1.45,
    double letterSpacing = 0.0,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Numbers, measurements, cooking timers, step counters
  static TextStyle numeral({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double letterSpacing = -0.2,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}
