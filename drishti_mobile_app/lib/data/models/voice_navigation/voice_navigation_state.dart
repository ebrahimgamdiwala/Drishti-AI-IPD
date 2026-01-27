/// Voice Navigation State Model
///
/// Represents the complete state of the voice navigation system.
library;

import 'classified_intent.dart';
import 'microphone_state.dart';

/// The complete state of the voice navigation system
class VoiceNavigationState {
  /// Current microphone state
  final MicrophoneState microphoneState;

  /// Current screen route name
  final String? currentScreen;

  /// Last classified intent
  final ClassifiedIntent? lastIntent;

  /// Conversation history for multi-turn conversations
  final List<String> conversationHistory;

  /// Whether emergency mode is active
  final bool isEmergencyMode;

  /// Whether offline mode is active
  final bool isOfflineMode;

  /// Last error message (if any)
  final String? lastError;

  /// Whether the system is currently processing a command
  final bool isProcessing;

  const VoiceNavigationState({
    this.microphoneState = MicrophoneState.idle,
    this.currentScreen,
    this.lastIntent,
    this.conversationHistory = const [],
    this.isEmergencyMode = false,
    this.isOfflineMode = false,
    this.lastError,
    this.isProcessing = false,
  });

  /// Create initial state
  factory VoiceNavigationState.initial() {
    return const VoiceNavigationState();
  }

  /// Create a copy with updated fields
  VoiceNavigationState copyWith({
    MicrophoneState? microphoneState,
    String? currentScreen,
    ClassifiedIntent? lastIntent,
    List<String>? conversationHistory,
    bool? isEmergencyMode,
    bool? isOfflineMode,
    String? lastError,
    bool? isProcessing,
    bool clearLastIntent = false,
    bool clearLastError = false,
  }) {
    return VoiceNavigationState(
      microphoneState: microphoneState ?? this.microphoneState,
      currentScreen: currentScreen ?? this.currentScreen,
      lastIntent: clearLastIntent ? null : (lastIntent ?? this.lastIntent),
      conversationHistory: conversationHistory ?? this.conversationHistory,
      isEmergencyMode: isEmergencyMode ?? this.isEmergencyMode,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'microphoneState': microphoneState.name,
      'currentScreen': currentScreen,
      'lastIntent': lastIntent?.toJson(),
      'conversationHistory': conversationHistory,
      'isEmergencyMode': isEmergencyMode,
      'isOfflineMode': isOfflineMode,
      'lastError': lastError,
      'isProcessing': isProcessing,
    };
  }

  /// Create from JSON
  factory VoiceNavigationState.fromJson(Map<String, dynamic> json) {
    return VoiceNavigationState(
      microphoneState: MicrophoneState.values.firstWhere(
        (e) => e.name == json['microphoneState'],
        orElse: () => MicrophoneState.idle,
      ),
      currentScreen: json['currentScreen'] as String?,
      lastIntent: json['lastIntent'] != null
          ? ClassifiedIntent.fromJson(json['lastIntent'] as Map<String, dynamic>)
          : null,
      conversationHistory: (json['conversationHistory'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isEmergencyMode: json['isEmergencyMode'] as bool? ?? false,
      isOfflineMode: json['isOfflineMode'] as bool? ?? false,
      lastError: json['lastError'] as String?,
      isProcessing: json['isProcessing'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'VoiceNavigationState(mic: ${microphoneState.name}, '
        'screen: $currentScreen, emergency: $isEmergencyMode, '
        'offline: $isOfflineMode, processing: $isProcessing)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VoiceNavigationState &&
        other.microphoneState == microphoneState &&
        other.currentScreen == currentScreen &&
        other.isEmergencyMode == isEmergencyMode &&
        other.isOfflineMode == isOfflineMode &&
        other.isProcessing == isProcessing;
  }

  @override
  int get hashCode {
    return microphoneState.hashCode ^
        currentScreen.hashCode ^
        isEmergencyMode.hashCode ^
        isOfflineMode.hashCode ^
        isProcessing.hashCode;
  }
}
