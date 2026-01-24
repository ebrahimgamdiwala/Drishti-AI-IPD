/// Drishti App - Dark Theme
///
/// iOS-inspired glassmorphism dark theme.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  // Color Scheme - iOS style
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primaryBlueLight,
    onPrimary: Colors.black,
    secondary: AppColors.primaryBlue,
    onSecondary: Colors.white,
    surface: AppColors.darkSurface,
    onSurface: AppColors.textPrimaryDark,
    error: AppColors.error,
    onError: Colors.white,
    surfaceContainerHighest: AppColors.glassDarkSurface,
  ),

  // Scaffold - Gradient background
  scaffoldBackgroundColor: Colors.transparent,

  // App Bar - Glassmorphism
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.textPrimaryDark,
    elevation: 0,
    centerTitle: true,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryBlueLight,
      letterSpacing: 0.5,
    ),
    iconTheme: const IconThemeData(color: AppColors.primaryBlueLight, size: 24),
  ),

  // Text Theme - SF Pro inspired
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 34,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryDark,
      letterSpacing: 0.4,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryDark,
      letterSpacing: 0.4,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryDark,
      letterSpacing: 0.4,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryDark,
      letterSpacing: 0.4,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryDark,
      letterSpacing: 0.4,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryDark,
      letterSpacing: 0.4,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimaryDark,
      letterSpacing: 0.2,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 17,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimaryDark,
      letterSpacing: 0.2,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondaryDark,
      letterSpacing: 0.2,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.4,
    ),
  ),

  // Card Theme - Glassmorphism
  cardTheme: CardThemeData(
    color: AppColors.glassDarkSurface,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      side: BorderSide(color: AppColors.glassDarkBorder, width: 1.5),
    ),
  ),

  // Elevated Button - iOS style
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryBlueLight,
      foregroundColor: Colors.black,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    ),
  ),

  // Input Decoration - Glassmorphism
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.glassDarkSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      borderSide: BorderSide(color: AppColors.glassDarkBorder, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      borderSide: BorderSide(color: AppColors.glassDarkBorder, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      borderSide: const BorderSide(color: AppColors.primaryBlueLight, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    hintStyle: GoogleFonts.inter(
      fontSize: 15,
      color: AppColors.textSecondaryDark,
      letterSpacing: 0.2,
    ),
  ),

  // Bottom Navigation - Glassmorphism
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.glassDarkSurface,
    selectedItemColor: AppColors.primaryBlueLight,
    unselectedItemColor: AppColors.textSecondaryDark,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    selectedLabelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
    unselectedLabelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
    ),
  ),

  // Floating Action Button - iOS style
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryBlueLight,
    foregroundColor: Colors.black,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),

  // Divider
  dividerTheme: const DividerThemeData(
    color: AppColors.darkBorder,
    thickness: 0.5,
    space: 1,
  ),

  // Switch - iOS style
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      return Colors.white;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primaryBlueLight;
      }
      return AppColors.textSecondaryDark.withValues(alpha: 0.3);
    }),
  ),

  // Dialog - Glassmorphism
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.glassDarkSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusLarge),
      side: BorderSide(color: AppColors.glassDarkBorder, width: 1.5),
    ),
  ),

  // Snackbar
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.textPrimaryDark,
    contentTextStyle: GoogleFonts.inter(fontSize: 15, color: Colors.black),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
    ),
    behavior: SnackBarBehavior.floating,
  ),
);
