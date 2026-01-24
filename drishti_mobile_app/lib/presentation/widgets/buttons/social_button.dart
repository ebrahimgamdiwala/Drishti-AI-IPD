/// Drishti App - Social Button
///
/// Circular social login button.
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;

  const SocialButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: 'Sign in with $label',
      child: Tooltip(
        message: 'Sign in with $label',
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: size * 0.5, color: AppColors.primaryBlue),
          ),
        ),
      ),
    );
  }
}
