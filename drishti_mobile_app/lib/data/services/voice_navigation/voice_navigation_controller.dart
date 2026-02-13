/// Voice Navigation Controller
///
/// Central orchestrator for all voice interactions in the Drishti app.
/// Manages the complete voice navigation lifecycle including microphone control,
/// intent classification, routing, and audio feedback.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/voice_navigation/voice_navigation_models.dart';
import '../../providers/locale_provider.dart';
import '../voice_service.dart';
import '../local_vlm_service.dart';
import '../api_service.dart';
import 'audio_feedback_engine.dart';
import 'intent_classifier.dart';
import 'microphone_controller.dart';
import 'voice_router.dart';
import 'phone_vision_provider.dart';
import 'voice_command_executor.dart';
import '../../../presentation/screens/relatives/voice_add_relative_sheet.dart';
import '../../../presentation/screens/relatives/voice_relative_flow_screen.dart';

/// Central controller for voice navigation system
///
/// This controller orchestrates all voice interactions and manages the state
/// of the voice navigation system. It coordinates between:
/// - Microphone controller (listening state)
/// - Intent classifier (understanding commands)
/// - Voice router (navigation)
/// - Audio feedback engine (responses)
/// - Vision provider (image analysis)
class VoiceNavigationController extends ChangeNotifier {
  // Services
  late final VoiceService _voiceService;
  late final MicrophoneController _micController;
  late final AudioFeedbackEngine _audioFeedback;
  late final IntentClassifier _intentClassifier;
  late final VoiceRouter _voiceRouter;
  late final PhoneVisionProvider _visionProvider;
  late final VoiceCommandExecutor _commandExecutor;

  // Navigator key for showing dialogs/sheets
  final GlobalKey<NavigatorState>? _navigatorKey;

  // Current state
  VoiceNavigationState _state = VoiceNavigationState.initial();

  // Callbacks for app-level operations
  final Function()? _onToggleTheme;
  final Function(String themeType)? _onSetTheme;

  /// Constructor with optional navigator key for routing
  VoiceNavigationController({
    GlobalKey<NavigatorState>? navigatorKey,
    LocalVLMService? localVLM,
    ApiService? apiService,
    Function()? onToggleTheme,
    Function(String themeType)? onSetTheme,
    Function(String route)? onNavigate,
  }) : _navigatorKey = navigatorKey,
       _onToggleTheme = onToggleTheme,
       _onSetTheme = onSetTheme {
    _voiceService = VoiceService();
    _micController = MicrophoneController(voiceService: _voiceService);
    _audioFeedback = AudioFeedbackEngine(voiceService: _voiceService);
    _intentClassifier = IntentClassifier();
    _voiceRouter = VoiceRouter(
      navigatorKey: navigatorKey,
      audioFeedback: _audioFeedback,
    );
    _visionProvider = PhoneVisionProvider(
      localVLM: localVLM ?? LocalVLMService(),
      apiService: apiService ?? ApiService(),
    );

    // Initialize voice command executor
    _commandExecutor = VoiceCommandExecutor(
      audioFeedback: _audioFeedback,
      onFeatureAction: _onFeatureAction,
      onNavigate: onNavigate ?? _voiceRouter.navigateTo,
    );
  }

  /// Get the current state
  VoiceNavigationState get state => _state;

  /// Get the current microphone state
  MicrophoneState get microphoneState => _state.microphoneState;

  /// Whether the system is currently processing
  bool get isProcessing => _state.isProcessing;

  /// Whether emergency mode is active
  bool get isEmergencyMode => _state.isEmergencyMode;

  /// Whether offline mode is active
  bool get isOfflineMode => _state.isOfflineMode;

  /// Get the voice router instance
  VoiceRouter get voiceRouter => _voiceRouter;

  /// Get the audio feedback engine instance
  AudioFeedbackEngine get audioFeedback => _audioFeedback;

  /// Get the microphone controller instance
  MicrophoneController get microphoneController => _micController;

  /// Whether speech recognition is available on this device
  bool get isSpeechRecognitionAvailable => _voiceService.isSttAvailable;

