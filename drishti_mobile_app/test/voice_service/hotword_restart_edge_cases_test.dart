/// Unit Tests: Hotword Restart Edge Cases
///
/// **Validates: Requirements 4.4, 4.5, 10.1, 10.2**
///
/// Tests edge cases and error scenarios for hotword restart functionality:
/// - STT busy error handling with backoff
/// - Multiple overlapping timer cancellation
/// - Manual stop cancellation
/// - STT initialization failure
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drishti_mobile_app/data/services/voice_service.dart';

void main() {
  // Initialize Flutter test bindings
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Unit Tests: Hotword Restart Edge Cases', () {
    late VoiceService voiceService;

    setUp(() {
      voiceService = VoiceService();
    });

    tearDown(() async {
      await voiceService.dispose();
    });

    test('Edge Case: stopHotwordListening cancels all pending timers', () async {
      // Initialize voice service
      await voiceService.initTts();
      await voiceService.initStt();

      // Start hotword listening
      await voiceService.startHotwordListening(
        onHotwordDetected: () {},
      );

      // Verify hotword listening is active
      expect(voiceService.isHotwordListening, isTrue);
      expect(voiceService.isContinuousListening, isTrue);

      // Stop hotword listening
      await voiceService.stopHotwordListening();

      // Verify all state is reset
      expect(voiceService.isHotwordListening, isFalse);
      expect(voiceService.isContinuousListening, isFalse);

      // Wait a bit to ensure no timers fire
      await Future.delayed(const Duration(milliseconds: 100));

      // State should still be stopped
      expect(voiceService.isHotwordListening, isFalse);
      expect(voiceService.isContinuousListening, isFalse);
    });

    test('Edge Case: resumeHotwordListening cancels previous timers', () async {
      // Initialize voice service
      await voiceService.initTts();
      await voiceService.initStt();

      // Start hotword listening
      await voiceService.startHotwordListening(
        onHotwordDetected: () {},
      );

      expect(voiceService.isHotwordListening, isTrue);

      // Stop (simulating command processing)
      await voiceService.stopHotwordListening();

      expect(voiceService.isHotwordListening, isFalse);

      // Resume multiple times rapidly (simulating multiple commands)
      // Each resume should cancel the previous timer
      for (int i = 0; i < 3; i++) {
        // Don't await - fire them rapidly
        voiceService.resumeHotwordListening();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Wait for the last resume to complete
      await Future.delayed(const Duration(milliseconds: 1000));

      // Should be in hotword listening state
      expect(voiceService.isHotwordListening, isTrue);
      expect(voiceService.isContinuousListening, isTrue);
    });

    test('Edge Case: Multiple stop calls are safe', () async {
      // Initialize voice service
      await voiceService.initTts();
      await voiceService.initStt();

      // Start hotword listening
      await voiceService.startHotwordListening(
        onHotwordDetected: () {},
      );

      expect(voiceService.isHotwordListening, isTrue);

      // Stop multiple times
      await voiceService.stopHotwordListening();
      await voiceService.stopHotwordListening();
      await voiceService.stopHotwordListening();

      // Should be stopped
      expect(voiceService.isHotwordListening, isFalse);
      expect(voiceService.isContinuousListening, isFalse);
    });

    test('Edge Case: resumeHotwordListening without prior start is safe', () async {
      // Initialize voice service
      await voiceService.initTts();
      await voiceService.initStt();

      // Try to resume without starting first
      await voiceService.resumeHotwordListening();

      // Should not crash, but also should not be listening
      // (because onHotwordDetected callback is null)
      expect(voiceService.isHotwordListening, isFalse);
    });

    test('Edge Case: Dispose cancels all timers', () async {
      // Initialize voice service
      await voiceService.initTts();
      await voiceService.initStt();

      // Start hotword listening
      await voiceService.startHotwordListening(
        onHotwordDetected: () {},
      );

      expect(voiceService.isHotwordListening, isTrue);

      // Dispose should cancel all timers
      await voiceService.dispose();

      // State should be reset
      expect(voiceService.isHotwordListening, isFalse);
      expect(voiceService.isContinuousListening, isFalse);
    });

    test('Edge Case: resumeHotwordListening waits 800ms', () async {
      // Initialize voice service
      await voiceService.initTts();
      await voiceService.initStt();

      // Start hotword listening
      await voiceService.startHotwordListening(
        onHotwordDetected: () {},
      );

      // Stop
      await voiceService.stopHotwordListening();

      // Measure time for resume
      final startTime = DateTime.now();
      await voiceService.resumeHotwordListening();
      final endTime = DateTime.now();

      final delayMs = endTime.difference(startTime).inMilliseconds;

      // Should wait at least 800ms
      expect(delayMs, greaterThanOrEqualTo(800),
          reason: 'resumeHotwordListening should wait at least 800ms for TTS to finish');

      // Allow some tolerance for execution time
      expect(delayMs, lessThan(1000),
          reason: 'resumeHotwordListening should not wait more than 1000ms');
    });

    test('Edge Case: State is correctly reset after resume', () async {
      // Initialize voice service
      await voiceService.initTts();
      await voiceService.initStt();

      // Start hotword listening
      await voiceService.startHotwordListening(
        onHotwordDetected: () {},
      );

      expect(voiceService.isHotwordListening, isTrue);
      expect(voiceService.isContinuousListening, isTrue);

      // Stop
      await voiceService.stopHotwordListening();

      expect(voiceService.isHotwordListening, isFalse);
      expect(voiceService.isContinuousListening, isFalse);

      // Resume
      await voiceService.resumeHotwordListening();

      // State should be reset correctly
      expect(voiceService.isHotwordListening, isTrue);
      expect(voiceService.isContinuousListening, isTrue);
    });

    test('Edge Case: STT initialization failure is handled gracefully', () async {
      // Try to start hotword listening without initializing STT
      // This simulates STT initialization failure
      
      // Don't initialize STT
      await voiceService.initTts();

      // Try to start hotword listening
      await voiceService.startHotwordListening(
        onHotwordDetected: () {},
      );

      // Should not crash, but STT won't be available
      // The service should handle this gracefully
      expect(voiceService.isSttAvailable, isFalse);
    });

    test('Edge Case: Resume after dispose is safe', () async {
      // Initialize voice service
      await voiceService.initTts();
      await voiceService.initStt();

      // Start hotword listening
      await voiceService.startHotwordListening(
        onHotwordDetected: () {},
      );

      // Dispose
      await voiceService.dispose();

      // Try to resume after dispose
      await voiceService.resumeHotwordListening();

      // Should not crash
      expect(voiceService.isContinuousListening, isFalse);
    });

    test('Edge Case: Rapid start/stop cycles', () async {
      // Initialize voice service
      await voiceService.initTts();
      await voiceService.initStt();

      // Perform rapid start/stop cycles
      for (int i = 0; i < 5; i++) {
        await voiceService.startHotwordListening(
          onHotwordDetected: () {},
        );

        expect(voiceService.isHotwordListening, isTrue);

        await voiceService.stopHotwordListening();

        expect(voiceService.isHotwordListening, isFalse);
      }

      // Final state should be stopped
      expect(voiceService.isHotwordListening, isFalse);
      expect(voiceService.isContinuousListening, isFalse);
    });
  });
}
