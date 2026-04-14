import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Proper Level — Design tokens
// Aesthetic: Apple Measure × Carrot Weather. Confident, sparse, characterful.

class AppColors {
  AppColors._();

  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const surfaceElevated = Color(0xFF1C1C1C);
  static const border = Color(0xFF1E1F22);

  // State colors — the ONLY yellow in the UI
  static const levelAchieved = Color(0xFFFFD60A); // Proper yellow — "on the level"
  static const nearLevel = Color(0xFFEAEAEA);     // near-white — almost there
  static const offLevel = Color(0xFF7A7C80);       // muted gray — off

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8A8F98);
  static const textMuted = Color(0xFF4A4D55);

  // Toolbar icon active
  static const iconActive = levelAchieved;
  static const iconInactive = Color(0xFF4A4D55);
}

class AppTextStyles {
  AppTextStyles._();

  // Angle readout — monospaced, tabular numerals
  static TextStyle readout({double fontSize = 72, Color? color}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
        height: 1.0,
      );

  // Small readout (secondary values)
  static TextStyle readoutSmall({double fontSize = 24, Color? color}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
        fontFeatures: const [FontFeature.tabularFigures()],
        height: 1.0,
      );

  // Status label (LEVEL / NEAR / OFF)
  static TextStyle statusLabel({Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.5,
        color: color ?? AppColors.textSecondary,
      );

  // UI label
  static TextStyle label({double fontSize = 14, Color? color}) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
      );

  // Section header
  static TextStyle sectionHeader() => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: AppColors.textMuted,
      );
}

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.levelAchieved,
      onPrimary: AppColors.background,
      onSurface: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.levelAchieved,
      unselectedItemColor: AppColors.iconInactive,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 0,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.levelAchieved,
      thumbColor: AppColors.levelAchieved,
      inactiveTrackColor: AppColors.border,
      overlayColor: Color(0x22FFD60A),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.levelAchieved
            : AppColors.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0x44FFD60A)
            : AppColors.border,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.levelAchieved,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
    useMaterial3: true,
  );
}
