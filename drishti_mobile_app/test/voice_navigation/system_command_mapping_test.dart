/// System Information Command Mapping Tests
///
/// Verifies that system information commands from VOICE_TESTING_EXAMPLES.md
/// are properly classified and have correct parameters.
///
/// **Validates: Requirements 3.5, 5.5**
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/intent_classifier.dart';
import 'package:drishti_mobile_app/data/models/voice_navigation/intent_type.dart';
import 'test_data/voice_commands.dart';

void main() {
  group('System Information Command Classification Tests', () {
    late IntentClassifier classifier;

    setUp(() {
      classifier = IntentClassifier();
    });

    test('should classify "battery status" as system intent', () async {
      // Arrange
      const command = 'battery status';

      // Act
      final intent = await classifier.classify(command);

      // Assert
      expect(intent.type, equals(IntentType.system));
      expect(intent.confidence, greaterThanOrEqualTo(0.65));
      expect(intent.parameters['infoType'], equals('battery'));
    });

    test('should classify "am i online" as system intent', () async {
      // Arrange
      const command = 'am i online';

      // Act
      final intent = await classifier.classify(command);

      // Assert
      expect(intent.type, equals(IntentType.system));
      expect(intent.confidence, greaterThanOrEqualTo(0.65));
      expect(intent.parameters['infoType'], equals('connection'));
    });

    test('should verify all system commands from test data', () async {
      // Arrange
      final systemCommands = VoiceCommandTestData.systemCommands;

      // Act & Assert
      for (final testCase in systemCommands) {
        final intent = await classifier.classify(testCase.command);

        // Verify classification
        expect(
          intent.type,
          equals(IntentType.system),
          reason: 'Command "${testCase.command}" should be classified as system intent',
        );

        // Verify confidence
        expect(
          intent.confidence,
          greaterThanOrEqualTo(0.65),
          reason: 'Command "${testCase.command}" should have confidence >= 0.65',
        );

        // Verify parameters are extracted
        expect(
          intent.parameters,
          isNotEmpty,
          reason: 'Command "${testCase.command}" should have parameters',
        );
      }
    });

    test('should handle system command variations correctly', () async {
      // Test command variations for battery
      final batteryVariations = [
        'battery status',
        'check battery',
        'battery level',
      ];

      for (final command in batteryVariations) {
        final intent = await classifier.classify(command);

        expect(
          intent.type,
          equals(IntentType.system),
          reason: 'Command "$command" should be classified as system intent',
        );
        expect(
          intent.parameters['infoType'],
          equals('battery'),
          reason: 'Command "$command" should have infoType=battery',
        );
      }

      // Test command variations for connection
      final connectionVariations = [
        'connection status',
        'network status',
        'check connection',
        'am i online',
      ];

      for (final command in connectionVariations) {
        final intent = await classifier.classify(command);

        expect(
          intent.type,
          equals(IntentType.system),
          reason: 'Command "$command" should be classified as system intent',
        );
        expect(
          intent.parameters['infoType'],
          equals('connection'),
          reason: 'Command "$command" should have infoType=connection',
        );
      }
    });

    test('should handle case-insensitive system commands', () async {
      // Test that commands work regardless of case
      final casedCommands = [
        ('BATTERY STATUS', 'battery'),
        ('Battery Status', 'battery'),
        ('battery status', 'battery'),
        ('AM I ONLINE', 'connection'),
        ('Am I Online', 'connection'),
        ('am i online', 'connection'),
      ];

      for (final (command, expectedInfoType) in casedCommands) {
        final intent = await classifier.classify(command);

        expect(
          intent.type,
          equals(IntentType.system),
          reason: 'Command "$command" should be classified as system intent',
        );
        expect(
          intent.parameters['infoType'],
          equals(expectedInfoType),
          reason: 'Command "$command" should have infoType=$expectedInfoType',
        );
      }
    });

    test('should handle system commands with extra whitespace', () async {
      // Test that commands work with extra whitespace
      final commandsWithWhitespace = [
        ('  battery status  ', 'battery'),
        (' check battery ', 'battery'),
        ('am i online   ', 'connection'),
        ('   network status', 'connection'),
      ];

      for (final (command, expectedInfoType) in commandsWithWhitespace) {
        final intent = await classifier.classify(command);

        expect(
          intent.type,
          equals(IntentType.system),
          reason: 'Command "$command" should be classified as system intent',
        );
        expect(
          intent.parameters['infoType'],
          equals(expectedInfoType),
          reason: 'Command "$command" should have infoType=$expectedInfoType',
        );
      }
    });

    test('should classify system commands with high confidence', () async {
      // Test that system commands have confidence >= 0.65
      final systemCommands = [
        'battery status',
        'check battery',
        'battery level',
        'connection status',
        'network status',
        'check connection',
        'am i online',
      ];

      for (final command in systemCommands) {
        final intent = await classifier.classify(command);

        expect(
          intent.confidence,
          greaterThanOrEqualTo(0.65),
          reason: 'Command "$command" should have confidence >= 0.65',
        );
      }
    });

    test('should extract correct parameters for battery commands', () async {
      // Test parameter extraction for battery commands
      final batteryCommands = [
        'battery status',
        'check battery',
        'battery level',
      ];

      for (final command in batteryCommands) {
        final intent = await classifier.classify(command);

        expect(
          intent.parameters['infoType'],
          equals('battery'),
          reason: 'Command "$command" should extract infoType=battery',
        );
      }
    });

    test('should extract correct parameters for connection commands', () async {
      // Test parameter extraction for connection commands
      final connectionCommands = [
        'connection status',
        'network status',
        'check connection',
        'am i online',
        'am i offline',
      ];

      for (final command in connectionCommands) {
        final intent = await classifier.classify(command);

        expect(
          intent.parameters['infoType'],
          equals('connection'),
          reason: 'Command "$command" should extract infoType=connection',
        );
      }
    });

    test('should handle offline status query', () async {
      // Arrange
      const command = 'am i offline';

      // Act
      final intent = await classifier.classify(command);

      // Assert
      expect(intent.type, equals(IntentType.system));
      expect(intent.parameters['infoType'], equals('connection'));
    });

    test('should handle generic system status query', () async {
      // Arrange
      const command = 'system status';

      // Act
      final intent = await classifier.classify(command);

      // Assert
      expect(intent.type, equals(IntentType.system));
      expect(intent.parameters, isNotEmpty);
    });
  });

  group('System Command Edge Cases', () {
    late IntentClassifier classifier;

    setUp(() {
      classifier = IntentClassifier();
    });

    test('should handle empty system command', () async {
      // Arrange
      const emptyCommand = '';

      // Act
      final intent = await classifier.classify(emptyCommand);

      // Assert - should handle gracefully with low confidence
      expect(intent.confidence, equals(0.0));
    });

    test('should handle system command with special characters', () async {
      // Arrange
      const specialCommand = 'battery @#\$%';

      // Act
      final intent = await classifier.classify(specialCommand);

      // Assert - should still classify based on 'battery' keyword
      expect(intent.type, equals(IntentType.system));
      expect(intent.parameters['infoType'], equals('battery'));
    });

    test('should handle mixed system commands', () async {
      // Test commands that contain multiple system keywords
      final mixedCommands = [
        ('battery and connection status', 'battery'), // First keyword wins
        ('check battery connection', 'battery'),
      ];

      for (final (command, expectedInfoType) in mixedCommands) {
        final intent = await classifier.classify(command);

        expect(
          intent.type,
          equals(IntentType.system),
          reason: 'Command "$command" should be classified as system intent',
        );
        expect(
          intent.parameters['infoType'],
          equals(expectedInfoType),
          reason: 'Command "$command" should have infoType=$expectedInfoType',
        );
      }
    });

    test('should preserve original command in intent', () async {
      // Arrange
      const command = '  BATTERY STATUS  ';

      // Act
      final intent = await classifier.classify(command);

      // Assert
      expect(intent.originalCommand, equals(command));
    });
  });
}
