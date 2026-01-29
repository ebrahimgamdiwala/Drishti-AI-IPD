/// Microphone Controller
///
/// Manages microphone states and transitions for voice input.
/// Handles the four-state machine: Idle → Listening → Processing → Speaking
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../models/voice_navigation/microphone_state.dart';
import '../voice_service.dart';

/// Controller for microphone state management
///
/// This controller manages the microphone state machine and provides
/// audio cues and haptic feedback for state transitions.
class MicrophoneController extends ChangeNotifier {
  final VoiceService _voiceService;

  MicrophoneState _state = MicrophoneState.idle;

  MicrophoneController({required VoiceService voiceService})
    : _voiceService = voiceService;

  /// Get the current microphone state
  MicrophoneState get state => _state;

  /// Whether the microphone is currently listening
  bool get isListening => _state == MicrophoneState.listening;

  /// Start listening for voice input
  ///
  /// Transitions from idle to listening state and begins recording.
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onError,
  }) async {
    debugPrint(
      '[MicController] startListening called, current state: ${_state.name}',
    );

    if (_state != MicrophoneState.idle) {
      debugPrint(
        '[MicController] Cannot start listening from state: ${_state.name}',
      );
      debugPrint('[MicController] Waiting for idle state...');

      // Wait a bit and try again
      await Future.delayed(const Duration(milliseconds: 500));

      if (_state != MicrophoneState.idle) {
        debugPrint('[MicController] Still not idle, aborting');
        onError?.call('Microphone is busy');
        return;
      }
    }

    // Check if STT is available
    if (!_voiceService.isSttAvailable) {
      debugPrint(
        '[MicController] STT not available - attempting to initialize',
      );
      final initialized = await _voiceService.initStt();
      if (!initialized) {
        onError?.call('Speech recognition not available on this device');
        return;
      }
    }

    debugPrint('[MicController] Transitioning to listening state');
    await _transitionTo(MicrophoneState.listening);

    try {
      debugPrint('[MicController] Starting voice service listening');
      await _voiceService.startListening(
        onResult: (text) {
          debugPrint('[MicController] Got result: $text');
          onResult(text);
          setIdle();
        },
        onError: (error) {
          debugPrint('[MicController] Got error: $error');
          onError?.call(error);
          setIdle();
        },
        listenFor: const Duration(seconds: 30), // Longer timeout for better UX
      );
      debugPrint(
        '[MicController] Voice service listening started successfully',
      );
    } catch (e) {
      debugPrint('[MicController] Failed to start listening: $e');
      onError?.call('Failed to start listening');
      await setIdle();
    }
  }

  /// Stop listening
  ///
  /// Stops recording and transitions back to idle.
  Future<void> stopListening() async {
    if (_state != MicrophoneState.listening) {
      return;
    }

    await _voiceService.stopListening();
    await setIdle();
  }

  /// Transition to processing state
  ///
  /// Called when a command is being analyzed.
  Future<void> setProcessing() async {
    await _transitionTo(MicrophoneState.processing);
  }

  /// Transition to speaking state
  ///
  /// Called when audio feedback is being provided.
  Future<void> setSpeaking() async {
    await _transitionTo(MicrophoneState.speaking);
  }

  /// Return to idle state
  ///
  /// Called when all processing is complete.
  Future<void> setIdle() async {
    await _transitionTo(MicrophoneState.idle);
  }

  /// Transition to a new state with audio cue and haptic feedback
  Future<void> _transitionTo(MicrophoneState newState) async {
    if (_state == newState) return;

    final oldState = _state;
    _state = newState;

    debugPrint(
      '[MicController] State transition: ${oldState.name} → ${newState.name}',
    );

    // Provide haptic feedback if needed
    if (newState.shouldProvideHaptic) {
      await _provideHapticFeedback();
    }

    // Provide audio cue if needed
    if (newState.audioCue.isNotEmpty) {
      await _provideAudioCue(newState.audioCue);
    }

    notifyListeners();
  }

  /// Provide haptic feedback for state change
  Future<void> _provideHapticFeedback() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('[MicController] Haptic feedback failed: $e');
    }
  }

  /// Provide audio cue for state change
  Future<void> _provideAudioCue(String cue) async {
    if (cue.isEmpty) return;

    try {
      // Use TTS to provide audio cue
      // These are short, distinct cues that won't interrupt main responses
      await _voiceService.speak(cue);
    } catch (e) {
      debugPrint('[MicController] Audio cue failed: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('[MicController] Microphone controller disposed');
    super.dispose();
  }
}
