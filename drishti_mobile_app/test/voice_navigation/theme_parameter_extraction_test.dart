/// Theme Parameter Extraction Tests
///
/// Tests to verify that theme commands correctly extract parameters
/// for toggle, dark mode, and light mode actions.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/intent_classifier.dart';
import 'package:drishti_mobile_app/data/models/voice_navigation/voice_navigation_models.dart';

void main() {
  group('Theme Parameter Extraction', () {
    late IntentClassifier classifier;

    setUp(() {
      classifier = IntentClassifier();
    });

    group('Toggle Theme Commands', () {
      test('should extract action=toggle for "change theme"', () async {
        final result = await classifier.classify('change theme');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['action'], equals('toggle'));
        expect(result.parameters.containsKey('value'), isFalse);
      });

      test('should extract action=toggle for "toggle theme"', () async {
        final result = await classifier.classify('toggle theme');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['action'], equals('toggle'));
        expect(result.parameters.containsKey('value'), isFalse);
      });

      test('should extract action=toggle for "switch theme"', () async {
        final result = await classifier.classify('switch theme');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['action'], equals('toggle'));
        expect(result.parameters.containsKey('value'), isFalse);
      });
    });

    group('Dark Mode Commands', () {
      test('should extract value=dark for "dark mode"', () async {
        final result = await classifier.classify('dark mode');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['value'], equals('dark'));
        expect(result.parameters.containsKey('action'), isFalse);
      });

      test('should extract value=dark for "enable dark mode"', () async {
        final result = await classifier.classify('enable dark mode');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['value'], equals('dark'));
      });

      test('should extract value=dark for "turn on dark mode"', () async {
        final result = await classifier.classify('turn on dark mode');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['value'], equals('dark'));
      });

      test('should extract value=dark for "set dark mode"', () async {
        final result = await classifier.classify('set dark mode');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['value'], equals('dark'));
      });

      test('should extract value=dark for "use dark mode"', () async {
        final result = await classifier.classify('use dark mode');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['value'], equals('dark'));
      });
    });

    group('Light Mode Commands', () {
      test('should extract value=light for "light mode"', () async {
        final result = await classifier.classify('light mode');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['value'], equals('light'));
        expect(result.parameters.containsKey('action'), isFalse);
      });

      test('should extract value=light for "enable light mode"', () async {
        final result = await classifier.classify('enable light mode');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['value'], equals('light'));
      });

      test('should extract value=light for "turn on light mode"', () async {
        final result = await classifier.classify('turn on light mode');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['value'], equals('light'));
      });

      test('should extract value=light for "set light mode"', () async {
        final result = await classifier.classify('set light mode');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['value'], equals('light'));
      });

      test('should extract value=light for "use light mode"', () async {
        final result = await classifier.classify('use light mode');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['value'], equals('light'));
      });
    });

    group('Case Insensitivity', () {
      test('should extract parameters from "DARK MODE"', () async {
        final result = await classifier.classify('DARK MODE');
        
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['value'], equals('dark'));
      });

      test('should extract parameters from "Light Mode"', () async {
        final result = await classifier.classify('Light Mode');
        
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['value'], equals('light'));
      });

      test('should extract parameters from "Toggle Theme"', () async {
        final result = await classifier.classify('Toggle Theme');
        
        expect(result.parameters['setting'], equals('theme'));
        expect(result.parameters['action'], equals('toggle'));
      });
    });

    group('Parameter Exclusivity', () {
      test('toggle commands should not have value parameter', () async {
        final toggleCommands = [
          'change theme',
          'toggle theme',
          'switch theme',
        ];

        for (final command in toggleCommands) {
          final result = await classifier.classify(command);
          expect(
            result.parameters.containsKey('value'),
            isFalse,
            reason: 'Toggle command "$command" should not have value parameter',
          );
          expect(
            result.parameters['action'],
            equals('toggle'),
            reason: 'Toggle command "$command" should have action=toggle',
          );
        }
      });

      test('dark/light mode commands should not have action parameter', () async {
        final modeCommands = [
          'dark mode',
          'light mode',
        ];

        for (final command in modeCommands) {
          final result = await classifier.classify(command);
          expect(
            result.parameters.containsKey('action'),
            isFalse,
            reason: 'Mode command "$command" should not have action parameter',
          );
          expect(
            result.parameters.containsKey('value'),
            isTrue,
            reason: 'Mode command "$command" should have value parameter',
          );
        }
      });
    });

    group('All Theme Commands', () {
      test('all theme commands should have setting=theme', () async {
        final themeCommands = [
          'change theme',
          'toggle theme',
          'dark mode',
          'enable dark mode',
          'light mode',
          'enable light mode',
          'switch theme',
          'set dark mode',
          'set light mode',
        ];

        for (final command in themeCommands) {
          final result = await classifier.classify(command);
          expect(
            result.parameters['setting'],
            equals('theme'),
            reason: 'Theme command "$command" should have setting=theme',
          );
        }
      });
    });
  });
}
