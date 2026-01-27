# Voice Navigation Testing Guide

## Overview
This guide explains how to test the voice-first navigation features implemented in the Drishti app.

## Prerequisites
1. Ensure the app is running on your device (DN2101)
2. Grant microphone permissions when prompted
3. Grant camera permissions for vision features
4. Ensure device has internet connection for backend VLM (or test offline mode)

## Features Implemented

### 1. Voice Navigation Between Screens
**What it does:** Navigate between all app screens using voice commands

**How to test:**
1. Open the app and go to the Home screen
2. Tap the microphone button (large circular button in center)
3. Wait for the "listening" audio cue
4. Say one of these commands:
   - "Go to settings" → Should navigate to Settings screen
   - "Go to dashboard" → Should navigate to Dashboard screen
   - "Open profile" → Should navigate to Profile screen
   - "Open relatives" → Should navigate to Relatives screen
   - "Open activity" → Should navigate to Activity screen
   - "Go back" → Should go to previous screen
   - "Home" → Should return to Home screen

**Expected behavior:**
- Microphone button changes color/animation when listening
- Audio confirmation when command is recognized
- Screen transitions smoothly
- New screen announces itself (e.g., "Settings. Change theme, Adjust voice speed...")

### 2. Screen Announcements
**What it does:** Each screen announces itself and available actions when loaded

**How to test:**
1. Navigate to any screen (using touch or voice)
2. Listen for the audio announcement

**Expected announcements:**
- **Home**: "Home. Tap microphone to speak, Quick scan, View tips"
- **Dashboard**: "Dashboard. View stats, Check battery, View alerts, Refresh"
- **Settings**: "Settings. Change theme, Adjust voice speed, Manage emergency contacts, View profile"
- **Profile**: "Profile. Edit profile, Change photo, Update information"
- **Relatives**: "Relatives. View relatives, Add new relative, Sort list"
- **Activity**: "Activity. View history, Filter activities, Check recent alerts"

### 3. Vision Analysis (Quick Scan)
**What it does:** Analyze camera view and describe surroundings using voice

**How to test:**
1. Go to Home screen
2. Tap the microphone button
3. Say: "Scan surroundings" or "What's in front of me"
4. OR tap the "Quick Scan" button directly

**Expected behavior:**
- Camera captures a frame
- System analyzes the image (using backend or local VLM)
- Speaks a 2-sentence description of what's visible
- If hazards detected, speaks safety warning immediately

**Alternative vision commands:**
- "Show obstacles" → Focuses on obstacle detection
- "Read text" → Attempts to read visible text
- "Who is near" → Attempts to identify people (if face recognition is set up)

### 4. Microphone States
**What it does:** Visual and audio feedback for microphone states

**How to test:**
1. Tap microphone button and observe:
   - **Idle** (default): Button is static, ready to listen
   - **Listening**: Button animates/pulses, audio cue plays
   - **Processing**: Button shows processing state
   - **Speaking**: Button indicates system is speaking

**Expected behavior:**
- Clear visual distinction between states
- Audio cues for state transitions
- Haptic feedback on state changes

### 5. Intent Classification
**What it does:** Understands different types of voice commands

**How to test different intent types:**

**Navigation Intent:**
- "Go to settings"
- "Open dashboard"
- "Take me to profile"

**Vision Intent:**
- "What's in front of me"
- "Scan surroundings"
- "Any obstacles"

**System Intent:**
- "Battery status"
- "Connection status"

**Emergency Intent:**
- "Help"
- "Emergency"

**Expected behavior:**
- System correctly identifies intent type
- Routes to appropriate handler
- Provides relevant response

### 6. Low Confidence Handling
**What it does:** Asks for clarification when command is unclear

**How to test:**
1. Tap microphone button
2. Say something unclear or mumbled
3. OR say something not in the command vocabulary

**Expected behavior:**
- System responds: "I'm not sure what you meant. Could you rephrase?"
- Returns to idle state
- Ready for new command

### 7. Error Handling
**What it does:** Provides user-friendly error messages

**How to test:**
1. **Camera error**: Try vision scan with camera permission denied
   - Expected: "Camera not available. Trying again."

2. **Network error**: Disable internet and try vision scan
   - Expected: "Connection lost. Using offline mode."

3. **Microphone error**: Deny microphone permission
   - Expected: "Microphone access required. Please enable in settings."

## Common Issues and Solutions

### Issue: "Settings screen" announced on Home screen
**Solution:** This has been fixed. The VoiceNavigationProvider is now initialized in MainShell's initState.

### Issue: No audio feedback
**Solution:** 
- Check device volume
- Ensure TTS is initialized (should happen automatically)
- Check if device has TTS engine installed

### Issue: Microphone not responding
**Solution:**
- Check microphone permissions
- Ensure no other app is using microphone
- Restart the app

### Issue: Vision scan not working
**Solution:**
- Check camera permissions
- Ensure internet connection for backend VLM
- Local VLM should work offline (if configured)

## Testing Checklist

- [ ] Voice navigation to all 6 screens works
- [ ] Screen announcements play on each screen
- [ ] Microphone button shows correct states
- [ ] Vision scan captures and analyzes images
- [ ] Quick scan button works
- [ ] Low confidence clarification works
- [ ] Error messages are user-friendly
- [ ] "Go back" command works
- [ ] "Home" command works
- [ ] Multiple commands in sequence work
- [ ] Haptic feedback on state changes
- [ ] Audio cues for state transitions

## Advanced Testing

### Test Offline Mode
1. Enable airplane mode
2. Try voice navigation (should work)
3. Try vision scan (should use local VLM)
4. Expected: "Offline mode active" announcement

### Test Emergency Mode
1. Say "Help" or "Emergency"
2. Expected: "Emergency mode activated"
3. Note: Full emergency handler not yet implemented (Task 13)

### Test Settings Voice Control
1. Say "Increase volume"
2. Expected: "Voice settings control not yet implemented"
3. Note: This is Task 12, not yet implemented

## Next Steps for Full Implementation

The following features are designed but not yet implemented:
1. **Voice Authentication** (Task 11) - Voice-only sign-in/sign-up
2. **Settings Voice Control** (Task 12) - Adjust settings via voice
3. **Emergency Handler** (Task 13) - Call emergency contacts
4. **Offline Detection** (Task 15) - Automatic offline mode switching
5. **Analytics Tracking** (Task 16) - Track voice interactions

## Reporting Issues

If you encounter issues:
1. Note the exact voice command used
2. Note the current screen
3. Note any error messages (audio or visual)
4. Check console logs for technical details
5. Report with steps to reproduce

## Tips for Best Results

1. **Speak clearly** - Enunciate commands clearly
2. **Wait for cue** - Wait for listening audio cue before speaking
3. **Use exact commands** - Commands listed above work best
4. **Quiet environment** - Reduce background noise for better recognition
5. **Check permissions** - Ensure all permissions are granted

## Demo Script

For a quick demo of all features:

1. **Start**: Open app, listen for "Voice navigation ready"
2. **Navigate**: "Go to dashboard" → Listen for "Dashboard" announcement
3. **Navigate**: "Go to settings" → Listen for "Settings" announcement
4. **Return**: "Home" → Back to home screen
5. **Vision**: Tap mic, say "Scan surroundings" → Listen for description
6. **Quick Scan**: Tap "Quick Scan" button → Listen for description
7. **Navigate**: "Go to profile" → Listen for "Profile" announcement
8. **Back**: "Go back" → Returns to previous screen

This demonstrates: voice navigation, screen announcements, vision analysis, and command recognition.
