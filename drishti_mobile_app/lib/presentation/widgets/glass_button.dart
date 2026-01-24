/// Drishti App - Glass Button Widget
///
/// iOS-style glassmorphism button with hover and press effects.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GlassButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final Color? color;
  final Color? textColor;
  final Gradient? gradient;
  final bool isLoading;
  final bool enabled;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.width,
    this.height = 56,
    this.borderRadius = AppColors.radiusMedium,
    this.color,
    this.textColor,
    this.gradient,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enabled && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enabled && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.enabled && !widget.isLoading ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.enabled
                    ? AppColors.primaryBlue.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: widget.gradient ?? AppColors.primaryGradient,
                  color: widget.color,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: widget.textColor ?? Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.text,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: widget.textColor ?? Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
