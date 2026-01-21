/// Drishti App - Color Constants
/// 
/// Blue/white theme inspired by UI reference images.
/// Supports both light and dark modes.
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Blue Shades
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryBlueDark = Color(0xFF2563EB);
  static const Color primaryBlueLight = Color(0xFF60A5FA);
  
  // Gradient Colors
  static const Color gradientStart = Color(0xFF06B6D4); // Cyan
  static const Color gradientEnd = Color(0xFF6366F1);   // Indigo
  
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF0F4FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightInputFill = Color(0xFFF1F5F9);
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkInputFill = Color(0xFF1E293B);
  
  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1E293B);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Severity Colors (for alerts)
  static const Color severityCritical = Color(0xFFEF4444);
  static const Color severityHigh = Color(0xFFF97316);
  static const Color severityMedium = Color(0xFFF59E0B);
  static const Color severityLow = Color(0xFF10B981);
  
  // Primary Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Card Gradient (subtle)
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFE0E7FF), Color(0xFFF0F4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