  /// Update state and notify listeners
  void _updateState(VoiceNavigationState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Start listening for hotword "Drishti"
  Future<void> startHotwordListening({
    required Function() onHotwordDetected,
  }) async {
    await _voiceService.startHotwordListening(
      onHotwordDetected: onHotwordDetected,
    );
  }

  /// Stop hotword listening
  Future<void> stopHotwordListening() async {
    await _voiceService.stopHotwordListening();
  }

  /// Handle microphone state changes from MicrophoneController
  void _onMicrophoneStateChanged() {
    _updateState(_state.copyWith(microphoneState: _micController.state));
  }

  /// Initialize the voice navigation system
  ///
  /// This should be called when the app starts to set up all voice components.
  Future<void> initialize() async {
    try {
      // Initialize TTS
      await _voiceService.initTts();

      // Initialize STT
      final sttInitialized = await _voiceService.initStt();
      if (!sttInitialized) {
        debugPrint(
          '[VoiceNav] STT initialization failed - voice commands may not work',
        );
        // Provide audio feedback about STT failure
        await _audioFeedback.speak(
          'Voice recognition unavailable, using text-to-speech only',
          priority: AudioPriority.high,
        );
      }

      // Don't announce "ready" - let the screen announce itself
      debugPrint(
        '[VoiceNav] Voice navigation system initialized (STT: $sttInitialized)',
      );
    } catch (e) {
      debugPrint('[VoiceNav] Failed to initialize: $e');
      _updateState(
        _state.copyWith(lastError: 'Failed to initialize voice navigation'),
      );
    }
  }

  /// Handle microphone button tap
  ///
  /// Transitions from idle to listening state when the user taps the mic button.
  Future<void> onMicrophoneTap() async {
    if (_micController.state != MicrophoneState.idle) {
      debugPrint(
        '[VoiceNav] Microphone already active: ${_micController.state.name}',
      );
      return;
    }

    try {
      debugPrint('[VoiceNav] Starting listening via microphone tap');

      // Start listening using MicrophoneController
      await _micController.startListening(
        onResult: (text) {
          debugPrint('[VoiceNav] Voice input received: "$text"');
          // Process the recognized text
          processVoiceCommand(text);
        },
        onError: (error) {
          debugPrint('[VoiceNav] Voice input error: $error');
          _audioFeedback.reportError(_audioFeedback.formatErrorMessage(error));
          _updateState(_state.copyWith(lastError: error));
        },
      );
    } catch (e) {
      debugPrint('[VoiceNav] Failed to start listening: $e');
      await _audioFeedback.reportError(
        _audioFeedback.formatErrorMessage(e.toString()),
      );
      _updateState(_state.copyWith(lastError: 'Failed to start listening'));
    }
  }

  /// Process a voice command
  ///
  /// Takes the recognized speech text and processes it through the intent
  /// classification and routing pipeline. Falls back to command executor for
  /// more specific feature commands.
  Future<void> processVoiceCommand(String command) async {
    if (command.trim().isEmpty) {
      debugPrint('[VoiceNav] Empty command received');
      return;
    }

    // Check for stop listening command first
    final normalized = command.toLowerCase().trim();
    if (normalized.contains('stop listening') || 
        (normalized.contains('stop') && normalized.contains('listening'))) {
      debugPrint('[VoiceNav] Stop listening command received');
      await _voiceService.stopHotwordListening();
      await _audioFeedback.speak('Voice control stopped. Tap the microphone to start again.');
      await _micController.setIdle();
      _updateState(_state.copyWith(isProcessing: false));
      return;
    }

    try {
      // Transition to processing state
      await _micController.setProcessing();
      _updateState(_state.copyWith(isProcessing: true, clearLastError: true));

      debugPrint('[VoiceNav] Processing command: "$command"');

      // First try to execute as a specific feature command
      final action = VoiceCommandConfig.getActionFromCommand(command);
      if (action != FeatureAction.unknown) {
        debugPrint('[VoiceNav] Recognized as feature action: $action');
        await _commandExecutor.executeCommand(command);

        // Return to idle state
        await _micController.setIdle();
        _updateState(_state.copyWith(isProcessing: false));

        // Resume hotword listening
        await _voiceService.resumeHotwordListening();
        return;
      }

      // Fall back to intent classification for complex commands
      final intent = await _intentClassifier.classify(command);
      debugPrint(
        '[VoiceNav] Classified as: ${intent.type.name} (confidence: ${intent.confidence})',
      );

      // Check confidence level
      if (!intent.isConfident) {
        await _audioFeedback.speak(
          'I\'m not sure what you meant. Could you rephrase?',
          priority: AudioPriority.high,
        );
        await _micController.setIdle();
        _updateState(_state.copyWith(isProcessing: false));

        // Resume hotword listening
        await _voiceService.resumeHotwordListening();
        return;
      }

      // Handle the intent
      await handleIntent(intent);

      // Return to idle state
      await _micController.setIdle();
      _updateState(_state.copyWith(isProcessing: false));

      // Resume hotword listening after command completes
      await _voiceService.resumeHotwordListening();
    } catch (e) {
      debugPrint('[VoiceNav] Failed to process command: $e');
      await _audioFeedback.reportError(
        _audioFeedback.formatErrorMessage(e.toString()),
      );
      await _micController.setIdle();
      _updateState(
        _state.copyWith(
          isProcessing: false,
          lastError: 'Failed to process command',
        ),
      );

      // Resume hotword listening even after error
      await _voiceService.resumeHotwordListening();
    }
  }

  /// Handle a classified intent
  ///
  /// Routes the intent to the appropriate handler based on its type.
  Future<void> handleIntent(ClassifiedIntent intent) async {
    debugPrint('[VoiceNav] Handling intent: ${intent.type.name}');

    _updateState(_state.copyWith(lastIntent: intent));

    try {
      // Transition to speaking state for audio feedback
      await _micController.setSpeaking();

      switch (intent.type) {
        case IntentType.navigation:
          // Route to VoiceRouter
          await _voiceRouter.routeFromIntent(intent);
          break;

        case IntentType.vision:
          // Route to VisionProvider
          await _handleVisionIntent(intent);
          break;

        case IntentType.relative:
          // Handle relative management
          await _handleRelativeIntent(intent);
          break;

        case IntentType.auth:
          // TODO: Route to VoiceAuthHandler (Task 11)
          await _audioFeedback.speak(
            'Voice authentication not yet implemented',
            priority: AudioPriority.normal,
          );
          break;

        case IntentType.settings:
          // Handle settings control
          await _handleSettingsIntent(intent);
          break;

        case IntentType.system:
          // Handle system info
          await _handleSystemIntent(intent);
          break;

        case IntentType.emergency:
          await triggerEmergency();
          break;
      }
    } catch (e) {
      debugPrint('[VoiceNav] Failed to handle intent: $e');
      await _audioFeedback.reportError(
        _audioFeedback.formatErrorMessage(e.toString()),
      );
      _updateState(_state.copyWith(lastError: 'Failed to handle command'));
    }
  }

  /// Trigger emergency mode
  ///
  /// Activates emergency mode with highest priority, interrupting all other operations.
  Future<void> triggerEmergency() async {
    debugPrint('[VoiceNav] Emergency mode activated!');

    _updateState(_state.copyWith(isEmergencyMode: true));

    // Announce emergency mode activation immediately
    await _audioFeedback.speakImmediate('Emergency mode activated');

    // TODO: Implement emergency handler (Task 13)
    // - Attempt to call emergency contact
    // - Override current screen with emergency UI
    // - Send location data if available

    // For now, just provide feedback
    await _audioFeedback.speakImmediate(
      'Emergency contact calling not yet implemented. Please configure emergency contact in settings.',
    );

    // Reset emergency mode after handling
    await Future.delayed(const Duration(seconds: 3));
    _updateState(_state.copyWith(isEmergencyMode: false));

    // Return to idle state
    await _micController.setIdle();
  }

  /// Handle vision intent
  ///
  /// Processes vision-related commands (scan, obstacles, people, text)
  Future<void> _handleVisionIntent(ClassifiedIntent intent) async {
    try {
      final analysisType =
          intent.parameters['analysisType'] as String? ?? 'general';

      debugPrint('[VoiceNav] Processing vision intent: $analysisType');

      // Perform appropriate vision analysis
      final result = await _performVisionAnalysis(analysisType);

      // Format response (max 2 sentences, safety-first)
      final formattedResponse = _audioFeedback.formatVisionResponse(
        result.description,
      );

      // Speak the result
      await _audioFeedback.speak(
        formattedResponse,
        priority: AudioPriority.high,
      );

      // Check for hazards
      final safetyResult = await _visionProvider.checkForHazards();
      if (safetyResult.hasDanger) {
        // Interrupt with safety warning
        await _audioFeedback.speakImmediate(safetyResult.warningMessage);
      }
    } catch (e) {
      debugPrint('[VoiceNav] Vision analysis error: $e');
      await _audioFeedback.reportError(
        _audioFeedback.formatErrorMessage(e.toString()),
      );
    }
  }

  /// Perform vision analysis based on type
  Future<dynamic> _performVisionAnalysis(String analysisType) async {
    switch (analysisType) {
      case 'obstacles':
        return await _visionProvider.detectObstacles();
      case 'text':
        return await _visionProvider.readText();
      case 'people':
        return await _visionProvider.identifyPeople();
      case 'general':
      default:
        return await _visionProvider.analyzeCurrentView();
    }
  }

  /// Handle relative management intent
  Future<void> _handleRelativeIntent(ClassifiedIntent intent) async {
    final action = intent.parameters['action'] as String?;

    debugPrint('[VoiceNav] Handling relative intent: $action');

    switch (action) {
      case 'create':
        // Navigate to relatives page and announce creation flow
        await _voiceRouter.navigateTo('/relatives');
        await Future.delayed(const Duration(milliseconds: 500));
        await _audioFeedback.speak(
          'Opening relatives page. To add a new relative, tap the add button and follow the prompts.',
          priority: AudioPriority.high,
        );
        break;

      case 'delete':
        await _audioFeedback.speak(
          'To delete a relative, go to relatives page and select the person you want to remove.',
          priority: AudioPriority.normal,
        );
        break;

      case 'edit':
        await _audioFeedback.speak(
          'To edit a relative, go to relatives page and select the person you want to update.',
          priority: AudioPriority.normal,
        );
        break;

      case 'list':
        await _voiceRouter.navigateTo('/relatives');
        await Future.delayed(const Duration(milliseconds: 500));
        await _audioFeedback.speak(
          'Showing all relatives.',
          priority: AudioPriority.normal,
        );
        break;

      default:
        // Proximity or identification query
        await _audioFeedback.speak(
          'Relative identification feature coming soon.',
          priority: AudioPriority.normal,
        );
    }
  }

  /// Handle settings control intent
  Future<void> _handleSettingsIntent(ClassifiedIntent intent) async {
    final setting = intent.parameters['setting'] as String?;
    final action = intent.parameters['action'] as String?;
    final direction = intent.parameters['direction'] as String?;

    debugPrint(
      '[VoiceNav] Handling settings intent: $setting, action: $action, direction: $direction',
    );

    // First navigate to settings if not already there
    if (_state.currentScreen != '/settings') {
      await _voiceRouter.navigateTo('/settings');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    switch (setting) {
      case 'volume':
        if (direction == 'up') {
          final newVolume = (_voiceService.volume + 0.1).clamp(0.0, 1.0);
          await _voiceService.setVolume(newVolume);
          await _audioFeedback.speak(
            'Volume increased to ${(newVolume * 100).round()} percent',
            priority: AudioPriority.high,
          );
        } else if (direction == 'down') {
          final newVolume = (_voiceService.volume - 0.1).clamp(0.0, 1.0);
          await _voiceService.setVolume(newVolume);
          await _audioFeedback.speak(
            'Volume decreased to ${(newVolume * 100).round()} percent',
            priority: AudioPriority.high,
          );
        }
        break;

      case 'speechRate':
        if (direction == 'faster') {
          final newRate = (_voiceService.speechRate + 0.1).clamp(0.0, 1.0);
          await _voiceService.setSpeechRate(newRate);
          await _audioFeedback.speak(
            'Speech speed increased',
            priority: AudioPriority.high,
          );
        } else if (direction == 'slower') {
          final newRate = (_voiceService.speechRate - 0.1).clamp(0.0, 1.0);
          await _voiceService.setSpeechRate(newRate);
          await _audioFeedback.speak(
            'Speech speed decreased',
            priority: AudioPriority.high,
          );
        }
        break;

      case 'theme':
        if (_onToggleTheme != null || _onSetTheme != null) {
          final value = intent.parameters['value'] as String?;
          final themeAction = intent.parameters['action'] as String?;

          if (value == 'dark') {
            _onSetTheme?.call('dark');
            await _audioFeedback.speak(
              'Dark mode enabled',
              priority: AudioPriority.high,
            );
          } else if (value == 'light') {
            _onSetTheme?.call('light');
            await _audioFeedback.speak(
              'Light mode enabled',
              priority: AudioPriority.high,
            );
          } else if (themeAction == 'toggle') {
            _onToggleTheme?.call();
            await _audioFeedback.speak(
              'Theme toggled',
              priority: AudioPriority.high,
            );
          } else {
            await _audioFeedback.speak(
              'Theme settings updated',
              priority: AudioPriority.normal,
            );
          }
        } else {
          await _audioFeedback.speak(
            'Theme settings are on the settings page. You can toggle between light and dark mode.',
            priority: AudioPriority.normal,
          );
        }
        break;

      case 'vibration':
        await _audioFeedback.speak(
          'Vibration settings are on the settings page.',
          priority: AudioPriority.normal,
        );
        break;

      case 'emergencyContact':
        await _audioFeedback.speak(
          'Emergency contact settings are on the settings page. Scroll down to find emergency contact options.',
          priority: AudioPriority.normal,
        );
        break;

      default:
        await _audioFeedback.speak(
          'You are on the settings page. Available options include volume, speech speed, theme, and emergency contacts.',
          priority: AudioPriority.normal,
        );
    }
  }

  /// Handle system information intent
  Future<void> _handleSystemIntent(ClassifiedIntent intent) async {
    final infoType = intent.parameters['infoType'] as String?;

    debugPrint('[VoiceNav] Handling system intent: $infoType');

    switch (infoType) {
      case 'battery':
        await _audioFeedback.speak(
          'Battery information is available on the dashboard.',
          priority: AudioPriority.normal,
        );
        await _voiceRouter.navigateTo('/dashboard');
        break;

      case 'connection':
        await _audioFeedback.speak(
          'You are currently online.',
          priority: AudioPriority.normal,
        );
        break;

      default:
        await _audioFeedback.speak(
          'System status: All systems operational.',
          priority: AudioPriority.normal,
        );
    }
  }

  /// Enable offline mode
  ///
  /// Switches to offline mode when network connectivity is lost.
  void enableOfflineMode() {
    debugPrint('[VoiceNav] Offline mode enabled');
    _updateState(_state.copyWith(isOfflineMode: true));
  }

  /// Disable offline mode
  ///
  /// Switches back to online mode when network connectivity is restored.
  void disableOfflineMode() {
    debugPrint('[VoiceNav] Offline mode disabled');
    _updateState(_state.copyWith(isOfflineMode: false));
  }

  /// Update the current screen
  ///
  /// Called when navigation occurs to track the current screen.
  void updateCurrentScreen(String screenRoute) {
    _updateState(_state.copyWith(currentScreen: screenRoute));
  }

  /// Clear the last error
  void clearError() {
    _updateState(_state.copyWith(clearLastError: true));
  }

  /// Handle feature action from voice command executor
  Future<void> _onFeatureAction(FeatureAction action, Map<String, dynamic> params) async {
    debugPrint('[VoiceNav] Feature action: $action with params: $params');

    switch (action) {
      // Relatives management
      case FeatureAction.addRelative:
        final voiceGuided = params['voiceGuided'] as bool? ?? false;
        final handsFree = params['handsFree'] as bool? ?? false;
        if (voiceGuided && handsFree) {
          _showHandsFreeAddRelative();
        } else if (voiceGuided) {
          _showVoiceGuidedAddRelative();
        }
        break;

      // Speech speed controls
      case FeatureAction.speechFaster:
        final currentRate = _voiceService.speechRate;
        final newRate = (currentRate + 0.15).clamp(0.0, 1.0);
        _voiceService.setSpeechRate(newRate);
        debugPrint('[VoiceNav] Speech rate increased to $newRate');
        break;
      case FeatureAction.speechSlower:
        final currentRate = _voiceService.speechRate;
        final newRate = (currentRate - 0.15).clamp(0.0, 1.0);
        _voiceService.setSpeechRate(newRate);
        debugPrint('[VoiceNav] Speech rate decreased to $newRate');
        break;
      case FeatureAction.speechNormal:
        _voiceService.setSpeechRate(0.5);
        debugPrint('[VoiceNav] Speech rate reset to normal (0.5)');
        break;

      // Theme controls
      case FeatureAction.toggleTheme:
        _onToggleTheme?.call();
        break;
      case FeatureAction.darkMode:
        _onSetTheme?.call('dark');
        break;
      case FeatureAction.lightMode:
        _onSetTheme?.call('light');
        break;

      // Language change
      case FeatureAction.changeLanguage:
        final languageCode = params['languageCode'] as String?;
        if (languageCode != null) {
          _changeLanguage(languageCode);
        }
        break;

      // Navigation
      case FeatureAction.goBack:
        _voiceRouter.goBack();
        break;

      // General actions
      case FeatureAction.cancel:
        _updateState(_state.copyWith(isProcessing: false));
        break;
      case FeatureAction.stop:
        final stopListening = params['stopListening'] as bool? ?? false;
        if (stopListening) {
          await _voiceService.stopHotwordListening();
          await _audioFeedback.speak('Voice control stopped. Tap the microphone to start again.');
        } else {
          _voiceService.stopSpeaking();
        }
        break;
      case FeatureAction.logout:
        _updateState(_state.copyWith(isProcessing: false));
        break;

      // Default - no special handling needed
      default:
        break;
    }
  }

  /// Show voice-guided add relative sheet
  void _showVoiceGuidedAddRelative() {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      debugPrint('[VoiceNav] Cannot show voice-guided sheet: no context');
      return;
    }

    // Import is added at the top of the file
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceAddRelativeSheet(),
    ).then((result) {
      if (result != null) {
        debugPrint('[VoiceNav] Relative added via voice: $result');
      }
    });
  }

