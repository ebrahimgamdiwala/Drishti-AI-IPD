/// Voice Command Test Data
///
/// Test data extracted from VOICE_TESTING_EXAMPLES.md for comprehensive
/// voice command mapping verification.
library;

import 'package:drishti_mobile_app/data/services/voice_navigation/voice_command_executor.dart';

/// Test case for a voice command
class VoiceCommandTestCase {
  final String command;
  final VoiceCommandCategory category;
  final FeatureAction expectedAction;
  final String? expectedRoute;
  final String? expectedFeedback;
  final Map<String, dynamic>? expectedParameters;

  const VoiceCommandTestCase({
    required this.command,
    required this.category,
    required this.expectedAction,
    this.expectedRoute,
    this.expectedFeedback,
    this.expectedParameters,
  });
}

/// Categories of voice commands
enum VoiceCommandCategory {
  navigation,
  relatives,
  settings,
  vision,
  system,
}

/// All voice commands from VOICE_TESTING_EXAMPLES.md
class VoiceCommandTestData {
  /// Navigation commands
  static const List<VoiceCommandTestCase> navigationCommands = [
    VoiceCommandTestCase(
      command: 'go to dashboard',
      category: VoiceCommandCategory.navigation,
      expectedAction: FeatureAction.goDashboard,
      expectedRoute: '/dashboard',
      expectedFeedback: 'Navigating to dashboard',
    ),
    VoiceCommandTestCase(
      command: 'go to settings',
      category: VoiceCommandCategory.navigation,
      expectedAction: FeatureAction.goSettings,
      expectedRoute: '/settings',
      expectedFeedback: 'Opening settings',
    ),
    VoiceCommandTestCase(
      command: 'go to relatives',
      category: VoiceCommandCategory.navigation,
      expectedAction: FeatureAction.goRelatives,
      expectedRoute: '/relatives',
      expectedFeedback: 'Opening relatives page',
    ),
    VoiceCommandTestCase(
      command: 'go home',
      category: VoiceCommandCategory.navigation,
      expectedAction: FeatureAction.goHome,
      expectedRoute: '/home',
      expectedFeedback: 'Going to home screen',
    ),
  ];

  /// Relatives management commands
  static const List<VoiceCommandTestCase> relativesCommands = [
    VoiceCommandTestCase(
      command: 'add relative',
      category: VoiceCommandCategory.relatives,
      expectedAction: FeatureAction.addRelative,
      expectedRoute: '/relatives',
      expectedFeedback:
          'Opening relatives page. To add a new relative, tap the add button and follow the prompts.',
    ),
    VoiceCommandTestCase(
      command: 'show relatives',
      category: VoiceCommandCategory.relatives,
      expectedAction: FeatureAction.listRelatives,
      expectedRoute: '/relatives',
      expectedFeedback: 'Showing all relatives',
    ),
    VoiceCommandTestCase(
      command: 'create new relative',
      category: VoiceCommandCategory.relatives,
      expectedAction: FeatureAction.addRelative,
      expectedRoute: '/relatives',
      expectedFeedback:
          'Opening relatives page. To add a new relative, tap the add button and follow the prompts.',
    ),
  ];

  /// Settings control commands
  static const List<VoiceCommandTestCase> settingsCommands = [
    VoiceCommandTestCase(
      command: 'increase volume',
      category: VoiceCommandCategory.settings,
      expectedAction: FeatureAction.adjustVolume,
      expectedFeedback: 'Volume increased to',
      expectedParameters: {'adjustment': 'increase', 'amount': 10},
    ),
    VoiceCommandTestCase(
      command: 'speak faster',
      category: VoiceCommandCategory.settings,
      expectedAction: FeatureAction.speechFaster,
      expectedFeedback: 'Speech speed increased',
    ),
    VoiceCommandTestCase(
      command: 'emergency contact',
      category: VoiceCommandCategory.settings,
      expectedAction: FeatureAction.viewEmergencyContacts,
      expectedRoute: '/emergency',
      expectedFeedback:
          'Emergency contact settings are on the settings page. Scroll down to find emergency contact options.',
    ),
    VoiceCommandTestCase(
      command: 'change theme',
      category: VoiceCommandCategory.settings,
      expectedAction: FeatureAction.toggleTheme,
      expectedFeedback:
          'Theme settings are on the settings page. You can toggle between light and dark mode.',
    ),
  ];

  /// Vision/scanning commands
  static const List<VoiceCommandTestCase> visionCommands = [
    VoiceCommandTestCase(
      command: 'scan surroundings',
      category: VoiceCommandCategory.vision,
      expectedAction: FeatureAction.scan,
      expectedFeedback: 'Analyzing surroundings',
    ),
    VoiceCommandTestCase(
      command: 'what\'s in front of me',
      category: VoiceCommandCategory.vision,
      expectedAction: FeatureAction.scan,
      expectedFeedback: 'Analyzing what\'s in front',
    ),
    VoiceCommandTestCase(
      command: 'detect obstacles',
      category: VoiceCommandCategory.vision,
      expectedAction: FeatureAction.detectObstacles,
      expectedFeedback: 'Detecting obstacles',
    ),
    VoiceCommandTestCase(
      command: 'read text',
      category: VoiceCommandCategory.vision,
      expectedAction: FeatureAction.readText,
      expectedFeedback: 'Reading text',
    ),
  ];

