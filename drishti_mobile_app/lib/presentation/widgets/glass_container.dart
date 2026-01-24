/// Drishti App - Glass Container Widget
///
/// Reusable glassmorphism container with blur effect.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = AppColors.radiusMedium,
    this.blur = AppColors.blurMedium,
    this.color,
    this.borderColor,
    this.borderWidth = 1.5,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient,
              color:
                  color ??
                  (isDark ? AppColors.glassDarkSurface : AppColors.glassWhite),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color:
                    borderColor ??
                    (isDark
                        ? AppColors.glassDarkBorder
                        : AppColors.glassBorder),
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
