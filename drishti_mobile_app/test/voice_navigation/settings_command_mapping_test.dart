/// Settings Control Command Mapping Tests
///
/// Verifies that settings control commands from VOICE_TESTING_EXAMPLES.md
/// are properly mapped and execute correctly.
///
/// **Validates: Requirements 3.3, 5.2**
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/voice_command_executor.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/audio_feedback_engine.dart';
import 'test_data/voice_commands.dart';

import 'settings_command_mapping_test.mocks.dart';

@GenerateMocks([AudioFeedbackEngine])
void main() {
  group('Settings Control Command Mapping Tests', () {
    late MockAudioFeedbackEngine mockAudioFeedback;
    late VoiceCommandExecutor executor;
    late List<FeatureAction> triggeredActions;
    late List<String> navigatedRoutes;

    setUp(() {
      mockAudioFeedback = MockAudioFeedbackEngine();
      triggeredActions = [];
      navigatedRoutes = [];

      // Mock audio feedback methods
      when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});
      when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});
      when(mockAudioFeedback.announceNavigation(any)).thenAnswer((_) async {});

      executor = VoiceCommandExecutor(
        audioFeedback: mockAudioFeedback,
        onFeatureAction: (action, params) {
          triggeredActions.add(action);
        },
        onNavigate: (route) {
          navigatedRoutes.add(route);
        },
      );
    });

    test('should map "increase volume" to volume adjustment', () async {
      // Arrange
      const command = 'increase volume';

      // Act
      await executor.executeCommand(command);

      // Assert
      verify(mockAudioFeedback.speak(argThat(contains('Volume')))).called(1);
    });

    test('should map "speak faster" to speech speed increase', () async {
      // Arrange
      const command = 'speak faster';

      // Act
      await executor.executeCommand(command);

      // Assert
      expect(triggeredActions, contains(FeatureAction.speechFaster));
      verify(mockAudioFeedback.speak('Speaking faster now')).called(1);
    });

    test('should map "emergency contact" to settings navigation', () async {
      // Arrange
      const command = 'emergency contact';

      // Act
      await executor.executeCommand(command);

      // Assert - should navigate to emergency contacts or settings
      verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
    });

    test('should map "change theme" to theme toggle', () async {
      // Arrange
      const command = 'change theme';

      // Act
      await executor.executeCommand(command);

      // Assert
      expect(triggeredActions, contains(FeatureAction.toggleTheme));
      verify(mockAudioFeedback.speak('Theme toggled')).called(1);
    });

    test('should verify all settings commands from test data', () async {
      // Arrange
      final settingsCommands = VoiceCommandTestData.settingsCommands;

      // Act & Assert
      for (final testCase in settingsCommands) {
        triggeredActions.clear();
        navigatedRoutes.clear();
        reset(mockAudioFeedback);

        // Re-setup mocks
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});

        await executor.executeCommand(testCase.command);

        // Verify audio feedback was provided
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('should provide appropriate audio feedback for settings commands',
        () async {
      // Test each settings command and verify feedback
      final testCases = [
        ('increase volume', 'Volume'),
        ('speak faster', 'Speaking faster now'),
        ('speak slower', 'Speaking slower now'),
        ('normal speed', 'Speech speed reset to normal'),
        ('change theme', 'Theme toggled'),
        ('dark mode', 'Dark mode enabled'),
        ('light mode', 'Light mode enabled'),
      ];

      for (final (command, expectedFeedbackPart) in testCases) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        verify(mockAudioFeedback.speak(argThat(contains(expectedFeedbackPart))))
            .called(1);
      }
    });

    test('should map settings command variations correctly', () async {
      // Test command variations that should map to the same action
      final variations = [
        ('increase volume', FeatureAction.adjustVolume),
        ('volume up', FeatureAction.adjustVolume),
        ('louder', FeatureAction.adjustVolume),
        ('decrease volume', FeatureAction.adjustVolume),
        ('volume down', FeatureAction.adjustVolume),
        ('quieter', FeatureAction.adjustVolume),
        ('speak faster', FeatureAction.speechFaster),
        ('faster speech', FeatureAction.speechFaster),
        ('talk faster', FeatureAction.speechFaster),
        ('speak slower', FeatureAction.speechSlower),
        ('slower speech', FeatureAction.speechSlower),
        ('talk slower', FeatureAction.speechSlower),
        ('toggle theme', FeatureAction.toggleTheme),
        ('switch theme', FeatureAction.toggleTheme),
        ('change theme', FeatureAction.toggleTheme),
      ];

      for (final (command, expectedAction) in variations) {
        final action = VoiceCommandConfig.getActionFromCommand(command);

        expect(
          action,
          equals(expectedAction),
          reason: 'Command "$command" should map to $expectedAction',
        );
      }
    });

    test('should handle volume adjustment commands', () async {
      // Test volume commands
      final volumeCommands = [
        'increase volume',
        'volume up',
        'louder',
        'decrease volume',
        'volume down',
        'quieter',
      ];

      for (final command in volumeCommands) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        // Verify volume feedback
        verify(mockAudioFeedback.speak(argThat(contains('Volume'))))
            .called(1);
      }
    });

    test('should handle speech speed adjustment commands', () async {
      // Test speech speed commands
      final speedCommands = [
        ('speak faster', FeatureAction.speechFaster),
        ('speak slower', FeatureAction.speechSlower),
        ('normal speed', FeatureAction.speechNormal),
        ('reset speed', FeatureAction.speechNormal),
      ];

      for (final (command, expectedAction) in speedCommands) {
        triggeredActions.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        expect(
          triggeredActions,
          contains(expectedAction),
          reason: 'Command "$command" should trigger $expectedAction',
        );
      }
    });

    test('should handle theme commands', () async {
      // Test theme commands
      final themeCommands = [
        ('toggle theme', FeatureAction.toggleTheme),
        ('change theme', FeatureAction.toggleTheme),
        ('dark mode', FeatureAction.darkMode),
        ('enable dark mode', FeatureAction.darkMode),
        ('light mode', FeatureAction.lightMode),
        ('enable light mode', FeatureAction.lightMode),
      ];

      for (final (command, expectedAction) in themeCommands) {
        triggeredActions.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        expect(
          triggeredActions,
          contains(expectedAction),
          reason: 'Command "$command" should trigger $expectedAction',
        );
      }
    });

    test('should handle case-insensitive settings commands', () async {
      // Test that commands work regardless of case
      final casedCommands = [
        'INCREASE VOLUME',
        'Speak Faster',
        'change theme',
        'DARK MODE',
        'Light Mode',
      ];

      for (final command in casedCommands) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('should handle settings commands with extra whitespace', () async {
      // Test that commands work with extra whitespace
      final commandsWithWhitespace = [
        '  increase volume  ',
        ' speak faster ',
        'change theme   ',
        '   dark mode',
      ];

      for (final command in commandsWithWhitespace) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('should trigger feature actions for settings commands', () async {
      // Verify that settings commands trigger feature actions
      final commands = [
        ('speak faster', FeatureAction.speechFaster),
        ('speak slower', FeatureAction.speechSlower),
        ('normal speed', FeatureAction.speechNormal),
        ('toggle theme', FeatureAction.toggleTheme),
        ('dark mode', FeatureAction.darkMode),
        ('light mode', FeatureAction.lightMode),
      ];

      for (final (command, expectedAction) in commands) {
        triggeredActions.clear();

        await executor.executeCommand(command);

        expect(
          triggeredActions,
          contains(expectedAction),
          reason: 'Command "$command" should trigger $expectedAction',
        );
      }
    });
  });

  group('Settings Command Edge Cases', () {
    late MockAudioFeedbackEngine mockAudioFeedback;
    late VoiceCommandExecutor executor;

    setUp(() {
      mockAudioFeedback = MockAudioFeedbackEngine();

      when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});
      when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});

      executor = VoiceCommandExecutor(
        audioFeedback: mockAudioFeedback,
        onFeatureAction: (_, __) {},
        onNavigate: (_) {},
      );
    });

    test('should handle partial settings commands', () async {
      // Test partial commands that might be recognized
      final partialCommands = [
        'volume',
        'theme',
        'speed',
      ];

      for (final command in partialCommands) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        // Should provide some feedback
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('should handle ambiguous settings commands', () async {
      // Commands that might be ambiguous
      final ambiguousCommands = [
        'change',
        'adjust',
        'set',
      ];

      for (final command in ambiguousCommands) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        // Should provide feedback
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });
  });

  group('Settings Command Integration', () {
    late MockAudioFeedbackEngine mockAudioFeedback;
    late VoiceCommandExecutor executor;
    late List<FeatureAction> triggeredActions;

    setUp(() {
      mockAudioFeedback = MockAudioFeedbackEngine();
      triggeredActions = [];

      when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});
      when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});

      executor = VoiceCommandExecutor(
        audioFeedback: mockAudioFeedback,
        onFeatureAction: (action, params) {
          triggeredActions.add(action);
        },
        onNavigate: (_) {},
      );
    });

    test('should handle sequence of settings commands', () async {
      // Test a sequence of settings commands
      final commandSequence = [
        'increase volume',
        'speak faster',
        'change theme',
        'dark mode',
      ];

      for (final command in commandSequence) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('should provide distinct feedback for different settings actions',
        () async {
      // Verify that different actions provide different feedback
      final commands = [
        'speak faster',
        'speak slower',
        'normal speed',
        'toggle theme',
        'dark mode',
        'light mode',
      ];

      final feedbackMessages = <String>[];

      for (final command in commands) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((invocation) async {
          feedbackMessages.add(invocation.positionalArguments[0] as String);
        });

        await executor.executeCommand(command);
      }

      // Verify we got distinct feedback messages
      expect(feedbackMessages.length, equals(commands.length));
      expect(feedbackMessages.toSet().length, equals(commands.length),
          reason: 'Each command should have distinct feedback');
    });

    test('should handle mixed volume direction commands', () async {
      // Test alternating volume up and down
      final volumeSequence = [
        'increase volume',
        'decrease volume',
        'volume up',
        'volume down',
        'louder',
        'quieter',
      ];

      for (final command in volumeSequence) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        verify(mockAudioFeedback.speak(argThat(contains('Volume'))))
            .called(1);
      }
    });

    test('should handle mixed speech speed commands', () async {
      // Test alternating speech speed changes
      final speedSequence = [
        'speak faster',
        'speak slower',
        'normal speed',
        'faster speech',
        'slower speech',
        'reset speed',
      ];

      for (final command in speedSequence) {
        triggeredActions.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        expect(
          triggeredActions,
          isNotEmpty,
          reason: 'Command "$command" should trigger an action',
        );
      }
    });
  });
}
