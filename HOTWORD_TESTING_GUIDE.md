# Hotword "Hey Vision" Testing Guide

## What Was Changed

**Hotword Updated**: Changed from "Drishti" to **"Hey Vision"** for better recognition
- "Hey Vision" uses common English words
- Similar to popular voice assistants ("Hey Google", "Hey Siri")
- Much easier for STT to recognize
- Related to your app's vision features

## What Was Fixed

1. **Added Debug Logging**: Extensive debug prints to track hotword detection flow
2. **Added Visual Indicator**: Shows "Say 'Hey Vision' to activate" when hotword listening is active
3. **Fixed Hotword Resumption**: Hotword listening now automatically resumes after each voice command
4. **Improved Error Handling**: Better error messages and retry logic
5. **Changed Hotword**: From "Drishti" to "Hey Vision" for better STT recognition

## How to Test

### Step 1: Build and Run
```bash
flutter run -d DN2101
```

### Step 2: Check Console Logs
When the app starts, you should see these logs in the console:
```
[HomeScreen] Checking STT availability...
[HomeScreen] ✅ STT available, starting hotword listening
[VoiceService] startHotwordListening called
[VoiceService] ✅ STT initialized
[VoiceService] ✅ Starting hotword listening for "hey vision"
[VoiceService] Starting hotword listening cycle...
[HomeScreen] ✅ Hotword listening started
```

### Step 3: Look for Visual Indicator
On the home screen, you should see a blue badge that says:
```
🎤 Say "Hey Vision" to activate
```
This badge has a shimmer animation and appears above the microphone button.

### Step 4: Test Hotword Detection
1. **Say "Hey Vision"** clearly into your device
2. Watch the console for:
   ```
   [VoiceService] Heard: "hey vision" (final: true)
   [VoiceService] ✅ Hotword detected: hey vision
   [HomeScreen] 🎤 Hotword detected! Starting voice command...
   ```
3. The microphone should activate and start listening for your command
4. Say a command like **"go to settings"**
5. The app should navigate to the settings screen

### Step 5: Test Continuous Listening
After the command completes:
1. Check console for:
   ```
   [VoiceService] Resuming hotword listening
   [VoiceService] Starting hotword listening cycle...
   ```
2. The visual indicator should still be visible
3. Say **"Hey Vision"** again
4. It should activate again for another command

## Troubleshooting

### Issue: No logs appear
**Problem**: Hotword listening isn't starting
**Solution**: 
- Check if STT is available: Look for `[HomeScreen] ✅ STT available`
- If you see `[HomeScreen] ❌ STT not available`, your device doesn't support STT
- Try restarting the app

### Issue: "Heard: ..." logs but no detection
**Problem**: STT is hearing you but not recognizing "Hey Vision"
**Solutions**:
- Speak more clearly: "HEY VISION"
- Try saying it as two separate words with a slight pause: "Hey... Vision"
- Check console to see what it's hearing: `[VoiceService] Heard: "..."`
- The phrase must contain "hey vision" (case-insensitive)
- Try variations: "hey vision", "a vision", "hey visions" (all should work since we check for "contains")

### Issue: Hotword works once but not again
**Problem**: Hotword listening not resuming
**Solution**:
- Check for `[VoiceService] Resuming hotword listening` in console
- If missing, there's an issue with the resume logic
- Try tapping the microphone button manually

### Issue: Visual indicator not showing
**Problem**: `_hotwordListening` state is false
**Solution**:
- Check console for `[HomeScreen] ✅ Hotword listening started`
- If missing, STT might not be available
- Try restarting the app

## What to Look For

### ✅ Success Indicators:
- Blue "Say 'Hey Vision' to activate" badge visible
- Console shows "Starting hotword listening cycle..."
- Saying "Hey Vision" triggers microphone activation
- After command, hotword listening resumes automatically
- Can use hotword multiple times in a row

### ❌ Failure Indicators:
- No visual indicator on home screen
- Console shows "STT not available"
- Saying "Hey Vision" does nothing
- No "Heard: ..." logs in console
- Hotword works once but not again

## Debug Commands

If hotword isn't working, you can still test navigation with:
1. **Test Buttons**: Use the test buttons on home screen (Scan, Dashboard, Settings, etc.)
2. **Manual Mic Tap**: Tap the microphone button and say your command

## Expected Behavior

**Normal Flow**:
1. App starts → Hotword listening starts automatically
2. User says "Hey Vision" → Microphone activates
3. User says command → Command executes
4. Command completes → Hotword listening resumes
5. Repeat from step 2

**Console Output Example**:
```
[VoiceService] Starting hotword listening cycle...
[VoiceService] Heard: "hey" (final: false)
[VoiceService] Heard: "hey vision" (final: false)
[VoiceService] Heard: "hey vision" (final: true)
[VoiceService] ✅ Hotword detected: hey vision
[HomeScreen] 🎤 Hotword detected! Starting voice command...
[VoiceNav] Starting listening via microphone tap
[VoiceNav] Voice input received: "go to settings"
[VoiceNav] Processing command: "go to settings"
[VoiceNav] Classified as: navigation (confidence: 0.95)
[VoiceNav] Handling intent: navigation
[VoiceService] Resuming hotword listening
[VoiceService] Starting hotword listening cycle...
```

## Tips for Better Recognition

1. **Speak Clearly**: Enunciate "HEY VISION"
2. **Speak at Normal Volume**: Not too loud, not too quiet
3. **Two Words**: Say it as two distinct words: "Hey" (pause) "Vision"
4. **Wait for Listening**: Give it a moment to start listening
5. **Check Microphone**: Make sure your device microphone works
6. **Quiet Environment**: Background noise can interfere

## Why "Hey Vision" Works Better

- ✅ Common English words that STT recognizes easily
- ✅ Similar pattern to "Hey Google" and "Hey Siri"
- ✅ Clear pronunciation
- ✅ Two syllables in each word
- ✅ Related to your app's purpose (vision assistance)

## Next Steps

If hotword is working:
- ✅ Test all navigation commands
- ✅ Test multiple hotword activations in a row
- ✅ Test in different environments (quiet, noisy)

If hotword is NOT working:
- Share the console logs with the developer
- Use test buttons as a workaround
- Try on a different device with better STT support
