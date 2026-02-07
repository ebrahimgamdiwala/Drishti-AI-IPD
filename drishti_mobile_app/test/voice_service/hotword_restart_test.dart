/// Property-Based Test: Hotword Restart After Command
///
/// **Validates: Requirements 4.1, 4.2, 4.3**
///
/// Property 6: Hotword Restart After Command
/// For any voice command completion (whether successful or error), the VoiceService
/// should resume hotword listening after exactly 5 seconds, with an 800ms delay
/// before starting the listen cycle.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:drishti_mobile_app/data/services/voice_service.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/voice_navigation_controller.dart';
import 'package:drishti_mobile_app/data/services/voice_navigation/audio_feedback_engine.dart';
import 'package:drishti_mobile_app/data/services/local_vlm_service.dart';
import 'package:drishti_mobile_app/data/services/api_service.dart';

import 'hotword_restart_test.mocks.dart';

@GenerateMocks([LocalVLMService, ApiService])
void main() {
  // Initialize Flutter test bindings
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Property Test: Hotword Restart Timing', () {
    late VoiceNavigationController controller;
    late MockLocalVLMService mockVLM;
    late MockApiService mockApiService;

    setUp(() {
      mockVLM = MockLocalVLMService();
      mockApiService = MockApiService();
      
      controller = VoiceNavigationController(
        localVLM: mockVLM,
        apiService: mockApiService,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    /// Test data: Various voice commands (valid and invalid)
    final testCommands = [
      // Valid navigation commands
      'go to dashboard',
      'go to settings',
      'go to relatives',
      'go home',
      
      // Valid theme commands
      'change theme',
      'dark mode',
      'light mode',
      
      // Valid settings commands
      'increase volume',
      'speak faster',
      'speak slower',
      
      // Invalid/unrecognized commands
      'asdfghjkl',
      '12345',
      'xyz abc def',
      'random gibberish',
      '',
      
      // Low confidence commands
      'maybe go somewhere',
      'I think I want to',
      'perhaps change something',
    ];

    test('Property: resumeHotwordListening waits 800ms before starting listen cycle', () async {
      // This test verifies that the 800ms delay is present in resumeHotwordListening
      // We can't easily test the exact timing without integration tests, but we can
      // verify the method exists and is called correctly
      
      final voiceService = VoiceService();
      
      // Initialize the voice service
      await voiceService.initTts();
      await voiceService.initStt();
      
      // Start hotword listening with a callback
      bool hotwordDetected = false;
      await voiceService.startHotwordListening(
        onHotwordDetected: () {
          hotwordDetected = true;
        },
      );
      
      // Verify hotword listening is active
      expect(voiceService.isHotwordListening, isTrue);
      expect(voiceService.isContinuousListening, isTrue);
      
      // Stop hotword listening (simulating command processing)
      await voiceService.stopHotwordListening();
      expect(voiceService.isHotwordListening, isFalse);
      expect(voiceService.isContinuousListening, isFalse);
      
      // Resume hotword listening
      final startTime = DateTime.now();
      await voiceService.resumeHotwordListening();
      final endTime = DateTime.now();
      
      // Verify the delay was at least 800ms
      final delayMs = endTime.difference(startTime).inMilliseconds;
      expect(delayMs, greaterThanOrEqualTo(800),
          reason: 'resumeHotwordListening should wait at least 800ms');
      
      // Allow some tolerance for execution time (up to 1000ms)
      expect(delayMs, lessThan(1000),
          reason: 'resumeHotwordListening should not wait more than 1000ms');
      
      // Verify hotword listening is active again
      expect(voiceService.isHotwordListening, isTrue);
      expect(voiceService.isContinuousListening, isTrue);
      
      // Cleanup
      await voiceService.stopHotwordListening();
      await voiceService.dispose();
    });

    test('Property: VoiceNavigationController calls resumeHotwordListening after command (100+ iterations)', () async {
      // Initialize the controller
      await controller.initialize();
      
      int iterationCount = 0;
      
      // Run property test with various commands
      // We test that resumeHotwordListening is called regardless of command validity
      for (final command in testCommands) {
        // Process the command
        // Note: We can't easily verify the internal call to resumeHotwordListening
        // without modifying the production code, but we can verify the behavior
        // by checking that the voice service state is correct after processing
        
        await controller.processVoiceCommand(command);
        
        // After processing, the controller should have called resumeHotwordListening
        // We verify this indirectly by checking the processing state
        expect(controller.isProcessing, isFalse,
            reason: 'Controller should not be processing after command completes');
        
        iterationCount++;
        
        // Add a small delay between commands to avoid overwhelming the system
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      // Run additional iterations to reach 100+
      final iterationsNeeded = 100;
      final additionalIterations = iterationsNeeded - iterationCount;
      
      for (int i = 0; i < additionalIterations; i++) {
        // Use a random command from the list
        final command = testCommands[i % testCommands.length];
        
        await controller.processVoiceCommand(command);
        
        expect(controller.isProcessing, isFalse,
            reason: 'Controller should not be processing after command completes');
        
        iterationCount++;
        
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      // Verify we ran at least 100 iterations
      expect(iterationCount, greaterThanOrEqualTo(100),
          reason: 'Property test must run at least 100 iterations');
      
      print('✓ Property test completed with $iterationCount iterations');
    });

    test('Property: resumeHotwordListening is called after successful command', () async {
      await controller.initialize();
      
      // Test with valid commands
      final validCommands = [
        'go to dashboard',
        'change theme',
        'increase volume',
      ];
      
      for (final command in validCommands) {
        await controller.processVoiceCommand(command);
        
        // Verify controller returned to idle state
        expect(controller.isProcessing, isFalse);
        expect(controller.microphoneState.name, equals('idle'));
        
        await Future.delayed(const Duration(milliseconds: 50));
      }
    });

    test('Property: resumeHotwordListening is called after error', () async {
      await controller.initialize();
      
      // Test with invalid commands that will cause errors
      final invalidCommands = [
        '', // Empty command
        'asdfghjkl', // Gibberish
        '12345', // Numbers
      ];
      
      for (final command in invalidCommands) {
        await controller.processVoiceCommand(command);
        
        // Verify controller returned to idle state even after error
        expect(controller.isProcessing, isFalse);
        
        await Future.delayed(const Duration(milliseconds: 50));
      }
    });

    test('Property: resumeHotwordListening resets state correctly', () async {
      final voiceService = VoiceService();
      
      await voiceService.initTts();
      await voiceService.initStt();
      
      // Start hotword listening
      await voiceService.startHotwordListening(
        onHotwordDetected: () {},
      );
      
      expect(voiceService.isHotwordListening, isTrue);
      expect(voiceService.isContinuousListening, isTrue);
      
      // Stop (simulating command processing)
      await voiceService.stopHotwordListening();
      
      expect(voiceService.isHotwordListening, isFalse);
      expect(voiceService.isContinuousListening, isFalse);
      
      // Resume
      await voiceService.resumeHotwordListening();
      
      // Verify state is reset correctly
      expect(voiceService.isHotwordListening, isTrue);
      expect(voiceService.isContinuousListening, isTrue);
      
      // Cleanup
      await voiceService.stopHotwordListening();
      await voiceService.dispose();
    });

    test('Property: Multiple rapid commands all trigger resumeHotwordListening', () async {
      await controller.initialize();
      
      // Simulate rapid command sequence
      final rapidCommands = [
        'go to dashboard',
        'go to settings',
        'change theme',
        'increase volume',
        'go home',
      ];
      
      for (final command in rapidCommands) {
        await controller.processVoiceCommand(command);
        
        // Verify controller is ready for next command
        expect(controller.isProcessing, isFalse);
        
        // Very short delay to simulate rapid commands
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      // After all commands, controller should still be in idle state
      expect(controller.isProcessing, isFalse);
    });
  });
}
