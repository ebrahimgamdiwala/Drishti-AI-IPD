/// Voice Navigation Provider
///
/// Provider for the voice navigation controller, integrating with the app's
/// dependency injection system.
library;

import 'package:flutter/material.dart';
import '../services/voice_navigation/voice_navigation_controller.dart';
import '../services/voice_navigation/audio_feedback_engine.dart';
import '../services/local_vlm_service.dart';
import '../services/api_service.dart';
import '../models/voice_navigation/voice_navigation_models.dart';

/// Provider for voice navigation functionality
///
/// This provider wraps the VoiceNavigationController and exposes it to the
/// widget tree through the Provider package.
class VoiceNavigationProvider extends ChangeNotifier {
  late final VoiceNavigationController _controller;
  bool _isInitialized = false;

  VoiceNavigationProvider({
    GlobalKey<NavigatorState>? navigatorKey,
    Function()? onToggleTheme,
    Function(String themeType)? onSetTheme,
    Function(String route)? onNavigate,
  }) {
    _controller = VoiceNavigationController(
      navigatorKey: navigatorKey,
      localVLM: LocalVLMService(),
      apiService: ApiService(),
      onToggleTheme: onToggleTheme,
      onSetTheme: onSetTheme,
      onNavigate: onNavigate,
    );

    // Listen to controller changes
    _controller.addListener(_onControllerUpdate);
  }

  /// Whether the voice navigation system is initialized
  bool get isInitialized => _isInitialized;

  /// Get the current voice navigation state
  VoiceNavigationState get state => _controller.state;

  /// Get the current microphone state
  MicrophoneState get microphoneState => _controller.microphoneState;

  /// Whether the system is currently processing
  bool get isProcessing => _controller.isProcessing;

  /// Whether emergency mode is active
  bool get isEmergencyMode => _controller.isEmergencyMode;

  /// Whether offline mode is active
  bool get isOfflineMode => _controller.isOfflineMode;

  /// Get the audio feedback engine
  AudioFeedbackEngine get audioFeedback => _controller.audioFeedback;

  /// Whether speech recognition is available on this device
  bool get isSpeechRecognitionAvailable =>
      _controller.isSpeechRecognitionAvailable;

  /// Start listening for hotword "Drishti"
  Future<void> startHotwordListening({
    required Function() onHotwordDetected,
  }) async {
    await _controller.startHotwordListening(
      onHotwordDetected: onHotwordDetected,
    );
  }

  /// Stop hotword listening
  Future<void> stopHotwordListening() async {
    await _controller.stopHotwordListening();
  }

  /// Initialize the voice navigation system
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _controller.initialize();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[VoiceNavProvider] Failed to initialize: $e');
      rethrow;
    }
  }

  /// Handle microphone button tap
  Future<void> onMicrophoneTap() async {
    debugPrint(
      '[VoiceNavProvider] Microphone tap received, state: ${_controller.microphoneState}',
    );
    await _controller.onMicrophoneTap();
    notifyListeners(); // Make sure UI updates
  }

  /// Process a voice command
  Future<void> processVoiceCommand(String command) async {
    await _controller.processVoiceCommand(command);
  }

  /// Handle a classified intent
  Future<void> handleIntent(ClassifiedIntent intent) async {
    await _controller.handleIntent(intent);
  }

  /// Trigger emergency mode
  Future<void> triggerEmergency() async {
    await _controller.triggerEmergency();
  }

  /// Enable offline mode
  void enableOfflineMode() {
    _controller.enableOfflineMode();
  }

  /// Disable offline mode
  void disableOfflineMode() {
    _controller.disableOfflineMode();
  }

  /// Update the current screen
  void updateCurrentScreen(String screenRoute) {
    _controller.updateCurrentScreen(screenRoute);
  }

  /// Clear the last error
  void clearError() {
    _controller.clearError();
  }

  /// Called when the controller state changes
  void _onControllerUpdate() {
    notifyListeners();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }
}
