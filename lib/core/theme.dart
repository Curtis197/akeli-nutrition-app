import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// DESIGN TOKENS — Akeli V1
// Ref: DESIGN_SYSTEM.md
// ---------------------------------------------------------------------------

abstract class AkeliColors {
  // Brand
  static const primary = Color(0xFF3BB78F);      // Teal
  static const secondary = Color(0xFFF5A623);    // Orange
  static const tertiary = Color(0xFF8B7FD4);     // Violet

  // Backgrounds
  static const background = Color(0xFFF5F0E8);
  static const surface = Color(0xFFFFFFFF);

  // Textes
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF8A8A8A);
  static const textMuted = Color(0xFFC8C8C8);

  // Semantiques
  static const success = Color(0xFF249689);
  static const warning = Color(0xFFF9CF58);
  static const error = Color(0xFFFF5963);
  static const info = Color(0xFF4D96FF);

  // Dark mode
  static const backgroundDark = Color(0xFF1A1A2E);
  static const surfaceDark = Color(0xFF16213E);
  static const textPrimaryDark = Color(0xFFF5F5F5);
  static const textSecondaryDark = Color(0xFFB0B0C0);
}

// ---------------------------------------------------------------------------
// SPACING
// ---------------------------------------------------------------------------

abstract class AkeliSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// ---------------------------------------------------------------------------
// BORDER RADIUS
// ---------------------------------------------------------------------------

abstract class AkeliRadius {
  static const double sm = 8.0;
  static const double md = 14.0;
  static const double lg = 20.0;
  static const double xl = 28.0;
  static const double pill = 999.0;
  static const double full = 100.0;  // kept for backward compat
}

// ---------------------------------------------------------------------------
// SHADOWS
// ---------------------------------------------------------------------------

abstract class AkeliShadows {
  static const BoxShadow sm = BoxShadow(
      color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 1));
  static const BoxShadow md = BoxShadow(
      color: Color(0x17000000), blurRadius: 12, offset: Offset(0, 2));
  static const BoxShadow lg = BoxShadow(
      color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 4));
  static const BoxShadow green = BoxShadow(
      color: Color(0x593BB78F), blurRadius: 16, offset: Offset(0, 4));
}

// ---------------------------------------------------------------------------
// ELEVATION
// ---------------------------------------------------------------------------

abstract class AkeliElevation {
  static const double none = 0;
  static const double low = 2;
  static const double medium = 4;
  static const double high = 8;
}

// ---------------------------------------------------------------------------
// THEME BUILDER
// ---------------------------------------------------------------------------

ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AkeliColors.primary,
    primary: AkeliColors.primary,
    secondary: AkeliColors.secondary,
    tertiary: AkeliColors.tertiary,
    background: AkeliColors.background,
    surface: AkeliColors.surface,
    error: AkeliColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: AkeliColors.textPrimary,
    onSurface: AkeliColors.textPrimary,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AkeliColors.background,
    textTheme: _buildTextTheme(AkeliColors.textPrimary),
    appBarTheme: AppBarTheme(
      backgroundColor: AkeliColors.background,
      foregroundColor: AkeliColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AkeliColors.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: AkeliColors.surface,
      elevation: AkeliElevation.low,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AkeliRadius.md),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AkeliColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkeliRadius.full),
        ),
        textStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AkeliColors.primary,
        side: const BorderSide(color: AkeliColors.primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkeliRadius.full),
        ),
        textStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AkeliColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AkeliSpacing.md,
        vertical: AkeliSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AkeliRadius.md),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AkeliRadius.md),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AkeliRadius.md),
        borderSide: const BorderSide(color: AkeliColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AkeliRadius.md),
        borderSide: const BorderSide(color: AkeliColors.error),
      ),
      labelStyle: GoogleFonts.nunito(color: AkeliColors.textSecondary),
      hintStyle: GoogleFonts.nunito(color: AkeliColors.textSecondary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AkeliColors.surface,
      selectedItemColor: AkeliColors.primary,
      unselectedItemColor: AkeliColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: AkeliElevation.high,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AkeliColors.background,
      selectedColor: AkeliColors.primary.withOpacity(0.15),
      labelStyle: GoogleFonts.nunito(fontSize: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AkeliRadius.full),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE5E5E5),
      thickness: 1,
      space: 0,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AkeliColors.primary,
    ),
  );
}

ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AkeliColors.primary,
    primary: AkeliColors.primary,
    secondary: AkeliColors.secondary,
    background: AkeliColors.backgroundDark,
    surface: AkeliColors.surfaceDark,
    error: AkeliColors.error,
    onPrimary: Colors.white,
    onBackground: AkeliColors.textPrimaryDark,
    onSurface: AkeliColors.textPrimaryDark,
    brightness: Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AkeliColors.backgroundDark,
    textTheme: _buildTextTheme(AkeliColors.textPrimaryDark),
    appBarTheme: AppBarTheme(
      backgroundColor: AkeliColors.backgroundDark,
      foregroundColor: AkeliColors.textPrimaryDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AkeliColors.textPrimaryDark,
      ),
    ),
    cardTheme: CardThemeData(
      color: AkeliColors.surfaceDark,
      elevation: AkeliElevation.low,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AkeliRadius.md),
      ),
      margin: EdgeInsets.zero,
    ),
  );
}

TextTheme _buildTextTheme(Color baseColor) => TextTheme(
      // Display — Nunito
      displayLarge: GoogleFonts.nunito(
          fontSize: 28, fontWeight: FontWeight.w800, color: baseColor),
      displayMedium: GoogleFonts.nunito(
          fontSize: 22, fontWeight: FontWeight.w700, color: baseColor),
      displaySmall: GoogleFonts.nunito(
          fontSize: 18, fontWeight: FontWeight.w700, color: baseColor),
      // Headlines — Nunito
      headlineLarge: GoogleFonts.nunito(
          fontSize: 32, fontWeight: FontWeight.w700, color: baseColor),
      headlineMedium: GoogleFonts.nunito(
          fontSize: 18, fontWeight: FontWeight.w700, color: baseColor),
      headlineSmall: GoogleFonts.nunito(
          fontSize: 16, fontWeight: FontWeight.w600, color: baseColor),
      // Titles
      titleLarge: GoogleFonts.nunito(
          fontSize: 22, fontWeight: FontWeight.w700, color: baseColor),
      titleMedium: GoogleFonts.nunito(
          fontSize: 16, fontWeight: FontWeight.w500, color: baseColor),
      titleSmall: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w500, color: baseColor),
      // Body — Nunito
      bodyLarge: GoogleFonts.nunito(
          fontSize: 16, fontWeight: FontWeight.w400, color: baseColor),
      bodyMedium: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w400, color: baseColor),
      bodySmall: GoogleFonts.nunito(
          fontSize: 13, fontWeight: FontWeight.w400, color: baseColor),
      // Labels
      labelLarge: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w600, color: baseColor),
      labelMedium: GoogleFonts.nunito(
          fontSize: 12, fontWeight: FontWeight.w600, color: baseColor),
      labelSmall: GoogleFonts.nunito(
          fontSize: 11, fontWeight: FontWeight.w600, color: baseColor),
    );
