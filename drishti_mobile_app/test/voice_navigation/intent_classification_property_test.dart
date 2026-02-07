/// Intent Classification Accuracy Property Test
///
/// **Property 9: Intent Classification Accuracy**
/// **Validates: Requirements 6.1, 6.2, 6.3**
///
/// For any voice command containing keywords from a specific intent category
/// (navigation, settings, vision, etc.), the IntentClassifier should classify
/// it with the correct IntentType and confidence >= 0.65.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/intent_classifier.dart';
import 'package:drishti_mobile_app/data/models/voice_navigation/voice_navigation_models.dart';

void main() {
  group('Property 9: Intent Classification Accuracy', () {
    late IntentClassifier classifier;

    setUp(() {
      classifier = IntentClassifier();
    });

    /// Test data: commands grouped by expected intent type
    /// Each command should be classified with the correct intent and confidence >= 0.65
    final testData = {
      IntentType.navigation: [
        'go to settings',
        'go to dashboard',
        'go to relatives',
        'go to profile',
        'go to activity',
        'go to history',
        'go to camera',
        'go to vision',
        'go home',
        'go back',
        'open settings',
        'open dashboard',
        'open relatives',
        'navigate to settings',
        'navigate to dashboard',
        'show me settings',
        'show me dashboard',
        'take me to settings',
        'take me to dashboard',
        'switch to settings',
        'switch to dashboard',
        'back',
        'home',
        'main screen',
      ],
      IntentType.settings: [
        'increase volume',
        'decrease volume',
        'louder',
        'quieter',
        'volume up',
        'volume down',
        'speak faster',
        'speak slower',
        'increase speed',
        'decrease speed',
        'faster',
        'slower',
        'change theme',
        'toggle theme',
        'switch theme',
        'dark mode',
        'light mode',
        'enable dark mode',
        'enable light mode',
        'turn on dark mode',
        'turn on light mode',
        'set dark mode',
        'set light mode',
        'emergency contact',
        'set emergency contact',
        'enable vibration',
        'disable vibration',
        'turn on vibration',
        'turn off vibration',
        'turn on haptic',
        'turn off haptic',
        'change language',
        'set language',
        'select first',
        'choose second',
        'pick third',
      ],
      IntentType.vision: [
        'what is in front of me',
        'what is ahead',
        'what do you see',
        'describe what you see',
        'describe the scene',
        'scan surroundings',
        'scan the area',
        'analyze the scene',
        'look around',
        'what obstacles are there',
        'detect obstacles',
        'read text',
        'read the text',
        'tell me more',
        'what else',
        'more details',
      ],
      IntentType.relative: [
        'who is near me',
        'who is nearby',
        'who is close',
        'recognize this person',
        'identify person',
        'add relative',
        'create relative',
        'new relative',
        'add family member',
        'save person',
        'remember this person',
        'delete relative',
        'remove relative',
        'edit relative',
        'update relative',
        'show all relatives',
        'list relatives',
      ],
      IntentType.auth: [
        'sign in',
        'log in',
        'sign up',
        'register',
        'log out',
        'sign out',
        'create account',
      ],
      IntentType.system: [
        'battery status',
        'battery level',
        'connection status',
        'am I connected',
        'am I online',
        'am I offline',
        'check connection',
        'refresh',
        'reload',
      ],
      IntentType.emergency: [
        'help',
        'help me',
        'emergency',
        'urgent',
        'sos',
        'call emergency contact',
      ],
    };

    group('Navigation Intent Classification', () {
      test('all navigation commands should be classified correctly with high confidence', () async {
        final commands = testData[IntentType.navigation]!;
        
        for (final command in commands) {
          final result = await classifier.classify(command);
          
          expect(
            result.type,
            equals(IntentType.navigation),
            reason: 'Command "$command" should be classified as navigation, got ${result.type.name}',
          );
          
          expect(
            result.confidence,
            greaterThanOrEqualTo(0.65),
            reason: 'Command "$command" should have confidence >= 0.65, got ${result.confidence}',
          );
        }
      });
    });

    group('Settings Intent Classification', () {
      test('all settings commands should be classified correctly with high confidence', () async {
        final commands = testData[IntentType.settings]!;
        
        for (final command in commands) {
          final result = await classifier.classify(command);
          
          expect(
            result.type,
            equals(IntentType.settings),
            reason: 'Command "$command" should be classified as settings, got ${result.type.name}',
          );
          
          expect(
            result.confidence,
            greaterThanOrEqualTo(0.65),
            reason: 'Command "$command" should have confidence >= 0.65, got ${result.confidence}',
          );
        }
      });
    });

    group('Vision Intent Classification', () {
      test('all vision commands should be classified correctly with high confidence', () async {
        final commands = testData[IntentType.vision]!;
        
        for (final command in commands) {
          final result = await classifier.classify(command);
          
          expect(
            result.type,
            equals(IntentType.vision),
            reason: 'Command "$command" should be classified as vision, got ${result.type.name}',
          );
          
          expect(
            result.confidence,
            greaterThanOrEqualTo(0.65),
            reason: 'Command "$command" should have confidence >= 0.65, got ${result.confidence}',
          );
        }
      });
    });

    group('Relative Intent Classification', () {
      test('all relative commands should be classified correctly with high confidence', () async {
        final commands = testData[IntentType.relative]!;
        
        for (final command in commands) {
          final result = await classifier.classify(command);
          
          expect(
            result.type,
            equals(IntentType.relative),
            reason: 'Command "$command" should be classified as relative, got ${result.type.name}',
          );
          
          expect(
            result.confidence,
            greaterThanOrEqualTo(0.65),
            reason: 'Command "$command" should have confidence >= 0.65, got ${result.confidence}',
          );
        }
      });
    });

    group('Auth Intent Classification', () {
      test('all auth commands should be classified correctly with high confidence', () async {
        final commands = testData[IntentType.auth]!;
        
        for (final command in commands) {
          final result = await classifier.classify(command);
          
          expect(
            result.type,
            equals(IntentType.auth),
            reason: 'Command "$command" should be classified as auth, got ${result.type.name}',
          );
          
          expect(
            result.confidence,
            greaterThanOrEqualTo(0.65),
            reason: 'Command "$command" should have confidence >= 0.65, got ${result.confidence}',
          );
        }
      });
    });

    group('System Intent Classification', () {
      test('all system commands should be classified correctly with high confidence', () async {
        final commands = testData[IntentType.system]!;
        
        for (final command in commands) {
          final result = await classifier.classify(command);
          
          expect(
            result.type,
            equals(IntentType.system),
            reason: 'Command "$command" should be classified as system, got ${result.type.name}',
          );
          
          expect(
            result.confidence,
            greaterThanOrEqualTo(0.65),
            reason: 'Command "$command" should have confidence >= 0.65, got ${result.confidence}',
          );
        }
      });
    });

    group('Emergency Intent Classification', () {
      test('all emergency commands should be classified correctly with high confidence', () async {
        final commands = testData[IntentType.emergency]!;
        
        for (final command in commands) {
          final result = await classifier.classify(command);
          
          expect(
            result.type,
            equals(IntentType.emergency),
            reason: 'Command "$command" should be classified as emergency, got ${result.type.name}',
          );
          
          expect(
            result.confidence,
            greaterThanOrEqualTo(0.65),
            reason: 'Command "$command" should have confidence >= 0.65, got ${result.confidence}',
          );
        }
      });
    });

    group('Property Validation Summary', () {
      test('should validate all test commands across all intent types', () async {
        int totalCommands = 0;
        int correctClassifications = 0;
        int highConfidenceClassifications = 0;

        for (final entry in testData.entries) {
          final expectedType = entry.key;
          final commands = entry.value;

          for (final command in commands) {
            totalCommands++;
            final result = await classifier.classify(command);

            if (result.type == expectedType) {
              correctClassifications++;
            }

            if (result.confidence >= 0.65) {
              highConfidenceClassifications++;
            }
          }
        }

        // All commands should be classified correctly
        expect(
          correctClassifications,
          equals(totalCommands),
          reason: 'All $totalCommands commands should be classified correctly',
        );

        // All commands should have high confidence
        expect(
          highConfidenceClassifications,
          equals(totalCommands),
          reason: 'All $totalCommands commands should have confidence >= 0.65',
        );

        // Print summary
        print('\n=== Intent Classification Property Test Summary ===');
        print('Total commands tested: $totalCommands');
        print('Correct classifications: $correctClassifications');
        print('High confidence classifications: $highConfidenceClassifications');
        print('Success rate: ${(correctClassifications / totalCommands * 100).toStringAsFixed(1)}%');
        print('High confidence rate: ${(highConfidenceClassifications / totalCommands * 100).toStringAsFixed(1)}%');
      });
    });
  });
}