  /// Show hands-free voice-guided add relative flow (full screen)
  void _showHandsFreeAddRelative() {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      debugPrint('[VoiceNav] Cannot show hands-free flow: no context');
      return;
    }

    // Navigate to full-screen hands-free flow
    Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (context) => const VoiceRelativeFlowScreen(),
        fullscreenDialog: true,
      ),
    ).then((result) {
      if (result != null) {
        debugPrint('[VoiceNav] Relative added via hands-free flow: $result');
        // Resume hotword listening after flow completes
        _voiceService.resumeHotwordListening();
      } else {
        debugPrint('[VoiceNav] Hands-free flow cancelled');
        // Resume hotword listening even if cancelled
        _voiceService.resumeHotwordListening();
      }
    });
  }

  /// Change app language
  void _changeLanguage(String languageCode) {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      debugPrint('[VoiceNav] Cannot change language: no context');
      return;
    }

    try {
      final localeProvider = context.read<LocaleProvider>();
      localeProvider.setLocale(Locale(languageCode, ''));
      debugPrint('[VoiceNav] Language changed to: $languageCode');
    } catch (e) {
      debugPrint('[VoiceNav] Error changing language: $e');
    }
  }

  @override
  void dispose() {
    _micController.removeListener(_onMicrophoneStateChanged);
    _micController.dispose();
    _audioFeedback.dispose();
    debugPrint('[VoiceNav] Voice navigation controller disposed');
    super.dispose();
  }
}
