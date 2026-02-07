# Manual Testing Checklist for Voice Control Fixes

## Overview
This checklist covers all manual testing requirements from task 9.5. Complete each test and mark with ✅ or ❌.

## Prerequisites
- [ ] Physical device with microphone
- [ ] Microphone permissions granted
- [ ] Internet connection active
- [ ] Models downloaded and initialized
- [ ] Quiet testing environment

---

## 1. Navigation Commands

### Test 1.1: Go to Dashboard
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "Go to dashboard"
- [ ] **Expected**: Navigates to dashboard and announces available actions
- [ ] **Result**: _______________

### Test 1.2: Go to Settings
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "Go to settings"
- [ ] **Expected**: Opens settings page
- [ ] **Result**: _______________

### Test 1.3: Go to Relatives
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "Go to relatives"
- [ ] **Expected**: Opens relatives/family page
- [ ] **Result**: _______________

### Test 1.4: Go Home
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "Go home"
- [ ] **Expected**: Returns to home screen
- [ ] **Result**: _______________

**Navigation Commands Status**: _____ / 4 passed

---

## 2. Relatives Management Commands

### Test 2.1: Add Relative
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "Add relative"
- [ ] **Expected**: 
  - Navigates to relatives page
  - Says: "Opening relatives page. To add a new relative, tap the add button and follow the prompts."
- [ ] **Result**: _______________

### Test 2.2: Show Relatives
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "Show relatives"
- [ ] **Expected**:
  - Navigates to relatives page
  - Says: "Showing all relatives."
- [ ] **Result**: _______________

### Test 2.3: Create New Relative
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "Create new relative"
- [ ] **Expected**: Same as "Add relative"
- [ ] **Result**: _______________

**Relatives Commands Status**: _____ / 3 passed

---

## 3. Settings Control Commands

### Test 3.1: Increase Volume
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "Increase volume"
- [ ] **Expected**:
  - Navigates to settings (if not already there)
  - Increases volume by 10%
  - Says: "Volume increased to X percent"
- [ ] **Result**: _______________

### Test 3.2: Speak Faster
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "Speak faster"
- [ ] **Expected**:
  - Navigates to settings
  - Increases speech speed
  - Says: "Speech speed increased" (in faster voice)
- [ ] **Result**: _______________

### Test 3.3: Emergency Contact
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "Emergency contact"
- [ ] **Expected**:
  - Navigates to settings
  - Says: "Emergency contact settings are on the settings page. Scroll down to find emergency contact options."
- [ ] **Result**: _______________

### Test 3.4: Change Theme
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "Change theme"
- [ ] **Expected**:
  - Theme toggles between light/dark
  - Says: "Theme changed" or similar confirmation
- [ ] **Result**: _______________

**Settings Commands Status**: _____ / 4 passed

---

## 4. Vision/Scanning Commands

### Test 4.1: Scan Surroundings
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "Scan surroundings"
- [ ] **Expected**: Analyzes current camera view and describes it
- [ ] **Result**: _______________

### Test 4.2: What's in Front of Me
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "What's in front of me?"
- [ ] **Expected**: Describes what the camera sees
- [ ] **Result**: _______________

### Test 4.3: Detect Obstacles
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "Detect obstacles"
- [ ] **Expected**: Identifies obstacles in view
- [ ] **Result**: _______________

### Test 4.4: Read Text
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "Read text"
- [ ] **Expected**: Reads any text visible in camera view
- [ ] **Result**: _______________

**Vision Commands Status**: _____ / 4 passed

---

## 5. System Information Commands

### Test 5.1: Battery Status
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "Battery status"
- [ ] **Expected**:
  - Says: "Battery information is available on the dashboard."
  - Navigates to dashboard
- [ ] **Result**: _______________

### Test 5.2: Am I Online
- [ ] Say "Hey Vision"
- [ ] Wait for beep/confirmation
- [ ] Say "Am I online?"
- [ ] **Expected**: Says: "You are currently online."
- [ ] **Result**: _______________

