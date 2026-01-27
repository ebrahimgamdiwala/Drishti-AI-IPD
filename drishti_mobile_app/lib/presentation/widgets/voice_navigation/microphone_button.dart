/// Drishti App - Microphone Button Widget
///
/// Interactive microphone button with visual state indicator.
/// Allows users to tap to start/stop voice input.
///
/// Requirements: 2.2, 2.6 - Microphone button with state visualization
library;

import 'package:flutter/material.dart';
import '../../../data/models/voice_navigation/microphone_state.dart';
import 'microphone_state_indicator.dart';

/// Interactive microphone button with state visualization
///
/// This button combines the visual state indicator with tap functionality
/// to control voice input. It provides:
/// - Visual feedback for current microphone state
/// - Tap to start/stop listening
/// - Accessibility support with semantic labels
/// - Minimum 48x48 dp touch target (Requirement 14.5)
class MicrophoneButton extends StatelessWidget {
  /// The current microphone state
  final MicrophoneState state;

  /// Callback when the button is tapped
  final VoidCallback? onTap;

  /// Size of the button
  final double size;

  /// Whether to show the state label
  final bool showLabel;

  /// Whether the button is enabled
  final bool enabled;

  const MicrophoneButton({
    super.key,
    required this.state,
    this.onTap,
    this.size = 80.0,
    this.showLabel = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure minimum touch target size of 48x48 dp (Requirement 14.5)
    final touchTargetSize = size < 48.0 ? 48.0 : size;
    // Calculate total height including label space (need more space for text)
    final totalHeight = touchTargetSize + (showLabel ? 52 : 0);

    return Semantics(
      button: true,
      enabled: enabled && onTap != null,
      label: _getSemanticLabel(),
      hint: _getSemanticHint(),
      child: SizedBox(
        width: touchTargetSize,
        height: totalHeight,
        child: Center(
          child: MicrophoneStateIndicator(
            state: state,
            size: size,
            showLabel: showLabel,
            onTap: enabled ? onTap : null,
          ),
        ),
      ),
    );
  }

  /// Get semantic label for accessibility
  String _getSemanticLabel() {
    if (!enabled) {
      return 'Microphone disabled';
    }

    switch (state) {
      case MicrophoneState.idle:
        return 'Tap to start voice input';
      case MicrophoneState.listening:
        return 'Listening to your voice';
      case MicrophoneState.processing:
        return 'Processing your command';
      case MicrophoneState.speaking:
        return 'Speaking response';
    }
  }

  /// Get semantic hint for accessibility
  String _getSemanticHint() {
    if (!enabled) {
      return 'Microphone is currently disabled';
    }

    switch (state) {
      case MicrophoneState.idle:
        return 'Double tap to activate voice input';
      case MicrophoneState.listening:
        return 'Speak your command now';
      case MicrophoneState.processing:
        return 'Please wait while we process your command';
      case MicrophoneState.speaking:
        return 'Listen to the response';
    }
  }
}

/// Floating microphone button for overlay usage
///
/// This variant is designed to float over content, typically used
/// as a persistent voice input control across screens.
class FloatingMicrophoneButton extends StatelessWidget {
  /// The current microphone state
  final MicrophoneState state;

  /// Callback when the button is tapped
  final VoidCallback? onTap;

  /// Size of the button
  final double size;

  /// Whether the button is enabled
  final bool enabled;

  const FloatingMicrophoneButton({
    super.key,
    required this.state,
    this.onTap,
    this.size = 64.0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: enabled ? onTap : null,
      elevation: 8,
      child: MicrophoneStateIndicator(
        state: state,
        size: size * 0.6,
        showLabel: false,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}

/// Compact microphone button for app bar usage
///
/// This variant is designed for use in app bars and toolbars,
/// with a smaller size and no label.
class CompactMicrophoneButton extends StatelessWidget {
  /// The current microphone state
  final MicrophoneState state;

  /// Callback when the button is tapped
  final VoidCallback? onTap;

  /// Whether the button is enabled
  final bool enabled;

  const CompactMicrophoneButton({
    super.key,
    required this.state,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: MicrophoneStateIndicator(
        state: state,
        size: 32.0,
        showLabel: false,
        onTap: enabled ? onTap : null,
      ),
      tooltip: _getTooltip(),
    );
  }

  /// Get tooltip text based on state
  String _getTooltip() {
    if (!enabled) {
      return 'Microphone disabled';
    }

    switch (state) {
      case MicrophoneState.idle:
        return 'Start voice input';
      case MicrophoneState.listening:
        return 'Listening...';
      case MicrophoneState.processing:
        return 'Processing...';
      case MicrophoneState.speaking:
        return 'Speaking...';
    }
  }
}
