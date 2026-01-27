# Implementation Plan: Voice-First Navigation Assistant

## Overview

This implementation plan breaks down the voice-first navigation assistant into incremental, testable steps. The approach follows a layered architecture, building from core services up to the complete voice interaction system. Each task builds on previous work, with checkpoints to ensure stability before proceeding.

## Tasks

- [x] 1. Set up core voice navigation infrastructure
  - Create directory structure for voice navigation module
  - Define core data models (IntentType, ClassifiedIntent, MicrophoneState, VoiceNavigationState)
  - Set up dependency injection for voice services
  - _Requirements: 1.1, 2.1, 3.1_

- [ ] 2. Implement Intent Classifier
  - [x] 2.1 Create IntentClassifier class with pattern matching
    - Implement classify() method with confidence scoring
    - Define intent patterns for all 7 intent types (NAVIGATION, VISION, RELATIVE, AUTH, SETTINGS, SYSTEM, EMERGENCY)
    - Implement parameter extraction from commands
    - _Requirements: 3.1, 3.2, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10_

  - [ ]* 2.2 Write property test for single intent classification
    - **Property 7: Single Intent Classification**
    - **Validates: Requirements 3.1**

  - [ ]* 2.3 Write property test for confidence score bounds
    - **Property 8: Confidence Score Bounds**
    - **Validates: Requirements 3.2**

  - [ ]* 2.4 Write property test for highest confidence selection
    - **Property 10: Highest Confidence Selection**
    - **Validates: Requirements 3.11**

  - [ ]* 2.5 Write unit tests for intent recognition examples
    - Test each intent type with example commands
    - Test edge cases (empty commands, very long commands, special characters)
    - _Requirements: 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10_

- [ ] 3. Implement Microphone Controller
  - [x] 3.1 Create MicrophoneController class with state machine
    - Implement four states: Idle, Listening, Processing, Speaking
    - Implement state transition methods (startListening, stopListening, setProcessing, setSpeaking, setIdle)
    - Integrate with existing VoiceService for STT
    - Add haptic feedback for state transitions
    - _Requirements: 2.1, 2.2, 2.3, 2.5_

  - [x] 3.2 Implement audio cues for state transitions
    - Create distinct audio cues for each state transition
    - Integrate with VoiceService for TTS
    - _Requirements: 2.4_

  - [x] 3.3 Create visual state indicator widget
    - Design microphone button with state visualization
    - Implement state-based color/animation changes
    - _Requirements: 2.6_

  - [ ]* 3.4 Write property test for state transition audio cues
    - **Property 5: State Transition Audio Cues**
    - **Validates: Requirements 2.4**

  - [ ]* 3.5 Write property test for visual state indicator consistency
    - **Property 6: Visual State Indicator Consistency**
    - **Validates: Requirements 2.6**

  - [ ]* 3.6 Write unit tests for state transitions
    - Test Idle → Listening on button tap
    - Test Idle → Listening on wake word
    - Test state transition sequence
    - _Requirements: 2.2, 2.3_

- [ ] 4. Implement Audio Feedback Engine
  - [x] 4.1 Create AudioFeedbackEngine class with message queue
    - Implement speak() method with priority queue
    - Implement speakImmediate() for interrupts
    - Implement message formatting methods
    - Integrate with existing VoiceService
    - _Requirements: 1.3, 1.4_

  - [x] 4.2 Implement vision response formatting
    - Create formatVisionResponse() to limit to 2 sentences
    - Remove filler phrases ("I see", "The image shows", etc.)
    - Implement clock direction formatting
    - Implement safety-first ordering for hazards
    - _Requirements: 4.6, 5.1, 5.2, 5.3, 5.4_

  - [x] 4.3 Implement error message formatting
    - Create user-friendly error messages for all error types
    - Ensure no technical jargon in messages
    - _Requirements: 1.4, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

  - [ ]* 4.4 Write property test for universal audio feedback
    - **Property 2: Universal Audio Feedback**
    - **Validates: Requirements 1.3**

  - [ ]* 4.5 Write property test for user-friendly error messages
    - **Property 3: User-Friendly Error Messages**
    - **Validates: Requirements 1.4, 8.6**

  - [ ]* 4.6 Write property test for two-sentence response limit
    - **Property 12: Two-Sentence Response Limit**
    - **Validates: Requirements 4.6, 5.1**

  - [ ]* 4.7 Write property test for no filler phrases
    - **Property 13: No Filler Phrases**
    - **Validates: Requirements 5.2**

  - [ ]* 4.8 Write property test for clock direction usage
    - **Property 14: Clock Direction Usage**
    - **Validates: Requirements 5.3**

  - [ ]* 4.9 Write property test for safety information priority
    - **Property 15: Safety Information Priority**
    - **Validates: Requirements 5.4**

  - [ ]* 4.10 Write unit tests for audio feedback
    - Test message queueing
    - Test priority handling
    - Test response formatting
    - _Requirements: 1.3, 5.1, 5.2, 5.3, 5.4_

