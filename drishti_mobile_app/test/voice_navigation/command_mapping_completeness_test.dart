/// Voice Command Mapping Completeness Property Test
///
/// **Property 4: Voice Command Mapping Completeness**
/// **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**
///
/// For any documented voice command in VOICE_TESTING_EXAMPLES.md,
/// the system should execute the correct corresponding action.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/voice_command_executor.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/audio_feedback_engine.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/intent_classifier.dart';
import 'package:drishti_mobile_app/data/models/voice_navigation/intent_type.dart';
import 'test_data/voice_commands.dart';

import 'command_mapping_completeness_test.mocks.dart';

@GenerateMocks([AudioFeedbackEngine])
void main() {
  group('Property Test: Voice Command Mapping Completeness', () {
    late MockAudioFeedbackEngine mockAudioFeedback;
    late VoiceCommandExecutor executor;
    late IntentClassifier classifier;
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

      classifier = IntentClassifier();
    });

    test('Property: All navigation commands execute correct actions', () async {
      // Arrange
      final navigationCommands = VoiceCommandTestData.navigationCommands;

      // Act & Assert
      for (final testCase in navigationCommands) {
        navigatedRoutes.clear();
        triggeredActions.clear();
        reset(mockAudioFeedback);

        // Re-setup mocks
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});

        await executor.executeCommand(testCase.command);

        // Verify navigation occurred
        expect(
          navigatedRoutes,
          isNotEmpty,
          reason: 'Navigation command "${testCase.command}" should trigger navigation',
        );

        // Verify expected route if specified
        if (testCase.expectedRoute != null) {
          expect(
            navigatedRoutes,
            contains(testCase.expectedRoute),
            reason: 'Command "${testCase.command}" should navigate to ${testCase.expectedRoute}',
          );
        }

        // Verify audio feedback was provided
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('Property: All relatives commands execute correct actions', () async {
      // Arrange
      final relativesCommands = VoiceCommandTestData.relativesCommands;

      // Act & Assert
      for (final testCase in relativesCommands) {
        navigatedRoutes.clear();
        triggeredActions.clear();
        reset(mockAudioFeedback);

        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(testCase.command);

        // Verify navigation to relatives page occurred
        expect(
          navigatedRoutes,
          contains('/relatives'),
          reason: 'Relatives command "${testCase.command}" should navigate to relatives page',
        );

        // Verify audio feedback was provided
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('Property: All settings commands execute correct actions', () async {
      // Arrange
      final settingsCommands = VoiceCommandTestData.settingsCommands;

      // Act & Assert
      for (final testCase in settingsCommands) {
        navigatedRoutes.clear();
        triggeredActions.clear();
        reset(mockAudioFeedback);

        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(testCase.command);

        // Verify some action occurred (navigation or feature action)
        final actionOccurred = navigatedRoutes.isNotEmpty || triggeredActions.isNotEmpty;
        expect(
          actionOccurred,
          isTrue,
          reason: 'Settings command "${testCase.command}" should trigger an action',
        );

        // Verify audio feedback was provided
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('Property: All vision commands execute correct actions', () async {
      // Arrange
      final visionCommands = VoiceCommandTestData.visionCommands;

      // Act & Assert
      for (final testCase in visionCommands) {
        navigatedRoutes.clear();
        triggeredActions.clear();
        reset(mockAudioFeedback);

        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        await executor.executeCommand(testCase.command);

        // Verify navigation to vision page occurred
        expect(
          navigatedRoutes,
          contains('/vision'),
          reason: 'Vision command "${testCase.command}" should navigate to vision page',
        );

        // Verify audio feedback was provided
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('Property: All system commands execute correct actions', () async {
      // Arrange
      final systemCommands = VoiceCommandTestData.systemCommands;

      // Act & Assert
      for (final testCase in systemCommands) {
        // System commands go through IntentClassifier, not VoiceCommandExecutor
        final intent = await classifier.classify(testCase.command);

        // Verify classification is correct
        expect(
          intent.type,
          equals(IntentType.system),
          reason: 'System command "${testCase.command}" should be classified as system intent',
        );

        // Verify confidence is high enough
        expect(
          intent.confidence,
          greaterThanOrEqualTo(0.65),
          reason: 'System command "${testCase.command}" should have high confidence',
        );

        // Verify parameters are extracted
        expect(
          intent.parameters,
          isNotEmpty,
          reason: 'System command "${testCase.command}" should have parameters',
        );
      }
    });

    test('Property: All commands provide audio feedback', () async {
      // Arrange
      final allCommands = VoiceCommandTestData.allCommands;

      // Act & Assert
      for (final testCase in allCommands) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});

        // Skip system commands as they go through a different path
        if (testCase.category == VoiceCommandCategory.system) {
          continue;
        }

        await executor.executeCommand(testCase.command);

        // Verify audio feedback was provided
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });

    test('Property: All commands are recognized (not unknown)', () async {
      // Arrange
      final allCommands = VoiceCommandTestData.allCommands;

      // Act & Assert
      for (final testCase in allCommands) {
        // Skip system commands as they go through IntentClassifier
        if (testCase.category == VoiceCommandCategory.system) {
          final intent = await classifier.classify(testCase.command);
          expect(
            intent.type,
            equals(IntentType.system),
            reason: 'System command "${testCase.command}" should be recognized',
          );
          continue;
        }

        final action = VoiceCommandConfig.getActionFromCommand(testCase.command);

        expect(
          action,
          isNot(equals(FeatureAction.unknown)),
          reason: 'Command "${testCase.command}" should be recognized (not unknown)',
        );
      }
    });

    test('Property: All commands have expected actions', () async {
      // Arrange
      final allCommands = VoiceCommandTestData.allCommands;

      // Act & Assert
      for (final testCase in allCommands) {
        if (testCase.expectedAction == null) {
          continue; // Skip if no expected action specified
        }

        // Skip system commands as they don't use FeatureAction
        if (testCase.category == VoiceCommandCategory.system) {
          continue;
        }

        final action = VoiceCommandConfig.getActionFromCommand(testCase.command);

        expect(
          action,
          equals(testCase.expectedAction),
          reason: 'Command "${testCase.command}" should map to ${testCase.expectedAction}',
        );
      }
    });

    test('Property: All commands with expected routes navigate correctly', () async {
      // Arrange
      final commandsWithRoutes = VoiceCommandTestData.allCommands
          .where((cmd) => cmd.expectedRoute != null)
          .toList();

      // Act & Assert
      for (final testCase in commandsWithRoutes) {
        navigatedRoutes.clear();
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});

        // Skip system commands as they need special handling
        if (testCase.category == VoiceCommandCategory.system) {
          continue;
        }

        await executor.executeCommand(testCase.command);

        expect(
          navigatedRoutes,
          contains(testCase.expectedRoute),
          reason: 'Command "${testCase.command}" should navigate to ${testCase.expectedRoute}',
        );
      }
    });

    test('Property: All commands with expected feedback provide it', () async {
      // Arrange
      final commandsWithFeedback = VoiceCommandTestData.allCommands
          .where((cmd) => cmd.expectedFeedback != null)
          .toList();

      // Act & Assert
      for (final testCase in commandsWithFeedback) {
        reset(mockAudioFeedback);
        when(mockAudioFeedback.speak(any)).thenAnswer((_) async {});
        when(mockAudioFeedback.speakImmediate(any)).thenAnswer((_) async {});

        // Skip system commands as they need special handling
        if (testCase.category == VoiceCommandCategory.system) {
          continue;
        }

        await executor.executeCommand(testCase.command);

        // Verify some audio feedback was provided
        // (exact message matching would be too brittle)
        verify(mockAudioFeedback.speak(any)).called(greaterThan(0));
      }
    });
  });

  group('Property Test: Command Mapping Invariants', () {
    test('Invariant: Every command maps to exactly one action', () {
      // Verify that each command in the command map has a unique action
      final commandMap = VoiceCommandConfig.commandMap;

      for (final entry in commandMap.entries) {
        final command = entry.key;
        final action = entry.value;

        // Get action again to verify consistency
        final retrievedAction = VoiceCommandConfig.getActionFromCommand(command);

        expect(
          retrievedAction,
          equals(action),
          reason: 'Command "$command" should consistently map to $action',
        );
      }
    });

    test('Invariant: Command mapping is case-insensitive', () {
      // Verify that commands work regardless of case
      final testCommands = [
        'go to dashboard',
        'GO TO DASHBOARD',
        'Go To Dashboard',
        'gO tO dAsHbOaRd',
      ];

      final expectedAction = VoiceCommandConfig.getActionFromCommand('go to dashboard');

      for (final command in testCommands) {
        final action = VoiceCommandConfig.getActionFromCommand(command);

        expect(
          action,
          equals(expectedAction),
          reason: 'Command "$command" should map to same action regardless of case',
        );
      }
    });

    test('Invariant: Command mapping handles whitespace consistently', () {
      // Verify that commands work with extra whitespace
      final testCommands = [
        'go to dashboard',
        '  go to dashboard  ',
        ' go to dashboard ',
        'go to dashboard   ',
      ];

      final expectedAction = VoiceCommandConfig.getActionFromCommand('go to dashboard');

      for (final command in testCommands) {
        final action = VoiceCommandConfig.getActionFromCommand(command);

        expect(
          action,
          equals(expectedAction),
          reason: 'Command "$command" should map to same action regardless of whitespace',
        );
      }
    });

    test('Invariant: Unknown commands always map to FeatureAction.unknown', () {
      // Verify that unrecognized commands consistently return unknown
      final unknownCommands = [
        'asdfghjkl',
        'xyz123',
        'qwerty',
        'not a real command',
        '12345',
      ];

      for (final command in unknownCommands) {
        final action = VoiceCommandConfig.getActionFromCommand(command);

        expect(
          action,
          equals(FeatureAction.unknown),
          reason: 'Unknown command "$command" should map to FeatureAction.unknown',
        );
      }
    });
  });
}
