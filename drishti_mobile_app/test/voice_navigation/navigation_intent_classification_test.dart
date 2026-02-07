/// Navigation Intent Classification Tests
///
/// Tests to verify that navigation commands are correctly classified
/// with appropriate confidence levels.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/intent_classifier.dart';
import 'package:drishti_mobile_app/data/models/voice_navigation/voice_navigation_models.dart';

void main() {
  group('Navigation Intent Classification', () {
    late IntentClassifier classifier;

    setUp(() {
      classifier = IntentClassifier();
    });

    group('Basic Navigation Commands', () {
      test('should classify "go to settings" as navigation with high confidence', () async {
        final result = await classifier.classify('go to settings');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['screen'], equals('settings'));
      });

      test('should classify "go to dashboard" as navigation with high confidence', () async {
        final result = await classifier.classify('go to dashboard');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['screen'], equals('dashboard'));
      });

      test('should classify "go to relatives" as navigation with high confidence', () async {
        final result = await classifier.classify('go to relatives');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['screen'], equals('relatives'));
      });

      test('should classify "go home" as navigation with high confidence', () async {
        final result = await classifier.classify('go home');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['screen'], equals('home'));
      });
    });

    group('Alternative Navigation Keywords', () {
      test('should classify "open settings" as navigation', () async {
        final result = await classifier.classify('open settings');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['screen'], equals('settings'));
      });

      test('should classify "navigate to dashboard" as navigation', () async {
        final result = await classifier.classify('navigate to dashboard');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['screen'], equals('dashboard'));
      });

      test('should classify "show me relatives" as navigation', () async {
        final result = await classifier.classify('show me relatives');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['screen'], equals('relatives'));
      });

      test('should classify "take me to profile" as navigation', () async {
        final result = await classifier.classify('take me to profile');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['screen'], equals('profile'));
      });

      test('should classify "switch to activity" as navigation', () async {
        final result = await classifier.classify('switch to activity');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['screen'], equals('activity'));
      });
    });

    group('Back and Home Commands', () {
      test('should classify "go back" as navigation', () async {
        final result = await classifier.classify('go back');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['action'], equals('back'));
      });

      test('should classify "back" as navigation', () async {
        final result = await classifier.classify('back');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['action'], equals('back'));
      });

      test('should classify "main screen" as navigation', () async {
        final result = await classifier.classify('main screen');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['screen'], equals('home'));
      });
    });

    group('Screen Name Variations', () {
      test('should classify "go to family" as navigation to relatives', () async {
        final result = await classifier.classify('go to family');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['screen'], equals('family'));
      });

      test('should classify "go to history" as navigation to activity', () async {
        final result = await classifier.classify('go to history');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['screen'], equals('history'));
      });

      test('should classify "go to camera" as navigation to vision', () async {
        final result = await classifier.classify('go to camera');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['screen'], equals('camera'));
      });
    });

    group('Case Insensitivity', () {
      test('should classify "GO TO SETTINGS" as navigation', () async {
        final result = await classifier.classify('GO TO SETTINGS');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['screen'], equals('settings'));
      });

      test('should classify "Go To Dashboard" as navigation', () async {
        final result = await classifier.classify('Go To Dashboard');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['screen'], equals('dashboard'));
      });
    });

    group('Extra Whitespace Handling', () {
      test('should classify "  go to   settings  " as navigation', () async {
        final result = await classifier.classify('  go to   settings  ');
        
        expect(result.type, equals(IntentType.navigation));
        expect(result.confidence, greaterThanOrEqualTo(0.65));
        expect(result.parameters['screen'], equals('settings'));
      });
    });

    group('Route Parameter Extraction', () {
      test('should extract correct route for settings', () async {
        final result = await classifier.classify('go to settings');
        
        expect(result.parameters['route'], equals('/settings'));
      });

      test('should extract correct route for dashboard', () async {
        final result = await classifier.classify('go to dashboard');
        
        expect(result.parameters['route'], equals('/dashboard'));
      });

      test('should extract correct route for home', () async {
        final result = await classifier.classify('go home');
        
        expect(result.parameters['route'], equals('/home'));
      });
    });

    group('Confidence Threshold Validation', () {
      test('all navigation commands should meet minimum confidence threshold', () async {
        final commands = [
          'go to settings',
          'open dashboard',
          'navigate to relatives',
          'show me profile',
          'take me to activity',
          'go back',
          'home',
          'main screen',
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
