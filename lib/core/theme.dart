import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// DESIGN TOKENS — Akeli V1
// Ref: DESIGN_SYSTEM.md
// ---------------------------------------------------------------------------

abstract class AkeliColors {
  // Brand - Digital Editorial System
  static const primary = Color(0xFF4DB6AC);      // Teal (Main)
  static const primaryContainer = Color(0xFF006A63); // Darker Teal
  static const secondary = Color(0xFFFF9F43);    // Orange (Alerts/Calories)
  static const accentPurple = Color(0xFFA18AFF);  // Title Purple
  static const tertiary = Color(0xFF8B7FD4);     // Violet (Fallback)

  // Surface Philosophy
  static const surface = Color(0xFFFFFFFF);             // Base Surface (Pure White)
  static const surfaceContainerLow = Color(0xFFF8F9FA); // Off-white Secondary
  static const surfaceContainerLowest = Color(0xFFFFFFFF); // Interactive Cards
  static const surfaceContainerHigh = Color(0xFFF1F3F5); // Higher Surface
  static const surfaceContainerHighest = Color(0xFFE9ECEF); // Highest Surface
  static const secondaryContainer = Color(0xFFC3EAE5);    // Light Teal/Secondary
  static const background = Color(0xFFFFFFFF);          // Same as surface

  // Text Roles
  static const onSurface = Color(0xFF1B1C16);           // Main Text
  static const onSurfaceVariant = Color(0xFF3D4947);    // Soft/Secondary Text
  static const outline = Color(0xFF6D7A77);             // Metadata Labels
  static const outlineVariant = Color(0xFFBDC9C6);      // Ghost Borders

  // Legacy (Keeping for compat with other features during transition)
  static const textPrimary = Color(0xFF1B1C16);
  static const textSecondary = Color(0xFF3D4947);
  static const textMuted = Color(0xFFC8C8C8);

  // Semantics
  static const success = Color(0xFF249689);
  static const warning = Color(0xFFF9CF58);
  static const error = Color(0xFFBA1A1A);
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
  static const double md = 12.0;
  static const double lg = 18.0;
  static const double xl = 24.0;
  static const double card = 24.0; // Alias for xl/card radius
  static const double m = 12.0;    // Alias for md/medium radius
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
    onPrimary: Colors.white,
    primaryContainer: AkeliColors.primaryContainer,
    onPrimaryContainer: Colors.white,
    secondary: AkeliColors.secondary,
    onSecondary: Colors.white,
    surface: AkeliColors.surface,
    onSurface: AkeliColors.onSurface,
    surfaceContainerLow: AkeliColors.surfaceContainerLow,
    surfaceContainerLowest: AkeliColors.surfaceContainerLowest,
    error: AkeliColors.error,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AkeliColors.background,
    textTheme: _buildTextTheme(AkeliColors.onSurface),
    appBarTheme: AppBarTheme(
      backgroundColor: AkeliColors.background.withValues(alpha: 0.7),
      foregroundColor: AkeliColors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AkeliColors.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: AkeliColors.surfaceContainerLowest,
      elevation: 0, // No harsh shadows
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AkeliRadius.xl), // Organic rounded corners
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AkeliColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkeliRadius.pill),
        ),
        textStyle: GoogleFonts.outfit(
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
          borderRadius: BorderRadius.circular(AkeliRadius.pill),
        ),
        textStyle: GoogleFonts.outfit(
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
      labelStyle: GoogleFonts.poppins(color: AkeliColors.onSurfaceVariant),
      hintStyle: GoogleFonts.poppins(color: AkeliColors.onSurfaceVariant),
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
      selectedColor: AkeliColors.primary.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.poppins(fontSize: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AkeliRadius.pill),
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
    surface: AkeliColors.surfaceDark,
    error: AkeliColors.error,
    onPrimary: Colors.white,
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
      displayLarge: GoogleFonts.outfit(
          fontSize: 32, fontWeight: FontWeight.w800, color: baseColor, letterSpacing: -0.02),
      displayMedium: GoogleFonts.outfit(
          fontSize: 24, fontWeight: FontWeight.w700, color: baseColor, letterSpacing: -0.01),
      displaySmall: GoogleFonts.outfit(
          fontSize: 20, fontWeight: FontWeight.w700, color: baseColor),
      // Headlines — Outfit
      headlineLarge: GoogleFonts.outfit(
          fontSize: 32, fontWeight: FontWeight.w700, color: baseColor),
      headlineMedium: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w700, color: baseColor),
      headlineSmall: GoogleFonts.outfit(
          fontSize: 16, fontWeight: FontWeight.w600, color: baseColor),
      // Titles — Outfit
      titleLarge: GoogleFonts.outfit(
          fontSize: 22, fontWeight: FontWeight.w700, color: baseColor),
      titleMedium: GoogleFonts.outfit(
          fontSize: 16, fontWeight: FontWeight.w500, color: baseColor),
      titleSmall: GoogleFonts.outfit(
          fontSize: 14, fontWeight: FontWeight.w500, color: baseColor),
      // Body — Poppins (Readability optimized)
      bodyLarge: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w400, color: AkeliColors.onSurfaceVariant),
      bodyMedium: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w400, color: AkeliColors.onSurfaceVariant),
      bodySmall: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w400, color: AkeliColors.onSurfaceVariant),
      // Labels — Poppins
      labelLarge: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600, color: AkeliColors.onSurfaceVariant),
      labelMedium: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w600, color: AkeliColors.onSurfaceVariant),
      labelSmall: GoogleFonts.poppins(
          fontSize: 11, fontWeight: FontWeight.w600, color: AkeliColors.onSurfaceVariant),
    );
