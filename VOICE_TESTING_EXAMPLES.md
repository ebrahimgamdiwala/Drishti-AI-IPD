# Voice Control Testing Examples

## 🎯 Quick Test Commands

### 1. Navigation Tests
```
"Hey Vision"
"Go to dashboard"
```
Expected: Navigates to dashboard and announces available actions

```
"Hey Vision"
"Go to settings"
```
Expected: Opens settings page

```
"Hey Vision"
"Go to relatives"
```
Expected: Opens relatives/family page

```
"Hey Vision"
"Go home"
```
Expected: Returns to home screen

---

### 2. Relatives Management Tests

```
"Hey Vision"
"Add relative"
```
Expected: 
- Navigates to relatives page
- Says: "Opening relatives page. To add a new relative, tap the add button and follow the prompts."

```
"Hey Vision"
"Show relatives"
```
Expected:
- Navigates to relatives page
- Says: "Showing all relatives."

```
"Hey Vision"
"Create new relative"
```
Expected: Same as "Add relative"

---

### 3. Settings Control Tests

```
"Hey Vision"
"Increase volume"
```
Expected:
- Navigates to settings (if not already there)
- Increases volume by 10%
- Says: "Volume increased to X percent"

```
"Hey Vision"
"Speak faster"
```
Expected:
- Navigates to settings
- Increases speech speed
- Says: "Speech speed increased" (in faster voice)

```
"Hey Vision"
"Emergency contact"
```
Expected:
- Navigates to settings
- Says: "Emergency contact settings are on the settings page. Scroll down to find emergency contact options."

```
"Hey Vision"
"Change theme"
```
Expected:
- Navigates to settings
- Says: "Theme settings are on the settings page. You can toggle between light and dark mode."

---

### 4. Vision/Scanning Tests

```
"Hey Vision"
"Scan surroundings"
```
Expected: Analyzes current camera view and describes it

```
"Hey Vision"
"What's in front of me?"
```
Expected: Describes what the camera sees

```
"Hey Vision"
"Detect obstacles"
```
Expected: Identifies obstacles in view

```
"Hey Vision"
"Read text"
```
Expected: Reads any text visible in camera view

---

### 5. System Information Tests

```
"Hey Vision"
"Battery status"
```
Expected:
- Says: "Battery information is available on the dashboard."
- Navigates to dashboard

```
"Hey Vision"
"Am I online?"
```
Expected: Says: "You are currently online."

---

### 6. Multi-Step Test Sequence

Try this complete workflow:

1. **"Hey Vision"** → Wait for beep
2. **"Go to dashboard"** → Should navigate and announce
3. Wait 5 seconds for hotword to restart
4. **"Hey Vision"** → Wait for beep
5. **"Go to settings"** → Should navigate
6. Wait 5 seconds
7. **"Hey Vision"** → Wait for beep
8. **"Increase volume"** → Should increase volume
9. Wait 5 seconds
10. **"Hey Vision"** → Wait for beep
11. **"Go home"** → Should return to home

---

## 🐛 Troubleshooting

### If hotword stops working after 2 commands:
- Check logs for: `[MainShell] ✅ Hotword listening restarted successfully`
- Should see this message 5 seconds after each command
- If not appearing, there's an issue with the restart logic

### If commands aren't recognized:
- Speak clearly and at normal pace
- Wait for the beep/confirmation before speaking command
- Make sure you're in a quiet environment
- Check that microphone permissions are granted

### If navigation doesn't work:
- Check logs for: `[VoiceRouter] Navigating to: /route`
- Verify the route exists in the app

### If settings commands don't work:
- Check logs for: `[VoiceNav] Handling settings intent`
- Verify you're saying the exact command phrases

---

## 📊 Expected Log Output

For a successful command sequence, you should see:

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

---

## ✅ Success Criteria

- [ ] Hotword "Hey Vision" is detected consistently
- [ ] Commands work at least 5 times in a row
- [ ] Navigation to all screens works
- [ ] Volume and speech speed adjustments work
- [ ] Settings page opens when requested
- [ ] Relatives page opens when requested
- [ ] System provides clear audio feedback for each action
- [ ] Hotword listening restarts automatically after each command

---

## 🎤 Voice Command Patterns

The system recognizes these patterns:

### Navigation
- "go to [screen]"
- "open [screen]"
- "show me [screen]"
- "navigate to [screen]"

### Relatives
- "add relative"
- "create relative"
- "new relative"
- "show relatives"
- "list family"

### Settings
- "increase/decrease volume"
- "louder/quieter"
- "faster/slower"
- "change theme"
- "emergency contact"

### Vision
- "scan [something]"
- "what's [location]"
- "describe [something]"
- "detect obstacles"
- "read text"

---

## 🔧 Quick Fixes

If something isn't working:

1. **Restart the app** - Clears any stuck states
2. **Check microphone permissions** - Settings > Apps > Drishti > Permissions
3. **Test STT separately** - Tap the mic button manually to verify STT works
4. **Check internet connection** - Cloud STT requires internet
5. **Clear app cache** - Settings > Apps > Drishti > Clear Cache

---

**Remember**: Wait 5 seconds between commands to allow hotword listening to restart!
