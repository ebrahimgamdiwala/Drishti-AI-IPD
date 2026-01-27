# Hotword Debug Instructions

## Critical: Share These Console Logs

When you run the app, please copy and share ALL console output that starts with:
- `[VoiceService]`
- `[HomeScreen]`
- `[VoiceNav]`

This will help me see exactly what's happening.

## What to Check

### 1. App Starts
Look for these logs when the app first loads:
```
[HomeScreen] Checking STT availability...
[HomeScreen] ✅ STT available, starting hotword listening
[VoiceService] startHotwordListening called
[VoiceService] Initializing STT...
[VoiceService] ✅ STT initialized
[VoiceService] ✅ Starting hotword listening for "hey vision"
[VoiceService] Starting hotword listening cycle...
```

**If you DON'T see these logs**, hotword listening isn't starting. Share what you DO see.

### 2. Visual Indicator
On the home screen, do you see:
- Blue badge with "🎤 Say 'Hey Vision' to activate"?
- YES → Hotword listening should be active
- NO → Hotword listening failed to start

### 3. Say "Hey Vision"
When you say "Hey Vision", look for:
```
[VoiceService] Heard: "..." (final: false)
[VoiceService] Heard: "hey vision" (final: true)
[VoiceService] ✅ Hotword detected: hey vision
```

**If you see "Heard: ..." logs:**
- Good! STT is working and listening
- Check what it's hearing - is it close to "hey vision"?
- Try different pronunciations

**If you DON'T see "Heard: ..." logs:**
- STT might not be listening
- Check if you see "Starting hotword listening cycle..."
- Share all console output

### 4. Common Issues

#### Issue: No logs at all
**Possible causes:**
- STT not available on device
- Permissions not granted
- App crashed during initialization

**What to share:**
- Full console output from app start
- Any error messages

#### Issue: "Heard: ..." but wrong words
**Example:**
```
[VoiceService] Heard: "a vision" (final: true)
[VoiceService] No hotword in: "a vision", restarting...
```

**This means:**
- STT is working!
- It's just not hearing "hey vision" correctly
- Try: "HEY VISION" (louder, clearer)
- Try: "Hey... Vision" (with pause)

#### Issue: Logs stop after first cycle
**Example:**
```
[VoiceService] Starting hotword listening cycle...
[VoiceService] Heard: "something" (final: true)
[VoiceService] No hotword in: "something", restarting...
(then nothing)
```

**This means:**
- Hotword listening stopped restarting
- Possible STT timeout or error
- Share the full log sequence

## Quick Test

1. **Run the app**:
   ```bash
   flutter run -d DN2101
   ```

2. **Immediately check console** for startup logs

3. **Look at home screen** for blue badge

4. **Say "Hey Vision"** 3 times, waiting 2 seconds between each

5. **Copy ALL console output** and share it

## What I Need From You

Please share:
1. ✅ Do you see the blue "Say 'Hey Vision' to activate" badge?
2. ✅ Full console output (all `[VoiceService]` and `[HomeScreen]` logs)
3. ✅ What happens when you say "Hey Vision"?
4. ✅ Any error messages you see

## Alternative: Manual Test

If hotword still doesn't work, try this:
1. **Tap the microphone button** (don't use hotword)
2. **Say "go to settings"**
3. Does it work?

If manual mic tap works but hotword doesn't, the issue is specifically with hotword detection, not STT in general.

## Expected Full Log Sequence

Here's what you SHOULD see:

```
[HomeScreen] Checking STT availability...
[HomeScreen] ✅ STT available, starting hotword listening
[VoiceService] startHotwordListening called
[VoiceService] ✅ STT initialized
[VoiceService] ✅ Starting hotword listening for "hey vision"
[VoiceService] Starting hotword listening cycle...
[VoiceService] Heard: "hey" (final: false)
[VoiceService] Heard: "hey vision" (final: false)
[VoiceService] Heard: "hey vision" (final: true)
[VoiceService] ✅ Hotword detected: hey vision
[HomeScreen] 🎤 Hotword detected! Starting voice command...
[VoiceService] Pausing hotword listening for voice command
[VoiceNav] Starting listening via microphone tap
```

If your logs look different, share them!
