/// Drishti App - Glass Card Widget
///
/// Modern glassmorphism card with tap effects.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = AppColors.radiusMedium,
    this.onTap,
    this.color,
    this.gradient,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
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
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardContent = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              color:
                  widget.color ??
                  (isDark ? AppColors.glassDarkSurface : AppColors.glassWhite),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: isDark
                    ? AppColors.glassDarkBorder
                    : AppColors.glassBorder,
                width: 1.5,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onTap,
        child: ScaleTransition(scale: _scaleAnimation, child: cardContent),
      );
    }

    return cardContent;
  }
}