- [x] 5. Checkpoint - Core voice services functional
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Implement Voice Router
  - [x] 6.1 Create VoiceRouter class with route mapping
    - Define VoiceRoutes constants for all screens
    - Implement routeFromIntent() to map intents to routes
    - Implement navigation methods (navigateTo, goBack, goHome)
    - Integrate with GoRouter
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

  - [x] 6.2 Implement screen announcement
    - Create announceCurrentScreen() method
    - List available actions for current screen
    - _Requirements: 7.8, 14.3_

  - [ ]* 6.3 Write property test for navigation announcement
    - **Property 18: Navigation Announcement**
    - **Validates: Requirements 7.8**

  - [ ]* 6.4 Write property test for complete bottom nav voice coverage
    - **Property 19: Complete Bottom Nav Voice Coverage**
    - **Validates: Requirements 7.9**

  - [ ]* 6.5 Write unit tests for voice navigation
    - Test each navigation command
    - Test go back functionality
    - Test home navigation
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

- [ ] 7. Implement Vision Provider abstraction
  - [x] 7.1 Create VisionProvider abstract interface
    - Define analyzeCurrentView() method
    - Define detectObstacles() method
    - Define identifyPeople() method
    - Define readText() method
    - Define checkForHazards() method
    - Define data models (VisionResult, DetectedObject, ClockPosition, SafetyResult, Hazard)
    - _Requirements: 4.1, 4.7_

  - [x] 7.2 Implement Phone Vision Provider
    - Create PhoneVisionProvider implementing VisionProvider
    - Initialize camera controller
    - Implement frame capture
    - Implement backend VLM integration
    - Implement local VLM fallback
    - Implement bounding box to clock position conversion
    - _Requirements: 4.2, 4.3, 4.4, 4.5_

  - [ ]* 7.3 Write property test for vision analysis routing
    - **Property 11: Vision Analysis Routing**
    - **Validates: Requirements 4.4**

  - [ ]* 7.4 Write unit tests for vision provider
    - Test frame capture
    - Test backend VLM integration
    - Test local VLM fallback
    - Test clock position conversion
    - _Requirements: 4.3, 4.4, 4.5_

