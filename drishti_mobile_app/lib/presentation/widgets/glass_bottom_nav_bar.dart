/// Drishti App - Glass Bottom Navigation Bar
///
/// iOS-style glassmorphism bottom navigation.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.glassDarkSurface : AppColors.glassWhite,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppColors.glassDarkBorder
                    : AppColors.glassBorder,
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            items: items,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primaryBlue,
            unselectedItemColor: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            showSelectedLabels: true,
            showUnselectedLabels: true,
          ),
        ),
      ),
    );
  }
}
