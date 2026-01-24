/// Drishti App - Gradient Background Wrapper
///
/// Wrapper widget for gradient background with glassmorphism support.
library;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              colors ??
              (isDark
                  ? [
                      AppColors.darkBackgroundGradientStart,
                      AppColors.darkBackgroundGradientEnd,
                    ]
                  : [
                      AppColors.lightBackgroundGradientStart,
                      AppColors.lightBackgroundGradientEnd,
                    ]),
          begin: begin,
          end: end,
        ),
      ),
      child: child,
    );
  }
}
