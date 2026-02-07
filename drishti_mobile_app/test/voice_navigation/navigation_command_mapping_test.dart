/// Navigation Command Mapping Tests
///
/// Verifies that navigation commands from VOICE_TESTING_EXAMPLES.md
/// are properly mapped and execute correctly.
///
/// **Validates: Requirements 3.1, 5.1**
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/voice_command_executor.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/audio_feedback_engine.dart';
import 'test_data/voice_commands.dart';

import 'navigation_command_mapping_test.mocks.dart';

@GenerateMocks([AudioFeedbackEngine])
void main() {
  group('Navigation Command Mapping Tests', () {
    late MockAudioFeedbackEngine mockAudioFeedback;
    late VoiceCommandExecutor executor;
    late List<String> navigatedRoutes;

    setUp(() {
      mockAudioFeedback = MockAudioFeedbackEngine();
      navigatedRoutes = [];

      // Mock audio feedback methods
      when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});
      when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});
      when(mockAudioFeedback.announceNavigation(any)).thenAnswer((_) async {});

      executor = VoiceCommandExecutor(
        audioFeedback: mockAudioFeedback,
        onNavigate: (route) {
          navigatedRoutes.add(route);
        },
      );
    });

    test('should map "go to dashboard" to dashboard route', () async {
      // Arrange
      const command = 'go to dashboard';

      // Act
      await executor.executeCommand(command);

      // Assert
      expect(navigatedRoutes, contains('/dashboard'));
      verify(mockAudioFeedback.speak('Opening dashboard')).called(1);
    });

    test('should map "go to settings" to settings route', () async {
      // Arrange
      const command = 'go to settings';

      // Act
      await executor.executeCommand(command);

      // Assert
      expect(navigatedRoutes, contains('/settings'));
      verify(mockAudioFeedback.speak('Opening settings')).called(1);
    });

    test('should map "go to relatives" to relatives route', () async {
      // Arrange
      const command = 'go to relatives';

      // Act
      await executor.executeCommand(command);

      // Assert
      expect(navigatedRoutes, contains('/relatives'));
      verify(mockAudioFeedback.speak('Opening relatives')).called(1);
    });

    test('should map "go home" to home route', () async {
      // Arrange
      const command = 'go home';

      // Act
      await executor.executeCommand(command);

      // Assert
      expect(navigatedRoutes, contains('/home'));
      verify(mockAudioFeedback.speak('Going to home')).called(1);
    });

    test('should verify all navigation commands from test data', () async {
      // Arrange
      final navigationCommands = VoiceCommandTestData.navigationCommands;

      // Act & Assert
      for (final testCase in navigationCommands) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);

        // Re-setup mocks
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});

        await executor.executeCommand(testCase.command);

        // Verify navigation occurred
        expect(
          navigatedRoutes,
          isNotEmpty,
          reason: 'Command "${testCase.command}" should trigger navigation',
        );

        // Verify audio feedback was provided
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('should provide correct audio feedback for each navigation command',
        () async {
      // Test each navigation command and verify feedback
      final testCases = [
        ('go to dashboard', 'Opening dashboard'),
        ('go to settings', 'Opening settings'),
        ('go to relatives', 'Opening relatives'),
        ('go home', 'Going to home'),
      ];

      for (final (command, expectedFeedback) in testCases) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        verify(mockAudioFeedback.speak(expectedFeedback)).called(1);
      }
    });

    test('should map navigation command variations correctly', () async {
      // Test command variations that should map to the same action
      final variations = [
        ('dashboard', '/dashboard'),
        ('go dashboard', '/dashboard'),
        ('open dashboard', '/dashboard'),
        ('settings', '/settings'),
        ('open settings', '/settings'),
        ('relatives', '/relatives'),
        ('family', '/relatives'),
        ('open relatives', '/relatives'),
        ('home', '/home'),
        ('home screen', '/home'),
        ('main screen', '/home'),
      ];

      for (final (command, expectedRoute) in variations) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        expect(
          navigatedRoutes,
          contains(expectedRoute),
          reason: 'Command "$command" should navigate to $expectedRoute',
        );
      }
    });

    test('should handle navigation to all main screens', () async {
      // Test navigation to all main app screens
      final mainScreens = [
        ('go home', '/home'),
        ('go to dashboard', '/dashboard'),
        ('open vision', '/vision'),
        ('go to relatives', '/relatives'),
        ('go to settings', '/settings'),
        ('open activity', '/activity'),
        ('open profile', '/profile'),
        ('show help', '/help'),
      ];

      for (final (command, expectedRoute) in mainScreens) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        expect(
          navigatedRoutes,
          contains(expectedRoute),
          reason: 'Command "$command" should navigate to $expectedRoute',
        );
      }
    });

    test('should verify FeatureAction mapping for navigation commands',
        () async {
      // Verify that commands map to correct FeatureAction
      final actionMappings = [
        ('go home', FeatureAction.goHome),
        ('go to dashboard', FeatureAction.goDashboard),
        ('go to settings', FeatureAction.goSettings),
        ('go to relatives', FeatureAction.goRelatives),
        ('open vision', FeatureAction.goVision),
        ('open activity', FeatureAction.goActivity),
        ('open profile', FeatureAction.goProfile),
        ('show help', FeatureAction.goHelp),
      ];

      for (final (command, expectedAction) in actionMappings) {
        final action = VoiceCommandConfig.getActionFromCommand(command);

        expect(
          action,
          equals(expectedAction),
          reason: 'Command "$command" should map to $expectedAction',
        );
      }
    });

    test('should handle case-insensitive navigation commands', () async {
      // Test that commands work regardless of case
      final casedCommands = [
        'GO TO DASHBOARD',
        'Go To Settings',
        'go to relatives',
        'GO HOME',
        'Open Settings',
      ];

      for (final command in casedCommands) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        expect(
          navigatedRoutes,
          isNotEmpty,
          reason: 'Command "$command" should trigger navigation',
        );
      }
    });

    test('should handle navigation commands with extra whitespace', () async {
      // Test that commands work with extra whitespace
      final commandsWithWhitespace = [
        '  go to dashboard  ',
        ' go to settings ',
        'go to relatives   ',
        '   go home',
      ];

      for (final command in commandsWithWhitespace) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        expect(
          navigatedRoutes,
          isNotEmpty,
          reason: 'Command "$command" should trigger navigation',
        );
      }
    });
  });

  group('Navigation Command Edge Cases', () {
    late MockAudioFeedbackEngine mockAudioFeedback;
    late VoiceCommandExecutor executor;

    setUp(() {
      mockAudioFeedback = MockAudioFeedbackEngine();

      when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});
      when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});

      executor = VoiceCommandExecutor(
        audioFeedback: mockAudioFeedback,
        onNavigate: (_) {},
      );
    });

    test('should handle unknown navigation commands gracefully', () async {
      // Arrange
      const unknownCommand = 'go to nonexistent screen';

      // Act
      await executor.executeCommand(unknownCommand);

      // Assert - should provide feedback for unknown command
      verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
    });

    test('should handle empty navigation command', () async {
      // Arrange
      const emptyCommand = '';

      // Act
      await executor.executeCommand(emptyCommand);

      // Assert - should handle gracefully
      verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
    });

    test('should handle navigation command with special characters', () async {
      // Arrange
      const specialCommand = 'go to @#\$%';

      // Act
      await executor.executeCommand(specialCommand);

      // Assert - should handle gracefully
      verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
    });
  });
}
