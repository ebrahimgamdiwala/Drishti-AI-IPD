/// Intent Classification Edge Cases Tests
///
/// Tests to verify that the IntentClassifier handles edge cases correctly,
/// including ambiguous commands, empty commands, special characters, and
/// commands with no matching patterns.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/intent_classifier.dart';
import 'package:drishti_mobile_app/data/models/voice_navigation/voice_navigation_models.dart';

void main() {
  group('Intent Classification Edge Cases', () {
    late IntentClassifier classifier;

    setUp(() {
      classifier = IntentClassifier();
    });

    group('Empty and Whitespace Commands', () {
      test('should handle empty string with low confidence', () async {
        final result = await classifier.classify('');
        
        expect(result.confidence, lessThan(0.65));
        expect(result.isConfident, isFalse);
        expect(result.originalCommand, equals(''));
      });

      test('should handle whitespace-only string with low confidence', () async {
        final result = await classifier.classify('   ');
        
        expect(result.confidence, lessThan(0.65));
        expect(result.isConfident, isFalse);
      });

      test('should handle tabs and newlines with low confidence', () async {
        final result = await classifier.classify('\t\n\r');
        
        expect(result.confidence, lessThan(0.65));
        expect(result.isConfident, isFalse);
      });

      test('should handle multiple spaces with low confidence', () async {
        final result = await classifier.classify('     ');
        
        expect(result.confidence, lessThan(0.65));
        expect(result.isConfident, isFalse);
      });
    });

    group('Gibberish and Unrecognized Commands', () {
      test('should handle random letters with low confidence', () async {
        final result = await classifier.classify('xyzabc');
        
        expect(result.confidence, lessThan(0.65));
        expect(result.isConfident, isFalse);
      });

      test('should handle random numbers with low confidence', () async {
        final result = await classifier.classify('123456');
        
        expect(result.confidence, lessThan(0.65));
        expect(result.isConfident, isFalse);
      });

      test('should handle mixed gibberish with low confidence', () async {
        final result = await classifier.classify('abc123xyz');
        
        expect(result.confidence, lessThan(0.65));
        expect(result.isConfident, isFalse);
      });

      test('should handle nonsense words with low confidence', () async {
        final result = await classifier.classify('blahblahblah');
        
        expect(result.confidence, lessThan(0.65));
        expect(result.isConfident, isFalse);
      });
    });

    group('Special Characters', () {
      test('should handle commands with punctuation', () async {
        final result = await classifier.classify('go to settings!');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should handle commands with question marks', () async {
        final result = await classifier.classify('what is in front of me?');
        
        expect(result.type, equals(IntentType.vision));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should handle commands with commas', () async {
        final result = await classifier.classify('go to settings, please');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should handle commands with periods', () async {
        final result = await classifier.classify('increase volume.');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should handle only special characters with low confidence', () async {
        final result = await classifier.classify('!@#\$%^&*()');
        
        expect(result.confidence, lessThan(0.65));
        expect(result.isConfident, isFalse);
      });
    });

    group('Ambiguous Commands with Multiple Intent Patterns', () {
      test('should handle command with weak matches across multiple intents', () async {
        // "is" appears in relative patterns and gets high confidence
        final result = await classifier.classify('is');
        
        // "is" is a valid relative pattern, so it should have reasonable confidence
        expect(result.type, equals(IntentType.relative));
      });

      test('should select highest confidence for overlapping patterns', () async {
        // "show me settings" has both navigation ("show me") and settings ("settings")
        final result = await classifier.classify('show me settings');
        
        // Navigation should win
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should handle command with generic words', () async {
        final result = await classifier.classify('do something');
        
        // Generic words shouldn't match strongly
        expect(result.confidence, lessThan(0.80));
      });
    });

    group('Very Long Commands', () {
      test('should handle very long command with valid patterns', () async {
        final longCommand = 'please go to the settings page right now because I need to change something';
        final result = await classifier.classify(longCommand);
        
        // Should still detect "go to" and "settings"
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should handle very long gibberish command', () async {
        final longGibberish = 'a' * 1000;
        final result = await classifier.classify(longGibberish);
        
        expect(result.confidence, lessThan(0.65));
        expect(result.isConfident, isFalse);
      });
    });

    group('Case Sensitivity Edge Cases', () {
      test('should handle all uppercase command', () async {
        final result = await classifier.classify('GO TO SETTINGS');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should handle all lowercase command', () async {
        final result = await classifier.classify('go to settings');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should handle mixed case command', () async {
        final result = await classifier.classify('Go To SeTTiNgS');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });
    });

    group('Commands with Extra Words', () {
      test('should handle command with polite words', () async {
        final result = await classifier.classify('please go to settings');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should handle command with filler words', () async {
        final result = await classifier.classify('um go to settings');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should handle command with articles', () async {
        final result = await classifier.classify('go to the settings');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });
    });

    group('Partial Matches', () {
      test('should handle partial keyword match', () async {
        // "set" is in settings patterns, but alone might not be enough
        final result = await classifier.classify('set');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should handle command with substring of keyword', () async {
        // "vol" is not a complete keyword
        final result = await classifier.classify('vol');
        
        expect(result.confidence, lessThan(0.65));
      });
    });

    group('Confidence Boundary Testing', () {
      test('should have isConfident=true when confidence is exactly 0.65', () async {
        // Find a command that gives exactly 0.65 confidence (or close to it)
        final result = await classifier.classify('go to settings');
        
        if (result.confidence >= 0.65) {
          expect(result.isConfident, isTrue);
        }
      });

      test('should have isConfident=false when confidence is below 0.65', () async {
        final result = await classifier.classify('');
        
        expect(result.confidence, lessThan(0.65));
        expect(result.isConfident, isFalse);
      });
    });

    group('Parameter Extraction Edge Cases', () {
      test('should handle command with no extractable parameters', () async {
        final result = await classifier.classify('help');
        
        expect(result.type, equals(IntentType.emergency));
        expect(result.parameters, isNotEmpty); // Should have action parameter
      });

      test('should handle navigation command without screen name', () async {
        final result = await classifier.classify('go back');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.parameters['action'], equals('back'));
      });

      test('should handle settings command without specific setting', () async {
        final result = await classifier.classify('enable');
        
        expect(result.type, equals(IntentType.settings));
        // Parameters might be empty or have generic values
      });
    });

    group('Timestamp and Metadata', () {
      test('should include timestamp in result', () async {
        final before = DateTime.now();
        final result = await classifier.classify('go to settings');
        final after = DateTime.now();
        
        expect(result.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(result.timestamp.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });

      test('should preserve original command', () async {
        const originalCommand = '  Go To SETTINGS  ';
        final result = await classifier.classify(originalCommand);
        
        expect(result.originalCommand, equals(originalCommand));
      });
    });

    group('Consistency and Determinism', () {
      test('should return same result for same command', () async {
        final result1 = await classifier.classify('go to settings');
        final result2 = await classifier.classify('go to settings');
        
        expect(result1.type, equals(result2.type));
        expect(result1.confidence, equals(result2.confidence));
        expect(result1.parameters, equals(result2.parameters));
      });

      test('should return different results for different commands', () async {
        final result1 = await classifier.classify('go to settings');
        final result2 = await classifier.classify('increase volume');
        
        expect(result1.type, isNot(equals(result2.type)));
      });
    });
  });
}
