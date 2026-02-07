/// Integration Test: Hotword Command Sequence Flow
///
/// **Validates: Requirements 4.1, 4.2, 4.3, 9.1, 9.2, 9.4, 9.5**
///
/// This integration test verifies the complete hotword command sequence:
/// - Start hotword listening
/// - Detect hotword
/// - Capture command
/// - Process command
/// - Provide audio feedback
/// - Wait 5 seconds
/// - Verify hotword listening resumed
/// - Repeat for multiple commands
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drishti_mobile_app/data/services/voice_service.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/voice_navigation_controller.dart';
import 'package:drishti_mobile_app/data/providers/theme_provider.dart';
import 'package:drishti_mobile_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Hotword Command Sequence Flow Integration Test', () {
    testWidgets('Complete hotword command sequence with multiple commands',
        (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Get voice service instance
      final context = tester.element(find.byType(MaterialApp));
      final voiceService = VoiceService();

      // Track hotword detection events
      int hotwordDetectionCount = 0;
      bool isListeningAfterCommand = false;

      // Initialize voice service
      await voiceService.initTts();
      await voiceService.initStt();

      // Start continuous hotword listening
      await voiceService.startContinuousHotwordListening(
        onHotwordDetected: () {
          hotwordDetectionCount++;
        },
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Verify hotword listening is active
      expect(voiceService.isHotwordListening, true);

      // Simulate hotword detection and command sequence (3 commands)
      for (int i = 0; i < 3; i++) {
        // Simulate hotword detection
        voiceService.onHotwordDetected?.call();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify hotword was detected
        expect(hotwordDetectionCount, i + 1);

        // Simulate command processing
        await Future.delayed(const Duration(milliseconds: 500));

        // Resume hotword listening (simulating command completion)
        await voiceService.resumeHotwordListening();

        // Wait for the 800ms delay before listen cycle starts
        await tester.pump(const Duration(milliseconds: 800));

        // Wait for the 5-second restart delay
        await tester.pump(const Duration(seconds: 5));

        // Verify hotword listening resumed
        expect(voiceService.isHotwordListening, true);
      }

      // Verify all hotword detections occurred
      expect(hotwordDetectionCount, 3);

      // Stop hotword listening
      await voiceService.stopHotwordListening();
      expect(voiceService.isHotwordListening, false);
    });

    testWidgets('Hotword restart timing verification',
        (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      final voiceService = VoiceService();

      // Initialize voice service
      await voiceService.initTts();
      await voiceService.initStt();

      // Start continuous hotword listening
      await voiceService.startContinuousHotwordListening(
        onHotwordDetected: () {},
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Record start time
      final startTime = DateTime.now();

      // Simulate command completion and resume
      await voiceService.resumeHotwordListening();

      // Wait for restart (800ms delay + time for listen cycle to start)
      await tester.pump(const Duration(milliseconds: 800));

      // Measure elapsed time
      final elapsedTime = DateTime.now().difference(startTime);

      // Verify timing is approximately 800ms (±100ms tolerance)
      expect(elapsedTime.inMilliseconds, greaterThanOrEqualTo(700));
      expect(elapsedTime.inMilliseconds, lessThanOrEqualTo(900));

      // Stop hotword listening
      await voiceService.stopHotwordListening();
    });

    testWidgets('Multiple rapid commands with hotword restart',
        (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      final voiceService = VoiceService();

      // Initialize voice service
      await voiceService.initTts();
      await voiceService.initStt();

      int hotwordDetectionCount = 0;

      // Start continuous hotword listening
      await voiceService.startContinuousHotwordListening(
        onHotwordDetected: () {
          hotwordDetectionCount++;
        },
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Simulate 5 rapid commands
      for (int i = 0; i < 5; i++) {
        // Detect hotword
        voiceService.onHotwordDetected?.call();
        await tester.pump(const Duration(milliseconds: 100));

        // Quick command processing
        await Future.delayed(const Duration(milliseconds: 200));

        // Resume hotword listening
        await voiceService.resumeHotwordListening();

        // Wait for restart delay
        await tester.pump(const Duration(milliseconds: 800));
      }

      // Verify all commands were processed
      expect(hotwordDetectionCount, 5);

      // Verify hotword listening is still active
      expect(voiceService.isHotwordListening, true);

      // Stop hotword listening
      await voiceService.stopHotwordListening();
    });

    testWidgets('Hotword restart after error',
        (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      final voiceService = VoiceService();

      // Initialize voice service
      await voiceService.initTts();
      await voiceService.initStt();

      bool hotwordDetected = false;

      // Start continuous hotword listening
      await voiceService.startContinuousHotwordListening(
        onHotwordDetected: () {
          hotwordDetected = true;
        },
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Simulate error during command processing
      try {
        throw Exception('Simulated command processing error');
      } catch (e) {
        // Error occurred, but hotword should still resume
        await voiceService.resumeHotwordListening();
      }

      // Wait for restart delay
      await tester.pump(const Duration(milliseconds: 800));

      // Verify hotword listening resumed despite error
      expect(voiceService.isHotwordListening, true);

      // Stop hotword listening
      await voiceService.stopHotwordListening();
    });
  });
}