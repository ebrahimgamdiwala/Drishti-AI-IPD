/// Relatives Management Command Mapping Tests
///
/// Verifies that relatives management commands from VOICE_TESTING_EXAMPLES.md
/// are properly mapped and execute correctly.
///
/// **Validates: Requirements 3.2, 5.3**
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/voice_command_executor.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/audio_feedback_engine.dart';
import 'test_data/voice_commands.dart';

import 'relatives_command_mapping_test.mocks.dart';

@GenerateMocks([AudioFeedbackEngine])
void main() {
  group('Relatives Management Command Mapping Tests', () {
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

    test('should map "add relative" to relatives route with guidance', () async {
      // Arrange
      const command = 'add relative';

      // Act
      await executor.executeCommand(command);

      // Assert
      expect(navigatedRoutes, contains('/relatives'));
      verify(mockAudioFeedback.speak(
        'Opening relatives to add a new family member',
      )).called(1);
    });

    test('should map "show relatives" to relatives route', () async {
      // Arrange
      const command = 'show relatives';

      // Act
      await executor.executeCommand(command);

      // Assert
      expect(navigatedRoutes, contains('/relatives'));
      verify(mockAudioFeedback.speak('Showing your relatives list')).called(1);
    });

    test('should map "create new relative" to relatives route', () async {
      // Arrange
      const command = 'create relative';

      // Act
      await executor.executeCommand(command);

      // Assert
      expect(navigatedRoutes, contains('/relatives'));
      verify(mockAudioFeedback.speak(
        'Opening relatives to add a new family member',
      )).called(1);
    });

    test('should verify all relatives commands from test data', () async {
      // Arrange
      final relativesCommands = VoiceCommandTestData.relativesCommands;

      // Act & Assert
      for (final testCase in relativesCommands) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);

        // Re-setup mocks
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});

        await executor.executeCommand(testCase.command);

        // Verify navigation occurred to relatives page
        expect(
          navigatedRoutes,
          contains('/relatives'),
          reason: 'Command "${testCase.command}" should navigate to relatives',
        );

        // Verify audio feedback was provided
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('should provide appropriate audio feedback for relatives commands',
        () async {
      // Test each relatives command and verify feedback
      final testCases = [
        ('add relative', 'Opening relatives to add a new family member'),
        ('show relatives', 'Showing your relatives list'),
        ('list relatives', 'Showing your relatives list'),
        ('find relative', 'Searching for family member'),
        ('edit relative', 'Ready to edit family member information'),
        ('delete relative', 'Ready to remove family member'),
      ];

      for (final (command, expectedFeedback) in testCases) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        verify(mockAudioFeedback.speak(expectedFeedback)).called(1);
      }
    });

    test('should map relatives command variations correctly', () async {
      // Test command variations that should map to the same action
      final variations = [
        ('add relative', FeatureAction.addRelative),
        ('add family member', FeatureAction.addRelative),
        ('new relative', FeatureAction.addRelative),
        ('add new relative', FeatureAction.addRelative),
        ('create relative', FeatureAction.addRelative),
        ('list relatives', FeatureAction.listRelatives),
        ('show relatives', FeatureAction.listRelatives),
        ('my relatives', FeatureAction.listRelatives),
        ('family members', FeatureAction.listRelatives),
        ('view relatives', FeatureAction.listRelatives),
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

    test('should handle all relatives management actions', () async {
      // Test all relatives-related actions
      final actions = [
        ('add relative', FeatureAction.addRelative),
        ('list relatives', FeatureAction.listRelatives),
        ('find relative', FeatureAction.findRelative),
        ('edit relative', FeatureAction.editRelative),
        ('delete relative', FeatureAction.deleteRelative),
      ];

      for (final (command, expectedAction) in actions) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        // Verify navigation to relatives page
        expect(
          navigatedRoutes,
          contains('/relatives'),
          reason: 'Command "$command" should navigate to relatives',
        );

        // Verify correct action mapping
        final action = VoiceCommandConfig.getActionFromCommand(command);
        expect(
          action,
          equals(expectedAction),
          reason: 'Command "$command" should map to $expectedAction',
        );
      }
    });

    test('should handle case-insensitive relatives commands', () async {
      // Test that commands work regardless of case
      final casedCommands = [
        'ADD RELATIVE',
        'Show Relatives',
        'list relatives',
        'FIND RELATIVE',
        'Edit Relative',
      ];

      for (final command in casedCommands) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        expect(
          navigatedRoutes,
          contains('/relatives'),
          reason: 'Command "$command" should navigate to relatives',
        );
      }
    });

    test('should handle relatives commands with extra whitespace', () async {
      // Test that commands work with extra whitespace
      final commandsWithWhitespace = [
        '  add relative  ',
        ' show relatives ',
        'list relatives   ',
        '   find relative',
      ];

      for (final command in commandsWithWhitespace) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        expect(
          navigatedRoutes,
          contains('/relatives'),
          reason: 'Command "$command" should navigate to relatives',
        );
      }
    });

    test('should navigate to relatives for all relatives commands', () async {
      // Verify all relatives commands navigate to the relatives page
      final commands = [
        'add relative',
        'show relatives',
        'list relatives',
        'find relative',
        'edit relative',
        'delete relative',
        'my relatives',
        'family members',
        'view relatives',
      ];

      for (final command in commands) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        expect(
          navigatedRoutes,
          contains('/relatives'),
          reason: 'Command "$command" should navigate to /relatives',
        );
      }
    });
  });

  group('Relatives Command Edge Cases', () {
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

    test('should handle partial relatives commands', () async {
      // Test partial commands that might be recognized
      final partialCommands = [
        'relatives',
        'family',
      ];

      for (final command in partialCommands) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        // Should either navigate or provide feedback
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('should provide feedback for ambiguous relatives commands', () async {
      // Commands that might be ambiguous
      final ambiguousCommands = [
        'relative',
        'add',
        'show',
      ];

      for (final command in ambiguousCommands) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        // Should provide some feedback
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });
  });

  group('Relatives Command Integration', () {
    late MockAudioFeedbackEngine mockAudioFeedback;
    late VoiceCommandExecutor executor;
    late List<String> navigatedRoutes;

    setUp(() {
      mockAudioFeedback = MockAudioFeedbackEngine();
      navigatedRoutes = [];

      when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});
      when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});

      executor = VoiceCommandExecutor(
        audioFeedback: mockAudioFeedback,
        onNavigate: (route) {
          navigatedRoutes.add(route);
        },
      );
    });

    test('should handle sequence of relatives commands', () async {
      // Test a sequence of relatives commands
      final commandSequence = [
        'show relatives',
        'add relative',
        'list relatives',
        'find relative',
      ];

      for (final command in commandSequence) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        expect(
          navigatedRoutes,
          contains('/relatives'),
          reason: 'Command "$command" should navigate to relatives',
        );
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('should provide distinct feedback for different relatives actions',
        () async {
      // Verify that different actions provide different feedback
      final commands = [
        'add relative',
        'show relatives',
        'find relative',
        'edit relative',
        'delete relative',
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
  });
}
