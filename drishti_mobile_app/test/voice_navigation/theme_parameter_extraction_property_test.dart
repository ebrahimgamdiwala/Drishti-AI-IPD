/// Theme Parameter Extraction Property Test
///
/// **Property 11: Theme Parameter Extraction**
/// **Validates: Requirements 6.5**
///
/// For any theme-related voice command, the IntentClassifier should extract
/// the correct parameters (action='toggle' for toggle commands, value='dark'
/// for dark mode, value='light' for light mode).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/intent_classifier.dart';
import 'package:drishti_mobile_app/data/models/voice_navigation/voice_navigation_models.dart';

void main() {
  group('Property 11: Theme Parameter Extraction', () {
    late IntentClassifier classifier;

    setUp(() {
      classifier = IntentClassifier();
    });

    /// Test data: theme commands with expected parameters
    final toggleCommands = [
      'change theme',
      'toggle theme',
      'switch theme',
      'CHANGE THEME',
      'Toggle Theme',
      'SwitCH ThEMe',
    ];

    final darkModeCommands = [
      'dark mode',
      'enable dark mode',
      'turn on dark mode',
      'set dark mode',
      'use dark mode',
      'DARK MODE',
      'Dark Mode',
      'DaRk MoDe',
    ];

    final lightModeCommands = [
      'light mode',
      'enable light mode',
      'turn on light mode',
      'set light mode',
      'use light mode',
      'LIGHT MODE',
      'Light Mode',
      'LiGhT MoDe',
    ];

    group('Toggle Theme Parameter Extraction', () {
      test('all toggle commands should extract action=toggle', () async {
        for (final command in toggleCommands) {
          final result = await classifier.classify(command);
          
          expect(
            result.type,
            equals(IntentType.settings),
            reason: 'Command "$command" should be classified as settings',
          );
          
          expect(
            result.parameters['setting'],
            equals('theme'),
            reason: 'Command "$command" should have setting=theme',
          );
          
          expect(
            result.parameters['action'],
            equals('toggle'),
            reason: 'Command "$command" should have action=toggle',
          );
          
          expect(
            result.parameters.containsKey('value'),
            isFalse,
            reason: 'Toggle command "$command" should not have value parameter',
          );
        }
      });
    });

    group('Dark Mode Parameter Extraction', () {
      test('all dark mode commands should extract value=dark', () async {
        for (final command in darkModeCommands) {
          final result = await classifier.classify(command);
          
          expect(
            result.type,
            equals(IntentType.settings),
            reason: 'Command "$command" should be classified as settings',
          );
          
          expect(
            result.parameters['setting'],
            equals('theme'),
            reason: 'Command "$command" should have setting=theme',
          );
          
          expect(
            result.parameters['value'],
            equals('dark'),
            reason: 'Command "$command" should have value=dark',
          );
        }
      });
    });

    group('Light Mode Parameter Extraction', () {
      test('all light mode commands should extract value=light', () async {
        for (final command in lightModeCommands) {
          final result = await classifier.classify(command);
          
          expect(
            result.type,
            equals(IntentType.settings),
            reason: 'Command "$command" should be classified as settings',
          );
          
          expect(
            result.parameters['setting'],
            equals('theme'),
            reason: 'Command "$command" should have setting=theme',
          );
          
          expect(
            result.parameters['value'],
            equals('light'),
            reason: 'Command "$command" should have value=light',
          );
        }
      });
    });

    group('Parameter Consistency', () {
      test('toggle commands should never have value parameter', () async {
        for (final command in toggleCommands) {
          final result = await classifier.classify(command);
          
          expect(
            result.parameters.containsKey('value'),
            isFalse,
            reason: 'Toggle command "$command" should not have value parameter',
          );
        }
      });

      test('dark mode commands should always have value=dark', () async {
        for (final command in darkModeCommands) {
          final result = await classifier.classify(command);
          
          expect(
            result.parameters['value'],
            equals('dark'),
            reason: 'Dark mode command "$command" should have value=dark',
          );
        }
      });

      test('light mode commands should always have value=light', () async {
        for (final command in lightModeCommands) {
          final result = await classifier.classify(command);
          
          expect(
            result.parameters['value'],
            equals('light'),
            reason: 'Light mode command "$command" should have value=light',
          );
        }
      });
    });

    group('High Confidence for All Theme Commands', () {
      test('all toggle commands should have confidence >= 0.65', () async {
        for (final command in toggleCommands) {
          final result = await classifier.classify(command);
          
          expect(
            result.confidence,
            greaterThanOrEqualTo(0.65),
            reason: 'Command "$command" should have confidence >= 0.65, got ${result.confidence}',
          );
        }
      });

      test('all dark mode commands should have confidence >= 0.65', () async {
        for (final command in darkModeCommands) {
          final result = await classifier.classify(command);
          
          expect(
            result.confidence,
            greaterThanOrEqualTo(0.65),
            reason: 'Command "$command" should have confidence >= 0.65, got ${result.confidence}',
          );
        }
      });

      test('all light mode commands should have confidence >= 0.65', () async {
        for (final command in lightModeCommands) {
          final result = await classifier.classify(command);
          
          expect(
            result.confidence,
            greaterThanOrEqualTo(0.65),
            reason: 'Command "$command" should have confidence >= 0.65, got ${result.confidence}',
          );
        }
      });
    });

    group('Property Validation Summary', () {
      test('should validate all theme commands with correct parameter extraction', () async {
        int totalCommands = 0;
        int correctParameterExtractions = 0;
        int highConfidenceClassifications = 0;

        // Test toggle commands
        for (final command in toggleCommands) {
          totalCommands++;
          final result = await classifier.classify(command);

          if (result.parameters['setting'] == 'theme' &&
              result.parameters['action'] == 'toggle' &&
              !result.parameters.containsKey('value')) {
            correctParameterExtractions++;
          }

          if (result.confidence >= 0.65) {
            highConfidenceClassifications++;
          }
        }

        // Test dark mode commands
        for (final command in darkModeCommands) {
          totalCommands++;
          final result = await classifier.classify(command);

          if (result.parameters['setting'] == 'theme' &&
              result.parameters['value'] == 'dark') {
            correctParameterExtractions++;
          }

          if (result.confidence >= 0.65) {
            highConfidenceClassifications++;
          }
        }

        // Test light mode commands
        for (final command in lightModeCommands) {
          totalCommands++;
          final result = await classifier.classify(command);

          if (result.parameters['setting'] == 'theme' &&
              result.parameters['value'] == 'light') {
            correctParameterExtractions++;
          }

          if (result.confidence >= 0.65) {
            highConfidenceClassifications++;
          }
        }

        // All commands should have correct parameter extraction
        expect(
          correctParameterExtractions,
          equals(totalCommands),
          reason: 'All $totalCommands theme commands should have correct parameter extraction',
        );

        // All commands should have high confidence
        expect(
          highConfidenceClassifications,
          equals(totalCommands),
          reason: 'All $totalCommands theme commands should have confidence >= 0.65',
        );

        // Print summary
        print('\n=== Theme Parameter Extraction Property Test Summary ===');
        print('Total theme commands tested: $totalCommands');
        print('  - Toggle commands: ${toggleCommands.length}');
        print('  - Dark mode commands: ${darkModeCommands.length}');
        print('  - Light mode commands: ${lightModeCommands.length}');
        print('Correct parameter extractions: $correctParameterExtractions');
        print('High confidence classifications: $highConfidenceClassifications');
        print('Parameter extraction accuracy: ${(correctParameterExtractions / totalCommands * 100).toStringAsFixed(1)}%');
        print('High confidence rate: ${(highConfidenceClassifications / totalCommands * 100).toStringAsFixed(1)}%');
      });
    });
  });
}
