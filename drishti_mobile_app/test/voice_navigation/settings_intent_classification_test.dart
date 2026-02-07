/// Settings Intent Classification Tests
///
/// Tests to verify that settings commands are correctly classified
/// with appropriate confidence levels.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/intent_classifier.dart';
import 'package:drishti_mobile_app/data/models/voice_navigation/voice_navigation_models.dart';

void main() {
  group('Settings Intent Classification', () {
    late IntentClassifier classifier;

    setUp(() {
      classifier = IntentClassifier();
    });

    group('Volume Commands', () {
      test('should classify "increase volume" as settings with high confidence', () async {
        final result = await classifier.classify('increase volume');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('volume'));
        expect(result.parameters['direction'], equals('up'));
      });

      test('should classify "decrease volume" as settings with high confidence', () async {
        final result = await classifier.classify('decrease volume');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('volume'));
        expect(result.parameters['direction'], equals('down'));
      });

      test('should classify "louder" as settings', () async {
        final result = await classifier.classify('louder');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('volume'));
        expect(result.parameters['direction'], equals('up'));
      });

      test('should classify "quieter" as settings', () async {
        final result = await classifier.classify('quieter');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('volume'));
        expect(result.parameters['direction'], equals('down'));
      });

      test('should classify "volume up" as settings', () async {
        final result = await classifier.classify('volume up');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('volume'));
        expect(result.parameters['direction'], equals('up'));
      });
    });

    group('Speech Speed Commands', () {
      test('should classify "speak faster" as settings with high confidence', () async {
        final result = await classifier.classify('speak faster');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('speechRate'));
        expect(result.parameters['direction'], equals('faster'));
      });

      test('should classify "speak slower" as settings with high confidence', () async {
        final result = await classifier.classify('speak slower');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('speechRate'));
        expect(result.parameters['direction'], equals('slower'));
      });

      test('should classify "increase speed" as settings', () async {
        final result = await classifier.classify('increase speed');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('speechRate'));
        expect(result.parameters['direction'], equals('faster'));
      });

      test('should classify "decrease speed" as settings', () async {
        final result = await classifier.classify('decrease speed');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('speechRate'));
        expect(result.parameters['direction'], equals('slower'));
      });
    });

    group('Theme Commands', () {
      test('should classify "change theme" as settings with high confidence', () async {
        final result = await classifier.classify('change theme');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['action'], equals('toggle'));
      });

      test('should classify "toggle theme" as settings with high confidence', () async {
        final result = await classifier.classify('toggle theme');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['action'], equals('toggle'));
      });

      test('should classify "dark mode" as settings with high confidence', () async {
        final result = await classifier.classify('dark mode');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['value'], equals('dark'));
      });

      test('should classify "enable dark mode" as settings with high confidence', () async {
        final result = await classifier.classify('enable dark mode');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['value'], equals('dark'));
      });

      test('should classify "light mode" as settings with high confidence', () async {
        final result = await classifier.classify('light mode');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['value'], equals('light'));
      });

      test('should classify "enable light mode" as settings with high confidence', () async {
        final result = await classifier.classify('enable light mode');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['value'], equals('light'));
      });
    });

    group('Emergency Contact Commands', () {
      test('should classify "emergency contact" as settings with high confidence', () async {
        final result = await classifier.classify('emergency contact');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('emergencyContact'));
        expect(result.parameters['action'], equals('set'));
      });

      test('should classify "set emergency contact" as settings', () async {
        final result = await classifier.classify('set emergency contact');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('emergencyContact'));
      });
    });

    group('Vibration Commands', () {
      test('should classify "enable vibration" as settings', () async {
        final result = await classifier.classify('enable vibration');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('vibration'));
        expect(result.parameters['action'], equals('enable'));
      });

      test('should classify "disable vibration" as settings', () async {
        final result = await classifier.classify('disable vibration');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('vibration'));
        expect(result.parameters['action'], equals('disable'));
      });

      test('should classify "turn on haptic" as settings', () async {
        final result = await classifier.classify('turn on haptic');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('vibration'));
        expect(result.parameters['action'], equals('enable'));
      });

      test('should classify "turn off haptic" as settings', () async {
        final result = await classifier.classify('turn off haptic');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('vibration'));
        expect(result.parameters['action'], equals('disable'));
      });
    });

    group('Language Commands', () {
      test('should classify "change language" as settings', () async {
        final result = await classifier.classify('change language');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('language'));
      });

      test('should classify "set language" as settings', () async {
        final result = await classifier.classify('set language');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['setting'], equals('language'));
      });
    });

    group('Selection Commands', () {
      test('should classify "select first" as settings', () async {
        final result = await classifier.classify('select first');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['action'], equals('select'));
        expect(result.parameters['index'], equals(0));
      });

      test('should classify "choose second" as settings', () async {
        final result = await classifier.classify('choose second');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['action'], equals('select'));
        expect(result.parameters['index'], equals(1));
      });

      test('should classify "pick third" as settings', () async {
        final result = await classifier.classify('pick third');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['action'], equals('select'));
        expect(result.parameters['index'], equals(2));
      });
    });

    group('Case Insensitivity', () {
      test('should classify "INCREASE VOLUME" as settings', () async {
        final result = await classifier.classify('INCREASE VOLUME');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should classify "Dark Mode" as settings', () async {
        final result = await classifier.classify('Dark Mode');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });
    });

    group('Confidence Threshold Validation', () {
      test('all settings commands should meet minimum confidence threshold', () async {
        final commands = [
          'increase volume',
          'speak faster',
          'change theme',
          'dark mode',
          'light mode',
          'emergency contact',
          'enable vibration',
          'change language',
          'louder',
          'quieter',
          'faster',
          'slower',
        ];

        for (final command in commands) {
          final result = await classifier.classify(command);
          expect(
            result.confidence,
            greaterThanOrEqualTo(0.65),
            reason: 'Command "$command" should have confidence >= 0.65, got ${result.confidence}',
          );
        }
      });
    });
  });
}