- [ ] 8. Implement Safety Priority Detector
  - [x] 8.1 Create SafetyPriorityDetector class
    - Define dangerous objects list
    - Implement detectHazards() method
    - Implement hazard level classification
    - Implement distance estimation
    - Implement warning message generation
    - _Requirements: 9.5_

  - [x] 8.2 Integrate safety detector with vision provider
    - Call safety detector after vision analysis
    - Trigger interrupts for dangerous objects
    - _Requirements: 9.1, 9.2, 9.3_

  - [ ]* 8.3 Write property test for dangerous object interruption
    - **Property 21: Dangerous Object Interruption**
    - **Validates: Requirements 9.1, 9.2**

  - [ ]* 8.4 Write property test for dangerous object screen override
    - **Property 22: Dangerous Object Screen Override**
    - **Validates: Requirements 9.3**

  - [ ]* 8.5 Write property test for safety priority ordering
    - **Property 23: Safety Priority Ordering**
    - **Validates: Requirements 9.4**

  - [ ]* 8.6 Write property test for dangerous object classification
    - **Property 24: Dangerous Object Classification**
    - **Validates: Requirements 9.5**

  - [ ]* 8.7 Write unit tests for safety detection
    - Test hazard detection
    - Test hazard level classification
    - Test warning generation
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 9. Checkpoint - Vision and safety systems functional
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Implement Voice Navigation Controller
  - [x] 10.1 Create VoiceNavigationController class
    - Orchestrate all voice components (MicrophoneController, IntentClassifier, VoiceRouter, AudioFeedbackEngine, VisionProvider)
    - Implement initialize() method
    - Implement onMicrophoneTap() method
    - Implement processVoiceCommand() method
    - Implement handleIntent() method for each intent type
    - Implement triggerEmergency() method
    - _Requirements: 1.1, 1.2, 1.3, 2.2, 2.3_

  - [x] 10.2 Implement intent routing logic
    - Route NAVIGATION intents to VoiceRouter
    - Route VISION intents to VisionProvider
    - Route RELATIVE intents to face recognition
    - Route AUTH intents to VoiceAuthHandler
    - Route SETTINGS intents to SettingsVoiceController
    - Route SYSTEM intents to system info
    - Route EMERGENCY intents to EmergencyHandler
    - _Requirements: 3.1, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10_

  - [ ]* 10.3 Write property test for complete voice command coverage
    - **Property 1: Complete Voice Command Coverage**
    - **Validates: Requirements 1.1, 1.2**

  - [ ]* 10.4 Write property test for touch fallback preservation
    - **Property 4: Touch Fallback Preservation**
    - **Validates: Requirements 1.5**

  - [ ]* 10.5 Write property test for low confidence clarification
    - **Property 9: Low Confidence Clarification**
    - **Validates: Requirements 3.3**

  - [ ]* 10.6 Write unit tests for voice navigation controller
    - Test microphone tap handling
    - Test voice command processing
    - Test intent routing
    - Test emergency triggering
    - _Requirements: 1.1, 1.2, 2.2, 2.3, 3.3_

- [ ] 11. Implement Voice Auth Handler
  - [x] 11.1 Create VoiceAuthHandler class
    - Implement startVoiceSignIn() method
    - Implement startVoiceSignUp() method
    - Implement collectPhoneNumber() method with voice input
    - Implement confirmPhoneNumber() method with voice confirmation
    - Implement collectOTP() method with voice input
    - Implement guideFaceRegistration() method with audio guidance
    - Implement parseSpokenDigits() helper
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

  - [ ]* 11.2 Write property test for voice auth audio confirmation
    - **Property 16: Voice Auth Audio Confirmation**
    - **Validates: Requirements 6.7**

  - [ ]* 11.3 Write property test for keyboard-free authentication
    - **Property 17: Keyboard-Free Authentication**
    - **Validates: Requirements 6.8**

  - [ ]* 11.4 Write unit tests for voice authentication
    - Test phone number collection
    - Test OTP collection
    - Test face registration guidance
    - Test digit parsing
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ] 12. Implement Settings Voice Controller
  - [x] 12.1 Create SettingsVoiceController class
    - Implement handleSettingsIntent() method
    - Implement adjustVolume() method
    - Implement adjustSpeechRate() method
    - Implement toggleVibration() method
    - Implement changeLanguage() method
    - Implement setEmergencyContact() method
    - Implement getCurrentSettings() method
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.8_

  - [ ]* 12.2 Write property test for settings change confirmation
    - **Property 25: Settings Change Confirmation**
    - **Validates: Requirements 10.9**

  - [ ]* 12.3 Write unit tests for settings voice control
    - Test volume adjustment
    - Test speech rate adjustment
    - Test vibration toggle
    - Test language change
    - Test emergency contact setup
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.8_

