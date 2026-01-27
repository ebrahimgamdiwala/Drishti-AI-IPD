/// Drishti App - Microphone State Indicator Widget
///
/// Visual state indicator for the microphone controller.
/// Displays the current state with color-coded animations for sighted assistants.
///
/// Requirements: 2.6 - Visual indicator showing current state for sighted assistants
library;

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';
import '../../../data/models/voice_navigation/microphone_state.dart';

/// Visual indicator widget for microphone state
///
/// This widget provides a visual representation of the microphone state
/// for sighted assistants. It uses distinct colors and animations for each state:
/// - Idle: Blue, static
/// - Listening: Green, pulsing animation
/// - Processing: Orange, rotating animation
/// - Speaking: Purple, wave animation
class MicrophoneStateIndicator extends StatefulWidget {
  /// The current microphone state to display
  final MicrophoneState state;

  /// Size of the indicator widget
  final double size;

  /// Whether to show the state label below the indicator
  final bool showLabel;

  /// Callback when the indicator is tapped
  final VoidCallback? onTap;

  const MicrophoneStateIndicator({
    super.key,
    required this.state,
    this.size = 80.0,
    this.showLabel = true,
    this.onTap,
  });

  @override
  State<MicrophoneStateIndicator> createState() =>
      _MicrophoneStateIndicatorState();
}

class _MicrophoneStateIndicatorState extends State<MicrophoneStateIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _getAnimationDuration(),
    );
    _startAnimation();
  }

  @override
  void didUpdateWidget(MicrophoneStateIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _animationController.duration = _getAnimationDuration();
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Get animation duration based on state
  Duration _getAnimationDuration() {
    switch (widget.state) {
      case MicrophoneState.idle:
        return const Duration(milliseconds: 0); // No animation
      case MicrophoneState.listening:
        return const Duration(milliseconds: 1500); // Slow pulse
      case MicrophoneState.processing:
        return const Duration(milliseconds: 1000); // Medium rotation
      case MicrophoneState.speaking:
        return const Duration(milliseconds: 800); // Fast wave
    }
  }

  /// Start animation based on state
  void _startAnimation() {
    _animationController.reset();
    if (widget.state != MicrophoneState.idle) {
      _animationController.repeat();
    }
  }

  /// Get color based on state
  Color _getStateColor() {
    switch (widget.state) {
      case MicrophoneState.idle:
        return AppColors.primaryBlue; // Blue for idle
      case MicrophoneState.listening:
        return AppColors.success; // Green for listening
      case MicrophoneState.processing:
        return AppColors.warning; // Orange for processing
      case MicrophoneState.speaking:
        return AppColors.gradientAccent; // Purple for speaking
    }
  }

  /// Get icon based on state
  IconData _getStateIcon() {
    switch (widget.state) {
      case MicrophoneState.idle:
        return Icons.mic_none_rounded;
      case MicrophoneState.listening:
        return Icons.mic_rounded;
      case MicrophoneState.processing:
        return Icons.sync_rounded;
      case MicrophoneState.speaking:
        return Icons.volume_up_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      label: 'Microphone ${widget.state.displayName}',
      hint: widget.state.description,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main indicator with animation
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return _buildAnimatedIndicator(isDark);
              },
            ),

            // State label (optional)
            if (widget.showLabel) ...[
              const SizedBox(height: 12),
              Text(
                widget.state.displayName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _getStateColor(),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build the animated indicator based on current state
  Widget _buildAnimatedIndicator(bool isDark) {
    switch (widget.state) {
      case MicrophoneState.idle:
        return _buildIdleIndicator(isDark);
      case MicrophoneState.listening:
        return _buildListeningIndicator(isDark);
      case MicrophoneState.processing:
        return _buildProcessingIndicator(isDark);
      case MicrophoneState.speaking:
        return _buildSpeakingIndicator(isDark);
    }
  }

  /// Build idle state indicator (static)
  Widget _buildIdleIndicator(bool isDark) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            _getStateColor(),
            _getStateColor().withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStateColor().withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.glassDarkBorder : AppColors.glassBorder,
          width: 2,
        ),
      ),
      child: Icon(
        _getStateIcon(),
        color: Colors.white,
        size: widget.size * 0.5,
      ),
    );
  }

  /// Build listening state indicator (pulsing animation)
  Widget _buildListeningIndicator(bool isDark) {
    final scale = 1.0 + (math.sin(_animationController.value * 2 * math.pi) * 0.1);
    final opacity = 0.3 + (math.sin(_animationController.value * 2 * math.pi) * 0.2);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulsing ring
        Container(
          width: widget.size * scale,
          height: widget.size * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStateColor().withValues(alpha: opacity),
          ),
        ),
        // Inner solid circle
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                _getStateColor(),
                _getStateColor().withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _getStateColor().withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark ? AppColors.glassDarkBorder : AppColors.glassBorder,
              width: 2,
            ),
          ),
          child: Icon(
            _getStateIcon(),
            color: Colors.white,
            size: widget.size * 0.5,
          ),
        ),
      ],
    );
  }

  /// Build processing state indicator (rotating animation)
  Widget _buildProcessingIndicator(bool isDark) {
    return Transform.rotate(
      angle: _animationController.value * 2 * math.pi,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              _getStateColor(),
              _getStateColor().withValues(alpha: 0.5),
              _getStateColor(),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: _getStateColor().withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? AppColors.glassDarkBorder : AppColors.glassBorder,
            width: 2,
          ),
        ),
        child: Transform.rotate(
          angle: -_animationController.value * 2 * math.pi,
          child: Icon(
            _getStateIcon(),
            color: Colors.white,
            size: widget.size * 0.5,
          ),
        ),
      ),
    );
  }

  /// Build speaking state indicator (wave animation)
  Widget _buildSpeakingIndicator(bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated wave bars
        ...List.generate(3, (index) {
          final offset = index * 0.33;
          final height = 0.3 +
              (math.sin((_animationController.value + offset) * 2 * math.pi) *
                  0.2);
          return Positioned(
            left: widget.size * 0.25 + (index * widget.size * 0.15),
            child: Container(
              width: 4,
              height: widget.size * height,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        // Main circle
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                _getStateColor(),
                _getStateColor().withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _getStateColor().withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark ? AppColors.glassDarkBorder : AppColors.glassBorder,
              width: 2,
            ),
          ),
          child: Icon(
            _getStateIcon(),
            color: Colors.white,
            size: widget.size * 0.5,
          ),
        ),
      ],
    );
  }
}
