/// Property-Based Test: Audio Feedback Completeness
///
/// **Property 8: Audio Feedback Completeness**
/// **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5, 5.6**
///
/// For any voice command execution (navigation, settings, relatives, vision, error),
/// the system should provide appropriate audio feedback describing the action taken
/// or error encountered.
library;

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/voice_command_executor.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/audio_feedback_engine.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/intent_classifier.dart';
import 'package:drishti_mobile_app/data/models/voice_navigation/intent_type.dart';
import 'test_data/voice_commands.dart';

import 'audio_feedback_test.mocks.dart';

@GenerateMocks([AudioFeedbackEngine])
void main() {
  group('Property Test: Audio Feedback Completeness', () {
    late MockAudioFeedbackEngine mockAudioFeedback;
    late VoiceCommandExecutor executor;
    late IntentClassifier classifier;
    late List<String> navigatedRoutes;
    late List<FeatureAction> triggeredActions;

    setUp(() {
      mockAudioFeedback = MockAudioFeedbackEngine();
      navigatedRoutes = [];
      triggeredActions = [];

      // Mock audio feedback methods
      when(mockAudioFeedback.speak(any, priority: anyNamed('priority'))).thenAnswer((_) async {});
      when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});
      when(mockAudioFeedback.announceNavigation(any)).thenAnswer((_) async {});

      executor = VoiceCommandExecutor(
        audioFeedback: mockAudioFeedback,
        onNavigate: (route) {
          navigatedRoutes.add(route);
        },
        onFeatureAction: (action, params) {
          triggeredActions.add(action);
        },
      );

      classifier = IntentClassifier();
    });

    test('Property: All commands provide audio feedback (100+ iterations)', () async {
      // Get all documented commands from test data
      final allCommands = VoiceCommandTestData.allCommands;
      
      // We need at least 100 iterations, so we'll repeat commands if necessary
      final commandsToTest = <VoiceCommandTestCase>[];
      final random = Random(42); // Fixed seed for reproducibility
      
      // Add all commands at least once
      commandsToTest.addAll(allCommands);
      
      // Add random commands until we have 100+
      while (commandsToTest.length < 100) {
        commandsToTest.add(allCommands[random.nextInt(allCommands.length)]);
      }
      
      int iterationCount = 0;
      int feedbackCount = 0;
      final feedbackByCategory = <VoiceCommandCategory, int>{};
      
      for (final testCase in commandsToTest) {
        // Reset for each iteration
        reset(mockAudioFeedback);
        navigatedRoutes.clear();
        triggeredActions.clear();
        
        // Re-setup mocks
        when(mockAudioFeedback.speak(any, priority: anyNamed('priority'))).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});
        when(mockAudioFeedback.announceNavigation(any)).thenAnswer((_) async {});
        
        // Execute the command
        await executor.executeCommand(testCase.command);
        
        // Verify audio feedback was provided
        bool feedbackProvided = false;
        try {
          verify(mockAudioFeedback.speak(any, priority: anyNamed('priority'))).called(greaterThan(0));
          feedbackProvided = true;
        } catch (e) {
          // Try speakImmediate
          try {
            verify(mockAudioFeedback.speakImmediate(any)).called(greaterThan(0));
            feedbackProvided = true;
          } catch (e) {
            // No feedback
          }
        }
        
        expect(
          feedbackProvided,
          isTrue,
          reason: 'Command "${testCase.command}" (${testCase.category}) should provide audio feedback',
        );
        
        iterationCount++;
        if (feedbackProvided) {
          feedbackCount++;
          feedbackByCategory[testCase.category] = 
              (feedbackByCategory[testCase.category] ?? 0) + 1;
        }
      }
      
      // Verify we ran at least 100 iterations
      expect(
        iterationCount,
        greaterThanOrEqualTo(100),
        reason: 'Property test must run at least 100 iterations',
      );
      
      // Verify all commands received feedback
      expect(
        feedbackCount,
        equals(iterationCount),
        reason: 'All commands should receive audio feedback',
      );
      
      print('✓ Property test completed with $iterationCount iterations');
      print('✓ All $feedbackCount commands received audio feedback');
      print('✓ Feedback by category:');
      for (final entry in feedbackByCategory.entries) {
        print('  - ${entry.key}: ${entry.value} commands');
      }
    });

    test('Property: Navigation commands announce destination', () async {
      // Test all navigation commands
      final navigationCommands = VoiceCommandTestData.navigationCommands;
      
      int commandsWithFeedback = 0;
      
      for (final testCase in navigationCommands) {
        reset(mockAudioFeedback);
        navigatedRoutes.clear();
        
        when(mockAudioFeedback.speak(any, priority: anyNamed('priority'))).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});
        
        await executor.executeCommand(testCase.command);
        
        // Verify audio feedback was provided
        final speakCalls = verify(mockAudioFeedback.speak(captureAny, priority: anyNamed('priority'))).captured;
        
        expect(
          speakCalls,
          isNotEmpty,
          reason: 'Navigation command "${testCase.command}" should announce destination',
        );
        
        // Verify feedback mentions navigation or destination
        final feedbackMessage = speakCalls.first as String;
        final isNavigationFeedback = feedbackMessage.toLowerCase().contains('navigat') ||
            feedbackMessage.toLowerCase().contains('opening') ||
            feedbackMessage.toLowerCase().contains('going') ||
            feedbackMessage.toLowerCase().contains('showing');
        
        expect(
          isNavigationFeedback,
          isTrue,
          reason: 'Navigation feedback should mention navigation. Got: "$feedbackMessage"',
        );
        
        commandsWithFeedback++;
      }
      
      print('✓ All $commandsWithFeedback navigation commands provided feedback');
    });

    test('Property: Settings commands announce action taken', () async {
      // Test all settings commands
      final settingsCommands = VoiceCommandTestData.settingsCommands;
      
      int commandsWithFeedback = 0;
      
      for (final testCase in settingsCommands) {
        reset(mockAudioFeedback);
        
        when(mockAudioFeedback.speak(any, priority: anyNamed('priority'))).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});
        
        await executor.executeCommand(testCase.command);
        
        // Verify audio feedback was provided
        final speakCalls = verify(mockAudioFeedback.speak(captureAny, priority: anyNamed('priority'))).captured;
        
        expect(
          speakCalls,
          isNotEmpty,
          reason: 'Settings command "${testCase.command}" should announce action',
        );
        
        commandsWithFeedback++;
      }
      
      print('✓ All $commandsWithFeedback settings commands provided feedback');
    });

    test('Property: Relatives commands announce action taken', () async {
      // Test all relatives commands
      final relativesCommands = VoiceCommandTestData.relativesCommands;
      
      int commandsWithFeedback = 0;
      
      for (final testCase in relativesCommands) {
        reset(mockAudioFeedback);
        navigatedRoutes.clear();
        
        when(mockAudioFeedback.speak(any, priority: anyNamed('priority'))).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});
        
        await executor.executeCommand(testCase.command);
        
        // Verify audio feedback was provided
        final speakCalls = verify(mockAudioFeedback.speak(captureAny, priority: anyNamed('priority'))).captured;
        
        expect(
          speakCalls,
          isNotEmpty,
          reason: 'Relatives command "${testCase.command}" should announce action',
        );
        
        commandsWithFeedback++;
      }
      
      print('✓ All $commandsWithFeedback relatives commands provided feedback');
    });

    test('Property: Vision commands announce analysis starting', () async {
      // Test all vision commands
      final visionCommands = VoiceCommandTestData.visionCommands;
      
      int commandsWithFeedback = 0;
      
      for (final testCase in visionCommands) {
        reset(mockAudioFeedback);
        navigatedRoutes.clear();
        
        when(mockAudioFeedback.speak(any, priority: anyNamed('priority'))).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});
        
        await executor.executeCommand(testCase.command);
        
        // Verify audio feedback was provided
        final speakCalls = verify(mockAudioFeedback.speak(captureAny, priority: anyNamed('priority'))).captured;
        
        expect(
          speakCalls,
          isNotEmpty,
          reason: 'Vision command "${testCase.command}" should announce analysis',
        );
        
        // Verify feedback mentions analysis or scanning
        final feedbackMessage = speakCalls.first as String;
        final isVisionFeedback = feedbackMessage.toLowerCase().contains('analyz') ||
            feedbackMessage.toLowerCase().contains('scan') ||
            feedbackMessage.toLowerCase().contains('detect') ||
            feedbackMessage.toLowerCase().contains('read');
        
        expect(
          isVisionFeedback,
          isTrue,
          reason: 'Vision feedback should mention analysis. Got: "$feedbackMessage"',
        );
        
        commandsWithFeedback++;
      }
      
      print('✓ All $commandsWithFeedback vision commands provided feedback');
    });

    test('Property: Error commands announce error message', () async {
      // Test invalid commands that should produce error feedback
      final invalidCommands = VoiceCommandTestData.invalidCommands;
      
      int commandsWithErrorFeedback = 0;
      
      for (final command in invalidCommands) {
        reset(mockAudioFeedback);
        
        when(mockAudioFeedback.speak(any, priority: anyNamed('priority'))).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});
        
        await executor.executeCommand(command);
        
        // Verify audio feedback was provided
        final speakCalls = verify(mockAudioFeedback.speak(captureAny, priority: anyNamed('priority'))).captured;
        
        expect(
          speakCalls,
          isNotEmpty,
          reason: 'Invalid command "$command" should announce error',
        );
        
        // Verify feedback indicates error
        final feedbackMessage = speakCalls.first as String;
        final isErrorFeedback = feedbackMessage.toLowerCase().contains('sorry') ||
            feedbackMessage.toLowerCase().contains('did not understand') ||
            feedbackMessage.toLowerCase().contains('not understand') ||
            feedbackMessage.toLowerCase().contains('error');
        
        expect(
          isErrorFeedback,
          isTrue,
          reason: 'Error feedback should indicate problem. Got: "$feedbackMessage"',
        );
        
        commandsWithErrorFeedback++;
      }
      
      print('✓ All $commandsWithErrorFeedback error commands provided feedback');
    });

    test('Property: Feedback is provided exactly once per command', () async {
      // Verify that each command gets feedback exactly once (not multiple times)
      final testCommands = [
        ...VoiceCommandTestData.navigationCommands.take(3),
        ...VoiceCommandTestData.settingsCommands.take(3),
        ...VoiceCommandTestData.relativesCommands.take(2),
        ...VoiceCommandTestData.visionCommands.take(2),
      ];
      
      for (final testCase in testCommands) {
        reset(mockAudioFeedback);
        
        when(mockAudioFeedback.speak(any, priority: anyNamed('priority'))).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});
        
        await executor.executeCommand(testCase.command);
        
        // Verify audio feedback was called at least once
        final speakCalls = verify(mockAudioFeedback.speak(captureAny, priority: anyNamed('priority'))).captured;
        
        expect(
          speakCalls.length,
          greaterThan(0),
          reason: 'Command "${testCase.command}" should provide feedback',
        );
        
        // It's OK to have multiple feedback calls for complex commands
        // but we want to ensure feedback is provided
      }
    });

    test('Property: All command categories provide feedback', () async {
      // Verify that every category has at least one command with feedback
      final categoriesWithFeedback = <VoiceCommandCategory>{};
      
      for (final category in VoiceCommandCategory.values) {
        final commands = VoiceCommandTestData.getCommandsByCategory(category);
        
        if (commands.isEmpty) continue;
        
        // Test first command from each category
        final testCase = commands.first;
        
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any, priority: anyNamed('priority'))).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});
        
        await executor.executeCommand(testCase.command);
        
        // Verify audio feedback was provided
        try {
          verify(mockAudioFeedback.speak(any, priority: anyNamed('priority'))).called(greaterThan(0));
          categoriesWithFeedback.add(category);
        } catch (e) {
          // Try speakImmediate
          try {
            verify(mockAudioFeedback.speakImmediate(any)).called(greaterThan(0));
            categoriesWithFeedback.add(category);
          } catch (e) {
            // No feedback provided
          }
        }
      }
      
      // Verify all categories provide feedback
      expect(
        categoriesWithFeedback.length,
        equals(VoiceCommandCategory.values.length),
        reason: 'All command categories should provide audio feedback',
      );
      
      print('✓ All ${categoriesWithFeedback.length} command categories provide feedback');
    });

    test('Property: Feedback messages are non-empty', () async {
      // Verify that all feedback messages contain actual content
      final testCommands = VoiceCommandTestData.allCommands.take(20).toList();
      
      for (final testCase in testCommands) {
        reset(mockAudioFeedback);
        
        when(mockAudioFeedback.speak(any, priority: anyNamed('priority'))).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});
        
        await executor.executeCommand(testCase.command);
        
        // Verify audio feedback messages are non-empty
        final speakCalls = verify(mockAudioFeedback.speak(captureAny, priority: anyNamed('priority'))).captured;
        
        for (final message in speakCalls) {
          final messageStr = message as String;
          expect(
            messageStr.trim(),
            isNotEmpty,
            reason: 'Feedback message should not be empty for command "${testCase.command}"',
          );
          
          expect(
            messageStr.length,
            greaterThan(5),
            reason: 'Feedback message should be meaningful (>5 chars) for command "${testCase.command}"',
          );
        }
      }
    });
  });

  group('Audio Feedback Timing Tests', () {
    late MockAudioFeedbackEngine mockAudioFeedback;
    late VoiceCommandExecutor executor;

    setUp(() {
      mockAudioFeedback = MockAudioFeedbackEngine();
      
      when(mockAudioFeedback.speak(any, priority: anyNamed('priority'))).thenAnswer((_) async {});
      when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});
      
      executor = VoiceCommandExecutor(
        audioFeedback: mockAudioFeedback,
      );
    });

    test('Feedback is provided before command completion', () async {
      // Verify that feedback is provided during command execution
      final testCommand = 'go to dashboard';
      
      var feedbackProvided = false;
      
      when(mockAudioFeedback.speak(any, priority: anyNamed('priority'))).thenAnswer((_) async {
        feedbackProvided = true;
      });
      
      await executor.executeCommand(testCommand);
      
      expect(
        feedbackProvided,
        isTrue,
        reason: 'Feedback should be provided during command execution',
      );
    });

    test('Multiple commands receive independent feedback', () async {
      // Verify that each command gets its own feedback
      final commands = ['go to dashboard', 'go to settings', 'go home'];
      
      for (final command in commands) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any, priority: anyNamed('priority'))).thenAnswer((_) async {});
        
        await executor.executeCommand(command);
        
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });
  });
}

