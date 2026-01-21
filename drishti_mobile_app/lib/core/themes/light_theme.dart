/// Drishti App - Light Theme
/// 
/// Light theme configuration with blue accents.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  
  // Color Scheme
  colorScheme: const ColorScheme.light(
    primary: AppColors.primaryBlue,
    onPrimary: Colors.white,
    secondary: AppColors.gradientEnd,
    onSecondary: Colors.white,
    surface: AppColors.lightSurface,
    onSurface: AppColors.textPrimaryLight,
    error: AppColors.error,
    onError: Colors.white,
  ),
  
  // Scaffold
  scaffoldBackgroundColor: AppColors.lightBackground,
  
  // App Bar
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.lightBackground,
    foregroundColor: AppColors.textPrimaryLight,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryBlue,
    ),
    iconTheme: const IconThemeData(
      color: AppColors.primaryBlue,
    ),
  ),
  
  // Text Theme
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryLight,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryLight,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryLight,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryLight,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryLight,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryLight,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimaryLight,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimaryLight,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondaryLight,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
  
  // Card Theme
  cardTheme: CardThemeData(
    color: AppColors.lightCard,
    elevation: 4,
    shadowColor: AppColors.primaryBlue.withOpacity(0.1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  
  // Elevated Button
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryBlue,
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
    fillColor: AppColors.lightInputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error, width: 1),
    ),
    hintStyle: GoogleFonts.inter(
      fontSize: 14,
      color: AppColors.textSecondaryLight,
    ),
  ),
  
  // Bottom Navigation
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: AppColors.primaryBlue,
    unselectedItemColor: AppColors.textSecondaryLight,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  
  // Floating Action Button
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryBlue,
    foregroundColor: Colors.white,
    elevation: 4,
  ),
  
  // Divider
  dividerTheme: const DividerThemeData(
    color: AppColors.lightBorder,
    thickness: 1,
  ),
  
  // Switch
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primaryBlue;
      }
      return AppColors.textSecondaryLight;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primaryBlue.withOpacity(0.3);
      }
      return AppColors.lightBorder;
    }),
  ),
);