- [ ] 13. Implement Emergency Handler
  - [x] 13.1 Create EmergencyHandler class
    - Implement emergency activation
    - Implement emergency contact calling
    - Implement emergency contact configuration prompt
    - Integrate with highest priority system
    - _Requirements: 12.1, 12.2, 12.3, 12.4_

  - [ ]* 13.2 Write property test for emergency priority maximum
    - **Property 27: Emergency Priority Maximum**
    - **Validates: Requirements 12.5**

  - [ ]* 13.3 Write property test for emergency override
    - **Property 28: Emergency Override**
    - **Validates: Requirements 12.6**

  - [ ]* 13.4 Write unit tests for emergency handling
    - Test emergency activation
    - Test emergency contact calling
    - Test configuration prompt
    - _Requirements: 12.1, 12.2, 12.3, 12.4_

- [x] 14. Checkpoint - All voice handlers implemented
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 15. Implement offline mode support
  - [x] 15.1 Add offline detection and mode switching
    - Detect network connectivity changes
    - Switch to local VLM when offline
    - Announce offline mode activation
    - Announce connection restoration
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

  - [ ]* 15.2 Write property test for offline voice command processing
    - **Property 29: Offline Voice Command Processing**
    - **Validates: Requirements 13.1, 13.3**

  - [ ]* 15.3 Write unit tests for offline mode
    - Test offline detection
    - Test local VLM fallback
    - Test offline announcements
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

- [ ] 16. Implement analytics tracking
  - [x] 16.1 Create VoiceAnalytics data model
    - Define analytics events enum
    - Create VoiceAnalytics class with metrics
    - Create DeviceHealth class
    - _Requirements: 11.1, 11.2, 11.3, 11.4_

  - [x] 16.2 Integrate analytics tracking throughout voice system
    - Track voice interactions
    - Track vision scans
    - Track emergency triggers
    - Track device health
    - _Requirements: 11.1, 11.2, 11.3, 11.4_

  - [x] 16.3 Create backend API endpoint for analytics
    - Implement POST /api/voice-analytics endpoint
    - Implement GET /api/voice-analytics endpoint
    - _Requirements: 11.5_

  - [ ]* 16.4 Write property test for analytics metric tracking
    - **Property 26: Analytics Metric Tracking**
    - **Validates: Requirements 11.1, 11.2, 11.3**

  - [ ]* 16.5 Write unit tests for analytics
    - Test metric tracking
    - Test API integration
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [ ] 17. Implement accessibility-first widgets
  - [x] 17.1 Create voice-enabled widget base classes
    - Create VoiceEnabledButton with semantic labels
    - Create VoiceEnabledCard with semantic labels
    - Create VoiceEnabledInput with semantic labels
    - Ensure minimum touch target sizes (48x48 dp)
    - _Requirements: 14.1, 14.2, 14.5_

  - [x] 17.2 Add haptic feedback to all state changes
    - Integrate haptic feedback throughout voice system
    - Define haptic patterns for different events
    - _Requirements: 14.4_

  - [x] 17.3 Implement screen load announcements
    - Add announcements to all screens
    - List available actions on each screen
    - _Requirements: 14.3_

  - [ ]* 17.4 Write property test for semantic label completeness
    - **Property 30: Semantic Label Completeness**
    - **Validates: Requirements 14.1**

  - [ ]* 17.5 Write property test for voice alternative completeness
    - **Property 31: Voice Alternative Completeness**
    - **Validates: Requirements 14.2**

  - [ ]* 17.6 Write property test for screen load announcement
    - **Property 32: Screen Load Announcement**
    - **Validates: Requirements 14.3**

  - [ ]* 17.7 Write property test for state change haptic feedback
    - **Property 33: State Change Haptic Feedback**
    - **Validates: Requirements 14.4**

  - [ ]* 17.8 Write property test for minimum touch target size
    - **Property 34: Minimum Touch Target Size**
    - **Validates: Requirements 14.5**

  - [ ]* 17.9 Write unit tests for accessibility widgets
    - Test semantic labels
    - Test haptic feedback
    - Test touch target sizes
    - _Requirements: 14.1, 14.2, 14.4, 14.5_

