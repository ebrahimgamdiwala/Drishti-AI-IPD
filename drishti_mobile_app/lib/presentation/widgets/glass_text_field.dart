/// Drishti App - Glass Text Field Widget
///
/// iOS-style glassmorphism input field.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GlassTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final int? maxLines;
  final bool enabled;

  const GlassTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: _isFocused
                    ? AppColors.primaryBlue.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: _isFocused ? 15 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.radiusMedium),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.glassDarkSurface
                      : AppColors.glassLight,
                  borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                  border: Border.all(
                    color: _isFocused
                        ? AppColors.primaryBlue.withValues(alpha: 0.5)
                        : (isDark
                              ? AppColors.glassDarkBorder
                              : AppColors.glassBorder),
                    width: _isFocused ? 2 : 1.5,
                  ),
                ),
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  validator: widget.validator,
                  onChanged: widget.onChanged,
                  maxLines: widget.maxLines,
                  enabled: widget.enabled,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    prefixIcon: widget.prefixIcon != null
                        ? Icon(
                            widget.prefixIcon,
                            color: _isFocused
                                ? AppColors.primaryBlue
                                : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                          )
                        : null,
                    suffixIcon: widget.suffixIcon != null
                        ? IconButton(
                            icon: Icon(
                              widget.suffixIcon,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            onPressed: widget.onSuffixIconTap,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
