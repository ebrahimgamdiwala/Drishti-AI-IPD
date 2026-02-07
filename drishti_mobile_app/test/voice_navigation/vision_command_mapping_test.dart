/// Vision/Scanning Command Mapping Tests
///
/// Verifies that vision/scanning commands from VOICE_TESTING_EXAMPLES.md
/// are properly mapped and execute correctly.
///
/// **Validates: Requirements 3.4, 5.4**
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/voice_command_executor.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/audio_feedback_engine.dart';
import 'test_data/voice_commands.dart';

import 'vision_command_mapping_test.mocks.dart';

@GenerateMocks([AudioFeedbackEngine])
void main() {
  group('Vision/Scanning Command Mapping Tests', () {
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

    test('should map "scan surroundings" to vision scan', () async {
      // Arrange
      const command = 'scan surroundings';

      // Act
      await executor.executeCommand(command);

      // Assert
      expect(navigatedRoutes, contains('/vision'));
      verify(mockAudioFeedback.speak(
        'Starting scan of your surroundings',
      )).called(1);
    });

    test('should map "what\'s in front of me" to vision scan', () async {
      // Arrange
      const command = 'what is in front';

      // Act
      await executor.executeCommand(command);

      // Assert
      expect(navigatedRoutes, contains('/vision'));
      verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
    });

    test('should map "detect obstacles" to obstacle detection', () async {
      // Arrange
      const command = 'detect obstacles';

      // Act
      await executor.executeCommand(command);

      // Assert
      expect(navigatedRoutes, contains('/vision'));
      verify(mockAudioFeedback.speak('Scanning for obstacles')).called(1);
    });

    test('should map "read text" to text reading', () async {
      // Arrange
      const command = 'read text';

      // Act
      await executor.executeCommand(command);

      // Assert
      expect(navigatedRoutes, contains('/vision'));
      verify(mockAudioFeedback.speak(
        'Ready to read text. Point your camera at the text',
      )).called(1);
    });

    test('should verify all vision commands from test data', () async {
      // Arrange
      final visionCommands = VoiceCommandTestData.visionCommands;

      // Act & Assert
      for (final testCase in visionCommands) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);

        // Re-setup mocks
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});

        await executor.executeCommand(testCase.command);

        // Verify navigation to vision page
        expect(
          navigatedRoutes,
          contains('/vision'),
          reason: 'Command "${testCase.command}" should navigate to vision',
        );

        // Verify audio feedback was provided
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('should provide appropriate audio feedback for vision commands',
        () async {
      // Test each vision command and verify feedback
      final testCases = [
        ('scan surroundings', 'Starting scan of your surroundings'),
        ('scan', 'Starting scan of your surroundings'),
        ('read text', 'Ready to read text'),
        ('detect obstacles', 'Scanning for obstacles'),
        ('identify people', 'Identifying people around you'),
        ('describe the scene', 'Analyzing your surroundings'),
      ];

      for (final (command, expectedFeedbackPart) in testCases) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        verify(mockAudioFeedback.speak(argThat(contains(expectedFeedbackPart))))
            .called(1);
      }
    });

    test('should map vision command variations correctly', () async {
      // Test command variations that should map to the same action
      final variations = [
        ('scan', FeatureAction.scan),
        ('scan surroundings', FeatureAction.scan),
        ('scan around', FeatureAction.scan),
        ('scan area', FeatureAction.scan),
        ('read text', FeatureAction.readText),
        ('read the text', FeatureAction.readText),
        ('read this', FeatureAction.readText),
        ('ocr', FeatureAction.readText),
        ('detect obstacles', FeatureAction.detectObstacles),
        ('are there obstacles', FeatureAction.detectObstacles),
        ('obstacles ahead', FeatureAction.detectObstacles),
        ('identify people', FeatureAction.identifyPeople),
        ('who is here', FeatureAction.identifyPeople),
        ('recognize person', FeatureAction.identifyPeople),
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

    test('should handle all vision feature actions', () async {
      // Test all vision-related actions
      final actions = [
        ('scan', FeatureAction.scan),
        ('read text', FeatureAction.readText),
        ('detect obstacles', FeatureAction.detectObstacles),
        ('identify people', FeatureAction.identifyPeople),
        ('analyze scene', FeatureAction.analyzeScene),
      ];

      for (final (command, expectedAction) in actions) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        // Verify navigation to vision page
        expect(
          navigatedRoutes,
          contains('/vision'),
          reason: 'Command "$command" should navigate to vision',
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

    test('should handle case-insensitive vision commands', () async {
      // Test that commands work regardless of case
      final casedCommands = [
        'SCAN SURROUNDINGS',
        'Read Text',
        'detect obstacles',
        'IDENTIFY PEOPLE',
        'Analyze Scene',
      ];

      for (final command in casedCommands) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        expect(
          navigatedRoutes,
          contains('/vision'),
          reason: 'Command "$command" should navigate to vision',
        );
      }
    });

    test('should handle vision commands with extra whitespace', () async {
      // Test that commands work with extra whitespace
      final commandsWithWhitespace = [
        '  scan surroundings  ',
        ' read text ',
        'detect obstacles   ',
        '   identify people',
      ];

      for (final command in commandsWithWhitespace) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        expect(
          navigatedRoutes,
          contains('/vision'),
          reason: 'Command "$command" should navigate to vision',
        );
      }
    });

    test('should navigate to vision for all vision commands', () async {
      // Verify all vision commands navigate to the vision page
      final commands = [
        'scan',
        'scan surroundings',
        'read text',
        'detect obstacles',
        'identify people',
        'analyze scene',
        'what is in front',
        'what is around me',
        'describe the scene',
      ];

      for (final command in commands) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        expect(
          navigatedRoutes,
          contains('/vision'),
          reason: 'Command "$command" should navigate to /vision',
        );
      }
    });
  });

  group('Vision Command Edge Cases', () {
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

    test('should handle partial vision commands', () async {
      // Test partial commands that might be recognized
      final partialCommands = [
        'scan',
        'read',
        'detect',
      ];

      for (final command in partialCommands) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        // Should provide some feedback
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('should handle ambiguous vision commands', () async {
      // Commands that might be ambiguous
      final ambiguousCommands = [
        'what',
        'describe',
        'analyze',
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

  group('Vision Command Integration', () {
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

    test('should handle sequence of vision commands', () async {
      // Test a sequence of vision commands
      final commandSequence = [
        'scan surroundings',
        'read text',
        'detect obstacles',
        'identify people',
      ];

      for (final command in commandSequence) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        expect(
          navigatedRoutes,
          contains('/vision'),
          reason: 'Command "$command" should navigate to vision',
        );
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('should provide distinct feedback for different vision actions',
        () async {
      // Verify that different actions provide different feedback
      final commands = [
        'scan surroundings',
        'read text',
        'detect obstacles',
        'identify people',
        'analyze scene',
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