- [ ] 18. Implement multi-turn conversation support
  - [x] 18.1 Add image context management to VoiceNavigationController
    - Maintain current image context after vision scan
    - Handle follow-up questions without re-capture
    - Clear context on new scan
    - _Requirements: 15.1, 15.2, 15.5_

  - [x] 18.2 Implement follow-up question handlers
    - Handle "Tell me more" command
    - Handle "What else do you see" command
    - _Requirements: 15.3, 15.4_

  - [ ]* 18.3 Write property test for image context preservation
    - **Property 35: Image Context Preservation**
    - **Validates: Requirements 15.1, 15.2**

  - [ ]* 18.4 Write property test for context clearing on new scan
    - **Property 36: Context Clearing on New Scan**
    - **Validates: Requirements 15.5**

  - [ ]* 18.5 Write unit tests for multi-turn conversation
    - Test context preservation
    - Test follow-up questions
    - Test context clearing
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_

- [x] 19. Checkpoint - All features implemented
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 20. Integrate voice navigation into existing screens
  - [x] 20.1 Add voice navigation to home screen
    - Add microphone button
    - Add voice command handlers
    - Add screen announcement
    - _Requirements: 1.1, 7.3_

  - [x] 20.2 Add voice navigation to dashboard screen
    - Add microphone button
    - Add voice command handlers
    - Add screen announcement
    - _Requirements: 1.1, 7.4_

  - [x] 20.3 Add voice navigation to settings screen
    - Add microphone button
    - Add voice command handlers
    - Add screen announcement
    - _Requirements: 1.1, 7.1_

  - [x] 20.4 Add voice navigation to profile screen
    - Add microphone button
    - Add voice command handlers
    - Add screen announcement
    - _Requirements: 1.1, 7.6_

  - [x] 20.5 Add voice navigation to relatives screen
    - Add microphone button
    - Add voice command handlers
    - Add screen announcement
    - _Requirements: 1.1, 7.5_

  - [x] 20.6 Add voice navigation to activity screen
    - Add microphone button
    - Add voice command handlers
    - Add screen announcement
    - _Requirements: 1.1, 7.7_

  - [x] 20.7 Add voice navigation to auth screens
    - Integrate VoiceAuthHandler
    - Add voice-only sign-in flow
    - Add voice-only sign-up flow
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ] 21. Implement error handling throughout voice system
  - [x] 21.1 Create VoiceErrorHandler class
    - Implement handleError() method
    - Implement getUserFriendlyMessage() method
    - Implement attemptRecovery() method
    - _Requirements: 1.4, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

  - [x] 21.2 Integrate error handling in all voice components
    - Add error handling to VoiceNavigationController
    - Add error handling to IntentClassifier
    - Add error handling to VisionProvider
    - Add error handling to VoiceAuthHandler
    - _Requirements: 1.4, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

  - [ ]* 21.3 Write property test for user-friendly unexpected errors
    - **Property 20: User-Friendly Unexpected Errors**
    - **Validates: Requirements 8.5**

  - [ ]* 21.4 Write unit tests for error handling
    - Test camera errors
    - Test network errors
    - Test permission errors
    - Test unexpected errors
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [ ] 22. Performance optimization
  - [x] 22.1 Optimize voice command latency
    - Pre-warm services on app start
    - Optimize intent classification
    - Target < 500ms latency
    - _Requirements: 1.1, 1.2_

  - [x] 22.2 Optimize vision analysis latency
    - Pre-warm camera
    - Implement frame caching
    - Consider parallel backend/local processing
    - Target < 3s for local, < 2s for backend
    - _Requirements: 4.3, 4.4, 4.5_

  - [x] 22.3 Optimize audio feedback latency
    - Minimize queue processing time
    - Target < 200ms from action to speech
    - _Requirements: 1.3_

- [ ] 23. Final integration testing
  - [ ]* 23.1 Write end-to-end integration tests
    - Test complete voice navigation flow
    - Test voice authentication flow
    - Test vision analysis flow
    - Test emergency flow
    - Test offline mode flow
    - _Requirements: All_

  - [ ]* 23.2 Write accessibility integration tests
    - Test screen reader compatibility
    - Test haptic feedback
    - Test audio cues
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_

- [x] 24. Final checkpoint - Complete system verification
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- The implementation follows a bottom-up approach: services → controllers → UI integration
- All voice components are designed to work both online and offline
- Security and privacy considerations are integrated throughout (encrypted storage, camera privacy, OTP security)
