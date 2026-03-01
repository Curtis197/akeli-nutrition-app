import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// DESIGN TOKENS — Akeli V1
// Ref: DESIGN_SYSTEM.md
// ---------------------------------------------------------------------------

abstract class AkeliColors {
  // Brand
  static const primary = Color(0xFF3BB78F);      // Teal — actions principales
  static const secondary = Color(0xFFFF9F1C);    // Orange — highlights
  static const tertiary = Color(0xFF9C88FF);     // Violet — accents

  // Backgrounds
  static const background = Color(0xFFF9F9E8);   // Crème — fond pages
  static const surface = Color(0xFFFFFFFF);      // Blanc — cards

  // Textes
  static const textPrimary = Color(0xFF2F2F2F);
  static const textSecondary = Color(0xFF5A5A5A);

  // Sémantiques
  static const success = Color(0xFF249689);
  static const warning = Color(0xFFF9CF58);
  static const error = Color(0xFFFF5963);
  static const info = Color(0xFF4D96FF);         // Fix: était #FFFFFF en MVP

  // Dark mode
  static const backgroundDark = Color(0xFF1A1A2E);
  static const surfaceDark = Color(0xFF16213E);
  static const textPrimaryDark = Color(0xFFF5F5F5);
  static const textSecondaryDark = Color(0xFFB0B0C0);
}

// ---------------------------------------------------------------------------
// SPACING — Grille 8px
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
  static const double md = 12.0;
  static const double lg = 20.0;
  static const double full = 100.0;
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
    useMaterial3: true,             // Material 3 activé (fix MVP)
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AkeliColors.background,
    textTheme: _buildTextTheme(AkeliColors.textPrimary),
    appBarTheme: AppBarTheme(
      backgroundColor: AkeliColors.background,
      foregroundColor: AkeliColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
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
        textStyle: GoogleFonts.poppins(
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
        textStyle: GoogleFonts.poppins(
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
      labelStyle: GoogleFonts.poppins(color: AkeliColors.textSecondary),
      hintStyle: GoogleFonts.poppins(color: AkeliColors.textSecondary),
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
      labelStyle: GoogleFonts.poppins(fontSize: 12),
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
      titleTextStyle: GoogleFonts.outfit(
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
      // Display — Outfit
      displayLarge: GoogleFonts.outfit(fontSize: 64, color: baseColor),
      displayMedium: GoogleFonts.outfit(fontSize: 44, color: baseColor),
      displaySmall: GoogleFonts.outfit(fontSize: 36, color: baseColor),
      // Headlines — Outfit
      headlineLarge: GoogleFonts.outfit(fontSize: 32, color: baseColor),
      headlineMedium: GoogleFonts.outfit(fontSize: 24, color: baseColor),
      headlineSmall: GoogleFonts.outfit(fontSize: 20, color: baseColor),
      // Titles
      titleLarge: GoogleFonts.outfit(fontSize: 22, color: baseColor),
      titleMedium: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w500, color: baseColor),
      titleSmall: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w500, color: baseColor),
      // Body — Poppins
      bodyLarge: GoogleFonts.poppins(fontSize: 16, color: baseColor),
      bodyMedium: GoogleFonts.poppins(fontSize: 14, color: baseColor),
      bodySmall: GoogleFonts.poppins(fontSize: 12, color: baseColor),
      // Labels
      labelLarge: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w500, color: baseColor),
      labelMedium: GoogleFonts.poppins(fontSize: 12, color: baseColor),
      labelSmall: GoogleFonts.poppins(
          fontSize: 11, fontWeight: FontWeight.w500, color: baseColor),
    );
