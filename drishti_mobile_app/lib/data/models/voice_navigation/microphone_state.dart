/// Microphone State Enumeration
///
/// Defines the four states of the microphone controller.
library;

/// The current state of the microphone
enum MicrophoneState {
  /// Ready to listen - waiting for user input
  idle,

  /// Actively recording voice input
  listening,

  /// Analyzing the recorded command
  processing,

  /// Providing audio response
  speaking,
}

/// Extension methods for MicrophoneState
extension MicrophoneStateExtension on MicrophoneState {
  /// Get the display name for this state
  String get displayName {
    switch (this) {
      case MicrophoneState.idle:
        return 'Idle';
      case MicrophoneState.listening:
        return 'Listening';
      case MicrophoneState.processing:
        return 'Processing';
      case MicrophoneState.speaking:
        return 'Speaking';
    }
  }

  /// Get a user-friendly description of this state
  String get description {
    switch (this) {
      case MicrophoneState.idle:
        return 'Ready to listen';
      case MicrophoneState.listening:
        return 'Listening to your command';
      case MicrophoneState.processing:
        return 'Processing your request';
      case MicrophoneState.speaking:
        return 'Speaking response';
    }
  }

  /// Get the audio cue text for transitioning to this state
  String get audioCue {
    switch (this) {
      case MicrophoneState.idle:
        return 'Ready';
      case MicrophoneState.listening:
        return 'Listening';
      case MicrophoneState.processing:
        return 'Processing';
      case MicrophoneState.speaking:
        return ''; // No cue when speaking (would interrupt the response)
    }
  }

  /// Whether haptic feedback should be provided for this state
  bool get shouldProvideHaptic {
    // Requirement 2.5: Provide haptic feedback for all state transitions
    return true;
  }
}