**System Commands Status**: _____ / 2 passed

---

## 6. Multi-Step Sequence Test

This test verifies that hotword restarts correctly after each command.

### Sequence Steps:
1. [ ] Say "Hey Vision" → Wait for beep
2. [ ] Say "Go to dashboard" → Should navigate and announce
3. [ ] Wait 5 seconds for hotword to restart
4. [ ] Say "Hey Vision" → Wait for beep
5. [ ] Say "Go to settings" → Should navigate
6. [ ] Wait 5 seconds
7. [ ] Say "Hey Vision" → Wait for beep
8. [ ] Say "Increase volume" → Should increase volume
9. [ ] Wait 5 seconds
10. [ ] Say "Hey Vision" → Wait for beep
11. [ ] Say "Go home" → Should return to home

**Multi-Step Sequence Status**: _____ / 11 steps passed

---

## 7. Hotword Restart Verification

Test that hotword listening restarts after each command.

### Test 7.1: Single Command Restart
- [ ] Say "Hey Vision" and a command
- [ ] Wait exactly 5 seconds
- [ ] Check logs for: `[MainShell] ✅ Hotword listening restarted successfully`
- [ ] Try another "Hey Vision" command
- [ ] **Expected**: Hotword detected and command processed
- [ ] **Result**: _______________

### Test 7.2: Multiple Commands in Sequence
- [ ] Execute 5 commands in a row (waiting 5 seconds between each)
- [ ] **Expected**: All 5 commands work correctly
- [ ] **Result**: _____ / 5 commands worked

### Test 7.3: Rapid Commands
- [ ] Execute 3 commands rapidly (1 second apart, not waiting for restart)
- [ ] **Expected**: System handles gracefully, restarts after last command
- [ ] **Result**: _______________

**Hotword Restart Status**: _____ / 3 tests passed

---

## 8. Audio Feedback Verification

### Test 8.1: Navigation Feedback
- [ ] Execute any navigation command
- [ ] **Expected**: System announces destination screen name
- [ ] **Result**: _______________

### Test 8.2: Settings Adjustment Feedback
- [ ] Execute "Increase volume" or "Speak faster"
- [ ] **Expected**: System announces new setting value
- [ ] **Result**: _______________

### Test 8.3: Relatives Action Feedback
- [ ] Execute "Add relative" or "Show relatives"
- [ ] **Expected**: System announces action taken
- [ ] **Result**: _______________

### Test 8.4: Vision Analysis Feedback
- [ ] Execute "Scan surroundings"
- [ ] **Expected**: System announces that analysis is starting
- [ ] **Result**: _______________

### Test 8.5: Error Feedback
- [ ] Say an invalid command (e.g., "blah blah blah")
- [ ] **Expected**: System announces error message
- [ ] **Result**: _______________

### Test 8.6: Hotword Detection Feedback
- [ ] Say "Hey Vision"
- [ ] **Expected**: Brief audio cue (beep or "listening")
- [ ] **Result**: _______________

**Audio Feedback Status**: _____ / 6 tests passed

---

## 9. Error Recovery Tests

### Test 9.1: Network Error Recovery
- [ ] Disable internet connection
- [ ] Try a voice command
- [ ] **Expected**: Error message, then hotword restarts
- [ ] Re-enable internet
- [ ] Try another command
- [ ] **Expected**: Command works normally
- [ ] **Result**: _______________

### Test 9.2: Microphone Busy Recovery
- [ ] Start a voice command
- [ ] Immediately start another (interrupt)
- [ ] **Expected**: System handles gracefully, restarts hotword
- [ ] **Result**: _______________

### Test 9.3: Background/Foreground Recovery
- [ ] Start hotword listening
- [ ] Put app in background
- [ ] Return to foreground
- [ ] **Expected**: Hotword listening resumes
- [ ] **Result**: _______________

**Error Recovery Status**: _____ / 3 tests passed

---

## 10. Success Criteria Verification

Mark each criterion as met or not met:

