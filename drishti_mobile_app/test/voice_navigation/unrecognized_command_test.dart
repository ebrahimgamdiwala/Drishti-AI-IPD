/// Property-Based Test: Unrecognized Command Handling
///
/// **Property 5: Unrecognized Command Handling**
/// **Validates: Requirements 3.6, 3.7**
///
/// For any voice command that is not recognized (FeatureAction.unknown or
/// confidence < 0.65), the system should provide audio feedback asking the
/// user to rephrase or indicating the command was not understood.
library;

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/voice_command_executor.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/audio_feedback_engine.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/intent_classifier.dart';
import 'package:drishti_mobile_app/data/models/voice_navigation/classified_intent.dart';
import 'package:drishti_mobile_app/data/models/voice_navigation/intent_type.dart';

import 'unrecognized_command_test.mocks.dart';

@GenerateMocks([AudioFeedbackEngine])
void main() {
  group('Property Test: Unrecognized Command Handling', () {
    late MockAudioFeedbackEngine mockAudioFeedback;
    late VoiceCommandExecutor executor;
    late IntentClassifier classifier;

    setUp(() {
      mockAudioFeedback = MockAudioFeedbackEngine();

      // Mock audio feedback methods
      when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});
      when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});

      executor = VoiceCommandExecutor(
        audioFeedback: mockAudioFeedback,
      );

      classifier = IntentClassifier();
    });

    /// Generator for random invalid commands
    List<String> generateInvalidCommands(int count) {
      final random = Random(42); // Fixed seed for reproducibility
      final commands = <String>[];
      
      // Character sets for generating gibberish
      const letters = 'abcdefghijklmnopqrstuvwxyz';
      const numbers = '0123456789';
      const special = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
      
      for (int i = 0; i < count; i++) {
        final type = random.nextInt(5);
        String command;
        
        switch (type) {
          case 0: // Random letters
            final length = 5 + random.nextInt(10);
            command = List.generate(
              length,
              (_) => letters[random.nextInt(letters.length)],
            ).join();
            break;
            
          case 1: // Random numbers
            final length = 3 + random.nextInt(7);
            command = List.generate(
              length,
              (_) => numbers[random.nextInt(numbers.length)],
            ).join();
            break;
            
          case 2: // Random special characters
            final length = 3 + random.nextInt(7);
            command = List.generate(
              length,
              (_) => special[random.nextInt(special.length)],
            ).join();
            break;
            
          case 3: // Mixed gibberish
            final length = 5 + random.nextInt(10);
            final allChars = letters + numbers + ' ';
            command = List.generate(
              length,
              (_) => allChars[random.nextInt(allChars.length)],
            ).join();
            break;
            
          case 4: // Nonsense words
            final nonsenseWords = [
              'asdfghjkl', 'qwertyuiop', 'zxcvbnm', 'xyz', 'abc',
              'qwerty', 'zxcvbn', 'plugh', 'xyzzy', 'lorem ipsum',
              'dolor sit', 'consectetur', 'adipiscing', 'foobar',
              'bazqux', 'thingamajig', 'whatchamacallit',
            ];
            command = nonsenseWords[random.nextInt(nonsenseWords.length)];
            break;
            
          default:
            command = 'unknown';
        }
        
        commands.add(command);
      }
      
      return commands;
    }

    test('Property: All invalid commands receive "did not understand" feedback (100+ iterations)', () async {
      // Generate 100+ random invalid commands
      final invalidCommands = generateInvalidCommands(100);
      
      int iterationCount = 0;
      int feedbackCount = 0;
      
      for (final command in invalidCommands) {
        // Reset mocks for each iteration
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});
        
        // Execute the invalid command
        await executor.executeCommand(command);
        
        // Verify audio feedback was provided
        final speakCalls = verify(mockAudioFeedback.speak(captureAny)).captured;
        
        expect(
          speakCalls,
          isNotEmpty,
          reason: 'Invalid command "$command" should receive audio feedback',
        );
        
        // Verify the feedback message indicates the command was not understood
        final feedbackMessage = speakCalls.first as String;
        final isErrorFeedback = feedbackMessage.toLowerCase().contains('did not understand') ||
            feedbackMessage.toLowerCase().contains('not understand') ||
            feedbackMessage.toLowerCase().contains('sorry') ||
            feedbackMessage.toLowerCase().contains('rephrase');
        
        expect(
          isErrorFeedback,
          isTrue,
          reason: 'Feedback for "$command" should indicate command was not understood. Got: "$feedbackMessage"',
        );
        
        iterationCount++;
        if (isErrorFeedback) feedbackCount++;
      }
      
      // Verify we ran at least 100 iterations
      expect(
        iterationCount,
        greaterThanOrEqualTo(100),
        reason: 'Property test must run at least 100 iterations',
      );
      
      // Verify all commands received appropriate feedback
      expect(
        feedbackCount,
        equals(iterationCount),
        reason: 'All invalid commands should receive error feedback',
      );
      
      print('✓ Property test completed with $iterationCount iterations');
      print('✓ All $feedbackCount commands received appropriate error feedback');
    });

    test('Property: All gibberish commands have low confidence', () async {
      // Generate random gibberish commands (truly random, not real words)
      final random = Random(42);
      final gibberishCommands = <String>[];
      
      // Generate 50 truly random gibberish commands
      for (int i = 0; i < 50; i++) {
        final type = random.nextInt(3);
        String command;
        
        if (type == 0) {
          // Random letters
          final length = 5 + random.nextInt(10);
          command = List.generate(
            length,
            (_) => 'abcdefghijklmnopqrstuvwxyz'[random.nextInt(26)],
          ).join();
        } else if (type == 1) {
          // Random numbers
          final length = 3 + random.nextInt(7);
          command = List.generate(
            length,
            (_) => '0123456789'[random.nextInt(10)],
          ).join();
        } else {
          // Random special characters
          final length = 3 + random.nextInt(7);
          command = List.generate(
            length,
            (_) => '!@#\$%^&*()'[random.nextInt(10)],
          ).join();
        }
        
        gibberishCommands.add(command);
      }
      
      int lowConfidenceCount = 0;
      
      for (final command in gibberishCommands) {
        final intent = await classifier.classify(command);
        
        // Truly gibberish commands should have low confidence (< 0.65)
        if (intent.confidence < 0.65) {
          lowConfidenceCount++;
        }
        
        expect(
          intent.confidence,
          lessThan(0.65),
          reason: 'Gibberish command "$command" should have low confidence, got ${intent.confidence}',
        );
      }
      
      print('✓ All $lowConfidenceCount gibberish commands had low confidence');
    });

    test('should provide feedback for completely unknown command', () async {
      // Arrange
      const unknownCommand = 'asdfghjkl';

      // Act
      await executor.executeCommand(unknownCommand);

      // Assert - should provide "did not understand" feedback
      verify(mockAudioFeedback.speak('Sorry, I did not understand that command'))
          .called(1);
    });

    test('should provide feedback for gibberish command', () async {
      // Arrange
      const gibberishCommand = 'xyz abc 123';

      // Act
      await executor.executeCommand(gibberishCommand);

      // Assert
      verify(mockAudioFeedback.speak('Sorry, I did not understand that command'))
          .called(1);
    });

    test('should provide feedback for numeric command', () async {
      // Arrange
      const numericCommand = '12345';

      // Act
      await executor.executeCommand(numericCommand);

      // Assert
      verify(mockAudioFeedback.speak('Sorry, I did not understand that command'))
          .called(1);
    });

    test('should provide feedback for special characters command', () async {
      // Arrange
      const specialCommand = '@#\$%^&*()';

      // Act
      await executor.executeCommand(specialCommand);

      // Assert
      verify(mockAudioFeedback.speak('Sorry, I did not understand that command'))
          .called(1);
    });

    test('should provide feedback for empty command', () async {
      // Arrange
      const emptyCommand = '';

      // Act
      await executor.executeCommand(emptyCommand);

      // Assert - should provide some feedback
      verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
    });

    test('should classify truly ambiguous commands with low confidence', () async {
      // Commands that are genuinely unclear
      final ambiguousCommands = [
        'xyz',
        'asdf',
        '12345',
        '@#\$%',
      ];

      for (final command in ambiguousCommands) {
        final intent = await classifier.classify(command);

        // These gibberish commands should have low confidence
        expect(
          intent.confidence,
          lessThan(0.65),
          reason: 'Command "$command" should have low confidence',
        );
      }
    });

    test('should verify isConfident threshold is 0.65', () async {
      // Create intents with different confidence levels
      final testCases = [
        (0.64, false), // Just below threshold
        (0.65, true),  // At threshold
        (0.66, true),  // Above threshold
        (0.5, false),  // Well below
        (0.8, true),   // Well above
      ];

      for (final (confidence, expectedConfident) in testCases) {
        final intent = ClassifiedIntent(
          type: IntentType.navigation,
          confidence: confidence,
          parameters: {},
          originalCommand: 'test',
        );

        expect(
          intent.isConfident,
          equals(expectedConfident),
          reason: 'Confidence $confidence should be ${expectedConfident ? "confident" : "not confident"}',
        );
      }
    });

    test('should handle multiple unrecognized commands in sequence', () async {
      // Test that multiple unrecognized commands all get feedback
      final unknownCommands = [
        'xyz',
        'abc',
        '123',
        'qwerty',
        'zxcvbn',
      ];

      for (final command in unknownCommands) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        verify(mockAudioFeedback.speak('Sorry, I did not understand that command'))
            .called(1);
      }
    });

    test('should handle unrecognized command with valid words', () async {
      // Commands that contain valid words but don't match any pattern
      final ambiguousCommands = [
        'show me the thing',
        'do something',
        'make it work',
        'fix the problem',
      ];

      for (final command in ambiguousCommands) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        // Should provide feedback (either unknown or low confidence)
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('should handle case-insensitive unrecognized commands', () async {
      // Test that case doesn't affect unrecognized command handling
      final casedCommands = [
        'ASDFGHJKL',
        'AsdfGhjkl',
        'asdfghjkl',
      ];

      for (final command in casedCommands) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        verify(mockAudioFeedback.speak('Sorry, I did not understand that command'))
            .called(1);
      }
    });

    test('should handle unrecognized commands with whitespace', () async {
      // Test that whitespace doesn't affect unrecognized command handling
      final commandsWithWhitespace = [
        '  asdfghjkl  ',
        ' xyz abc ',
        'qwerty   ',
        '   zxcvbn',
      ];

      for (final command in commandsWithWhitespace) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        verify(mockAudioFeedback.speak('Sorry, I did not understand that command'))
            .called(1);
      }
    });
  });

  group('Low Confidence Command Handling Tests', () {
    late IntentClassifier classifier;

    setUp(() {
      classifier = IntentClassifier();
    });

    test('should classify gibberish commands with low confidence', () async {
      // Commands that are complete gibberish
      final gibberishCommands = [
        'asdfghjkl',
        'qwertyuiop',
        'zxcvbnm',
        'xyz123',
      ];

      for (final command in gibberishCommands) {
        final intent = await classifier.classify(command);

        // These gibberish commands should have low confidence
        expect(
          intent.confidence,
          lessThan(0.65),
          reason: 'Command "$command" should have low confidence',
        );
      }
    });

    test('should classify empty command with zero confidence', () async {
      // Empty command should have zero confidence
      const emptyCommand = '';

      final intent = await classifier.classify(emptyCommand);

      expect(
        intent.confidence,
        equals(0.0),
        reason: 'Empty command should have zero confidence',
      );
    });
  });

  group('Audio Feedback Content Tests', () {
    late MockAudioFeedbackEngine mockAudioFeedback;
    late VoiceCommandExecutor executor;

    setUp(() {
      mockAudioFeedback = MockAudioFeedbackEngine();
      when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

      executor = VoiceCommandExecutor(
        audioFeedback: mockAudioFeedback,
      );
    });

    test('should provide clear "did not understand" message', () async {
      // Arrange
      const unknownCommand = 'xyz';

      // Act
      await executor.executeCommand(unknownCommand);

      // Assert - verify exact message
      verify(mockAudioFeedback.speak('Sorry, I did not understand that command'))
          .called(1);
    });

    test('should provide consistent feedback for all unknown commands', () async {
      // Test that all unknown commands get the same feedback message
      final unknownCommands = ['abc', '123', 'xyz', 'qwerty'];

      for (final command in unknownCommands) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(command);

        // All should get the same message
        verify(mockAudioFeedback.speak('Sorry, I did not understand that command'))
            .called(1);
      }
    });
  });
}
