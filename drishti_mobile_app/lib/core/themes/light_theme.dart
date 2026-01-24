/// Drishti App - Light Theme
///
/// iOS-inspired glassmorphism light theme.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  // Color Scheme - iOS style
  colorScheme: const ColorScheme.light(
    primary: AppColors.primaryBlue,
    onPrimary: Colors.white,
    secondary: AppColors.primaryBlueLight,
    onSecondary: Colors.white,
    surface: AppColors.lightSurface,
    onSurface: AppColors.textPrimaryLight,
    error: AppColors.error,
    onError: Colors.white,
    surfaceContainerHighest: AppColors.glassWhite,
  ),

  // Scaffold - Gradient background
  scaffoldBackgroundColor: Colors.transparent,

  // App Bar - Glassmorphism
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.textPrimaryLight,
    elevation: 0,
    centerTitle: true,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryBlue,
      letterSpacing: 0.5,
    ),
    iconTheme: const IconThemeData(color: AppColors.primaryBlue, size: 24),
  ),

  // Text Theme - SF Pro inspired
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 34,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryLight,
      letterSpacing: 0.4,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryLight,
      letterSpacing: 0.4,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryLight,
      letterSpacing: 0.4,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryLight,
      letterSpacing: 0.4,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryLight,
      letterSpacing: 0.4,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryLight,
      letterSpacing: 0.4,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimaryLight,
      letterSpacing: 0.2,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 17,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimaryLight,
      letterSpacing: 0.2,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondaryLight,
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
    color: AppColors.glassWhite,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      side: BorderSide(color: AppColors.glassBorder, width: 1.5),
    ),
  ),

  // Elevated Button - iOS style
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
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
    fillColor: AppColors.glassLight,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      borderSide: BorderSide(color: AppColors.glassBorder, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      borderSide: BorderSide(color: AppColors.glassBorder, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    hintStyle: GoogleFonts.inter(
      fontSize: 15,
      color: AppColors.textSecondaryLight,
      letterSpacing: 0.2,
    ),
  ),

  // Bottom Navigation - Glassmorphism
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.glassWhite,
    selectedItemColor: AppColors.primaryBlue,
    unselectedItemColor: AppColors.textSecondaryLight,
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
    backgroundColor: AppColors.primaryBlue,
    foregroundColor: Colors.white,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),

  // Divider
  dividerTheme: const DividerThemeData(
    color: AppColors.lightBorder,
    thickness: 0.5,
    space: 1,
  ),

  // Switch - iOS style
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.white;
      }
      return Colors.white;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primaryBlue;
      }
      return AppColors.textSecondaryLight.withValues(alpha: 0.3);
    }),
  ),

  // Dialog - Glassmorphism
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.glassWhite,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusLarge),
      side: BorderSide(color: AppColors.glassBorder, width: 1.5),
    ),
  ),

  // Snackbar
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.textPrimaryLight,
    contentTextStyle: GoogleFonts.inter(fontSize: 15, color: Colors.white),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
    ),
    behavior: SnackBarBehavior.floating,
  ),
);
