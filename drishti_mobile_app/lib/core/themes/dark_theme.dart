/// Drishti App - Dark Theme
/// 
/// Dark theme configuration with blue accents.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  
  // Color Scheme
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primaryBlueLight,
    onPrimary: Colors.white,
    secondary: AppColors.gradientEnd,
    onSecondary: Colors.white,
    surface: AppColors.darkSurface,
    onSurface: AppColors.textPrimaryDark,
    error: AppColors.error,
    onError: Colors.white,
  ),
  
  // Scaffold
  scaffoldBackgroundColor: AppColors.darkBackground,
  
  // App Bar
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.darkBackground,
    foregroundColor: AppColors.textPrimaryDark,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryBlueLight,
    ),
    iconTheme: const IconThemeData(
      color: AppColors.primaryBlueLight,
    ),
  ),
  
  // Text Theme
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryDark,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryDark,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryDark,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryDark,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryDark,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryDark,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimaryDark,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimaryDark,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondaryDark,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
  
  // Card Theme
  cardTheme: CardThemeData(
    color: AppColors.darkCard,
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  
  // Elevated Button
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryBlueLight,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  
  // Input Decoration
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkInputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryBlueLight, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error, width: 1),
    ),
    hintStyle: GoogleFonts.inter(
      fontSize: 14,
      color: AppColors.textSecondaryDark,
    ),
  ),
  
  // Bottom Navigation
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    selectedItemColor: AppColors.primaryBlueLight,
    unselectedItemColor: AppColors.textSecondaryDark,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  
  // Floating Action Button
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryBlueLight,
    foregroundColor: Colors.white,
    elevation: 4,
  ),
  
  // Divider
  dividerTheme: const DividerThemeData(
    color: AppColors.darkBorder,
    thickness: 1,
  ),
  
  // Switch
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primaryBlueLight;
      }
      return AppColors.textSecondaryDark;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primaryBlueLight.withOpacity(0.3);
      }
      return AppColors.darkBorder;
    }),
  ),
);
