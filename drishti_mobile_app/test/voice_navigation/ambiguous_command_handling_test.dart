/// Ambiguous Command Handling Tests
///
/// Tests to verify that ambiguous commands (with multiple intent patterns)
/// are handled correctly by selecting the highest confidence intent or
/// returning low confidence when truly ambiguous.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/intent_classifier.dart';
import 'package:drishti_mobile_app/data/models/voice_navigation/voice_navigation_models.dart';

void main() {
  group('Ambiguous Command Handling', () {
    late IntentClassifier classifier;

    setUp(() {
      classifier = IntentClassifier();
    });

    group('Highest Confidence Selection', () {
      test('should select navigation for "go to settings" despite "settings" keyword', () async {
        // "go to" is a strong navigation pattern
        // "settings" could be settings intent, but navigation should win
        final result = await classifier.classify('go to settings');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should select settings for "increase volume" despite generic keywords', () async {
        // "volume" is a strong settings pattern
        final result = await classifier.classify('increase volume');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should select vision for "what is in front of me"', () async {
        // "what" and "in front" are vision patterns
        final result = await classifier.classify('what is in front of me');
        
        expect(result.type, equals(IntentType.vision));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should select relative for "who is near me"', () async {
        // "who" and "near" are relative patterns
        final result = await classifier.classify('who is near me');
        
        expect(result.type, equals(IntentType.relative));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });
    });

    group('Multiple Pattern Matches', () {
      test('should handle "show me settings" with both navigation and settings patterns', () async {
        // "show me" is navigation, "settings" is settings
        // Navigation should win because "show me" is a navigation action phrase
        final result = await classifier.classify('show me settings');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should handle "open volume settings" with navigation and settings patterns', () async {
        // "open" is navigation, "volume" and "settings" are settings
        // Settings should win because "volume" is a strong settings keyword
        final result = await classifier.classify('open volume settings');
        
        expect(result.type, equals(IntentType.settings));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should handle "scan for relatives" with vision and relative patterns', () async {
        // "scan" is vision, "relatives" is relative
        // Vision should win as it's the primary action
        final result = await classifier.classify('scan for relatives');
        
        expect(result.type, equals(IntentType.vision));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });
    });

    group('Clear Intent Dominance', () {
      test('emergency commands should dominate when "help" is present', () async {
        final result = await classifier.classify('help me');
        
        expect(result.type, equals(IntentType.emergency));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('emergency commands should dominate when "sos" is present', () async {
        final result = await classifier.classify('sos');
        
        expect(result.type, equals(IntentType.emergency));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('auth commands should dominate for "sign in"', () async {
        final result = await classifier.classify('sign in');
        
        expect(result.type, equals(IntentType.auth));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('system commands should dominate for "battery status"', () async {
        final result = await classifier.classify('battery status');
        
        expect(result.type, equals(IntentType.system));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });
    });

    group('Low Confidence for Truly Ambiguous Commands', () {
      test('should return low confidence for empty command', () async {
        final result = await classifier.classify('');
        
        expect(result.confidence, lessThan(0.65));
      });

      test('should return low confidence for gibberish', () async {
        final result = await classifier.classify('xyzabc123');
        
        expect(result.confidence, lessThan(0.65));
      });

      test('should return low confidence for unrecognized command', () async {
        final result = await classifier.classify('do something random');
        
        // This might match some patterns weakly, but should be low confidence
        // We're testing that it doesn't strongly match any intent
        expect(result.confidence, lessThan(0.80));
      });
    });

    group('Intent Priority Verification', () {
      test('should verify emergency has highest priority', () async {
        final result = await classifier.classify('help');
        
        expect(result.type, equals(IntentType.emergency));
        expect(result.priority, equals(100));
      });

      test('should verify vision has high priority', () async {
        final result = await classifier.classify('what is ahead');
        
        expect(result.type, equals(IntentType.vision));
        expect(result.priority, equals(50));
      });

      test('should verify navigation has medium priority', () async {
        final result = await classifier.classify('go home');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.priority, equals(30));
      });
    });

    group('Confidence Threshold Boundary', () {
      test('isConfident should be true for confidence >= 0.65', () async {
        final result = await classifier.classify('go to settings');
        
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.isConfident, isTrue);
      });

      test('isConfident should be false for confidence < 0.65', () async {
        final result = await classifier.classify('');
        
        expect(result.confidence, lessThan(0.65));
        expect(result.isConfident, isFalse);
      });
    });

    group('Command Normalization', () {
      test('should handle extra whitespace', () async {
        final result = await classifier.classify('  go   to   settings  ');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should handle mixed case', () async {
        final result = await classifier.classify('Go To SETTINGS');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });

      test('should handle tabs and newlines', () async {
        final result = await classifier.classify('go\tto\nsettings');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
      });
    });

    group('Consistent Classification', () {
      test('should classify same command consistently', () async {
        final results = <ClassifiedIntent>[];
        
        // Classify the same command multiple times
        for (int i = 0; i < 5; i++) {
          results.add(await classifier.classify('go to settings'));
        }
        
        // All results should have the same type and confidence
        for (final result in results) {
          expect(result.type, equals(IntentType.navigation));
          expect(result.confidence, equals(results.first.confidence));
        }
      });
    });
  });
}
