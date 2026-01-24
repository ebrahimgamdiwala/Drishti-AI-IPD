/// Drishti App - Custom Text Field
///
/// Styled text input field matching UI design.
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool enabled;
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        // Input field
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          enabled: enabled,
          focusNode: focusNode,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: AppColors.primaryBlue.withValues(alpha: 0.7),
                    size: 22,
                  )
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark
                ? AppColors.darkInputFill
                : AppColors.lightInputFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