- [ ] Hotword "Hey Vision" detected consistently (>95% success rate)
  - Tested: _____ times
  - Successful: _____ times
  - Success rate: _____%

- [ ] Commands work 5+ times in a row
  - Tested: _____ commands in sequence
  - All successful: Yes / No

- [ ] All navigation commands work
  - Dashboard: ✅ / ❌
  - Settings: ✅ / ❌
  - Relatives: ✅ / ❌
  - Home: ✅ / ❌

- [ ] Volume and speech speed adjustments work
  - Volume: ✅ / ❌
  - Speech speed: ✅ / ❌

- [ ] Theme toggle works via voice
  - Theme change: ✅ / ❌
  - Audio feedback: ✅ / ❌
  - Persistence: ✅ / ❌

- [ ] Model download screen auto-skips when appropriate
  - Auto-skip tested: ✅ / ❌
  - Audio feedback: ✅ / ❌
  - Timing (<500ms): ✅ / ❌

- [ ] Clear audio feedback for all actions
  - All commands provide feedback: ✅ / ❌

- [ ] Hotword restarts automatically after each command
  - Restart timing (5 seconds): ✅ / ❌
  - Consistent restart: ✅ / ❌

**Overall Success Criteria**: _____ / 8 met

---

## 11. Log Verification

For each test, verify the expected log output appears:

### Expected Log Sequence:
```
[VoiceService] ✅ HOTWORD DETECTED!
[MainShell] 🎤 Hotword detected! Starting voice command...
[VoiceNav] Starting listening via microphone tap
[MicController] State transition: idle → listening
[VoiceService] Hotword listening paused for voice command
[VoiceService] 🎤 Heard: "go to settings" (final: true)
[VoiceNav] Processing command: "go to settings"
[VoiceNav] Classified as: navigation (confidence: 0.85)
[VoiceRouter] Navigating to: /settings
[MainShell] ⏰ Scheduling hotword restart in 5 seconds...
[MainShell] 🔄 Restarting hotword listening...
[MainShell] ✅ Hotword listening restarted successfully
```

- [ ] Hotword detection logs appear
- [ ] Command processing logs appear
- [ ] Navigation logs appear
- [ ] Hotword restart logs appear
- [ ] No error logs appear (unless testing errors)

**Log Verification Status**: _____ / 5 checks passed

---

## 12. Issues Found

Document any issues discovered during testing:

### Issue 1:
- **Test**: _______________
- **Expected**: _______________
- **Actual**: _______________
- **Severity**: Critical / High / Medium / Low
- **Notes**: _______________

### Issue 2:
- **Test**: _______________
- **Expected**: _______________
- **Actual**: _______________
- **Severity**: Critical / High / Medium / Low
- **Notes**: _______________

### Issue 3:
- **Test**: _______________
- **Expected**: _______________
- **Actual**: _______________
- **Severity**: Critical / High / Medium / Low
- **Notes**: _______________

---

## Summary

### Test Results:
- **Navigation Commands**: _____ / 4 passed
- **Relatives Commands**: _____ / 3 passed
- **Settings Commands**: _____ / 4 passed
- **Vision Commands**: _____ / 4 passed
- **System Commands**: _____ / 2 passed
- **Multi-Step Sequence**: _____ / 11 steps passed
- **Hotword Restart**: _____ / 3 tests passed
- **Audio Feedback**: _____ / 6 tests passed
- **Error Recovery**: _____ / 3 tests passed
- **Success Criteria**: _____ / 8 met

### Overall Pass Rate: _____ / 50 tests passed (____%)

### Recommendation:
- [ ] All tests passed - Ready for release
- [ ] Minor issues found - Fix and retest
- [ ] Major issues found - Requires significant fixes
- [ ] Critical issues found - Not ready for release

### Tester Information:
- **Name**: _______________
- **Date**: _______________
- **Device**: _______________
- **OS Version**: _______________
- **App Version**: _______________

### Notes:
_______________________________________________
_______________________________________________
_______________________________________________