  /// System information commands
  static const List<VoiceCommandTestCase> systemCommands = [
    VoiceCommandTestCase(
      command: 'battery status',
      category: VoiceCommandCategory.system,
      expectedAction: FeatureAction.viewBattery,
      expectedRoute: '/dashboard',
      expectedFeedback: 'Battery information is available on the dashboard',
    ),
    VoiceCommandTestCase(
      command: 'am i online',
      category: VoiceCommandCategory.system,
      expectedAction: FeatureAction.viewConnection,
      expectedFeedback: 'You are currently online',
    ),
  ];

  /// All commands combined
  static List<VoiceCommandTestCase> get allCommands => [
        ...navigationCommands,
        ...relativesCommands,
        ...settingsCommands,
        ...visionCommands,
        ...systemCommands,
      ];

  /// Get commands by category
  static List<VoiceCommandTestCase> getCommandsByCategory(
      VoiceCommandCategory category) {
    switch (category) {
      case VoiceCommandCategory.navigation:
        return navigationCommands;
      case VoiceCommandCategory.relatives:
        return relativesCommands;
      case VoiceCommandCategory.settings:
        return settingsCommands;
      case VoiceCommandCategory.vision:
        return visionCommands;
      case VoiceCommandCategory.system:
        return systemCommands;
    }
  }

  /// Multi-step test sequence from VOICE_TESTING_EXAMPLES.md
  static const List<String> multiStepSequence = [
    'go to dashboard',
    'go to settings',
    'increase volume',
    'go home',
  ];

  /// Command patterns for testing variations
  static const Map<String, List<String>> commandPatterns = {
    'navigation': [
      'go to [screen]',
      'open [screen]',
      'show me [screen]',
      'navigate to [screen]',
    ],
    'relatives': [
      'add relative',
      'create relative',
      'new relative',
      'show relatives',
      'list family',
    ],
    'settings': [
      'increase/decrease volume',
      'louder/quieter',
      'faster/slower',
      'change theme',
      'emergency contact',
    ],
    'vision': [
      'scan [something]',
      'what\'s [location]',
      'describe [something]',
      'detect obstacles',
      'read text',
    ],
  };

  /// Expected log patterns for successful command execution
  static const Map<String, String> expectedLogPatterns = {
    'hotword_detected': r'\[VoiceService\] ✅ HOTWORD DETECTED!',
    'hotword_started': r'\[MainShell\] 🎤 Hotword detected! Starting voice command\.\.\.',
    'listening_started': r'\[VoiceNav\] Starting listening via microphone tap',
    'state_transition': r'\[MicController\] State transition: idle → listening',
    'hotword_paused': r'\[VoiceService\] Hotword listening paused for voice command',
    'command_heard': r'\[VoiceService\] 🎤 Heard: ".+" \(final: true\)',
    'command_processing': r'\[VoiceNav\] Processing command: ".+"',
    'command_classified': r'\[VoiceNav\] Classified as: \w+ \(confidence: \d+\.\d+\)',
    'navigation': r'\[VoiceRouter\] Navigating to: /.+',
    'restart_scheduled': r'\[MainShell\] ⏰ Scheduling hotword restart in 5 seconds\.\.\.',
    'restart_initiated': r'\[MainShell\] 🔄 Restarting hotword listening\.\.\.',
    'restart_success': r'\[MainShell\] ✅ Hotword listening restarted successfully',
  };

  /// Troubleshooting scenarios
  static const Map<String, String> troubleshootingScenarios = {
    'hotword_stops_after_2_commands':
        'Check logs for hotword restart success message 5 seconds after each command',
    'commands_not_recognized':
        'Speak clearly at normal pace, wait for beep, ensure quiet environment, check microphone permissions',
    'navigation_not_working':
        'Check logs for VoiceRouter navigation messages, verify routes exist',
    'settings_not_working':
        'Check logs for settings intent handling, verify exact command phrases',
  };

  /// Success criteria checklist
  static const List<String> successCriteria = [
    'Hotword "Hey Vision" is detected consistently',
    'Commands work at least 5 times in a row',
    'Navigation to all screens works',
    'Volume and speech speed adjustments work',
    'Settings page opens when requested',
    'Relatives page opens when requested',
    'System provides clear audio feedback for each action',
    'Hotword listening restarts automatically after each command',
  ];

  /// Invalid commands for testing error handling
  static const List<String> invalidCommands = [
    'asdfghjkl',
    '12345',
    '!@#\$%^&*()',
    '',
    '   ',
    'xyzzy plugh',
    'lorem ipsum dolor',
    'qwerty uiop',
  ];

  /// Ambiguous commands for testing low confidence handling
  static const List<String> ambiguousCommands = [
    'go',
    'show',
    'open',
    'change',
    'set',
    'get',
  ];
}
