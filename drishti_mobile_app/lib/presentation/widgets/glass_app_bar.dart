/// Drishti App - Glass App Bar Widget
///
/// Glassmorphism app bar for modern iOS-style UI.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.elevation = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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
              bottom: BorderSide(
                color: isDark
                    ? AppColors.glassDarkBorder
                    : AppColors.glassBorder,
                width: 1,
              ),
            ),
          ),
          child: AppBar(
            title: Text(title),
            centerTitle: centerTitle,
            leading: leading,
            actions: actions,
            backgroundColor: Colors.transparent,
            elevation: elevation,
          ),
        ),
      ),
    );
  }
}
