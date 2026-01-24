/// Drishti App - Color Constants
///
/// iOS-inspired glassmorphism theme with modern aesthetics.
/// Supports both light and dark modes with glass effects.
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Blue Shades - iOS style
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color primaryBlueDark = Color(0xFF0051D5);
  static const Color primaryBlueLight = Color(0xFF5AC8FA);

  // Gradient Colors - Modern glassmorphism
  static const Color gradientStart = Color(0xFF00C6FF); // Bright cyan
  static const Color gradientEnd = Color(0xFF0072FF); // Deep blue
  static const Color gradientAccent = Color(0xFF8E2DE2); // Purple accent

  // Light Theme Colors - Glassmorphism
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightBackgroundGradientStart = Color(0xFFE0E7FF);
  static const Color lightBackgroundGradientEnd = Color(0xFFFCE7F3);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightInputFill = Color(0xFFF1F5F9);

  // Glassmorphism Colors (with transparency)
  static const Color glassWhite = Color(0x40FFFFFF);
  static const Color glassLight = Color(0x30FFFFFF);
  static const Color glassMedium = Color(0x20FFFFFF);
  static const Color glassDark = Color(0x15000000);
  static const Color glassBorder = Color(0x30FFFFFF);

  // Dark Theme Colors - Glassmorphism
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkBackgroundGradientStart = Color(0xFF0F172A);
  static const Color darkBackgroundGradientEnd = Color(0xFF1E1B4B);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkInputFill = Color(0xFF1E293B);

  // Dark Glassmorphism Colors
  static const Color glassBlack = Color(0x40000000);
  static const Color glassDarkSurface = Color(0x20FFFFFF);
  static const Color glassDarkBorder = Color(0x20FFFFFF);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1E293B);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Status Colors - iOS style
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Severity Colors (for alerts)
  static const Color severityCritical = Color(0xFFFF3B30);
  static const Color severityHigh = Color(0xFFFF9500);
  static const Color severityMedium = Color(0xFFFFCC00);
  static const Color severityLow = Color(0xFF34C759);

  // Primary Gradient - Modern glass
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glass Gradient - Multi-color
  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF0072FF), Color(0xFF8E2DE2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background Gradient - Light
  static const LinearGradient backgroundGradientLight = LinearGradient(
    colors: [lightBackgroundGradientStart, lightBackgroundGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background Gradient - Dark
  static const LinearGradient backgroundGradientDark = LinearGradient(
    colors: [darkBackgroundGradientStart, darkBackgroundGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Card Gradient (subtle)
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFE0E7FF), Color(0xFFF0F4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Blur intensity for glassmorphism
  static const double blurLight = 10.0;
  static const double blurMedium = 20.0;
  static const double blurHeavy = 30.0;

  // Border radius constants
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 20.0;
  static const double radiusLarge = 30.0;
  static const double radiusXLarge = 40.0;
}
