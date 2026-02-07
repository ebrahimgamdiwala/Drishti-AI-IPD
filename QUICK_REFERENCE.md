# Drishti App - Quick Reference Card

## 🎯 Quick Start

### First Time Setup
1. Install app on device
2. Grant permissions (camera, mic, storage)
3. Sign up or login
4. Enable biometric when prompted
5. Say "Hey Vision" to start

---

## 🎤 Voice Commands

### Hotword
**"Hey Vision"** - Activate voice control

### Navigation
- "go home"
- "dashboard"
- "settings"
- "relatives"
- "profile"
- "go back"

### Add Relative (Voice-Guided)
1. Say: **"add relative"**
2. Wait for prompt, then speak name
3. Wait for prompt, then speak relationship
4. Say "take photo" or "skip"
5. Say notes or "skip"
6. Say "save"

### Theme
- **"toggle theme"** - Switch light/dark
- **"dark mode"** - Enable dark theme
- **"light mode"** - Enable light theme

### Control
- **"stop listening"** - Stop voice control
- **"stop"** - Stop speaking
- **"repeat"** - Repeat last message

---

## 🔐 Biometric Login

### Enable
1. Login with email/password
2. Tap "Enable" when prompted
3. Authenticate with fingerprint/Face ID

### Use
- **Auto**: Opens automatically on app start
- **Manual**: Tap fingerprint button on login screen

### Supported
- ✅ Fingerprint (Android & iOS)
- ✅ Face ID (iOS)
- ✅ Touch ID (iOS)
- ✅ Device PIN/Pattern (fallback)

---

## 🎨 Theme Toggle

### Commands
- "toggle theme"
- "dark mode"
- "light mode"

### Result
Theme changes immediately

---

## 🛑 Stop Listening

### Commands
- "stop listening"
- "quiet"
- "silence"

### What Happens
- Voice control stops
- Audio confirmation
- Tap mic to restart

---

## 🔧 Troubleshooting

### Voice not working?
- Check microphone permission
- Say "Hey Vision" clearly
- Ensure quiet environment
- Check internet connection

### Theme not changing?
- Wait for previous command to finish
- Say exact command
- Check if hotword is active

### Biometric not available?
- Enroll fingerprint/Face ID in device settings
- Check app permissions
- Restart app

### Voice input not captured?
- Wait for prompt to finish
- Speak clearly
- Check microphone
- Try again (auto-retry)

---

## 📱 Device Requirements

### Android
- Android 6.0+ (API 23+)
- Microphone
- Camera (optional)
- Fingerprint sensor (for biometric)

### iOS
- iOS 11.0+
- Microphone
- Camera (optional)
- Touch ID or Face ID (for biometric)

---

## 🔒 Security

### What's Encrypted
- ✅ Login credentials
- ✅ Biometric data
- ✅ Auth tokens
- ✅ User data

### What's Secure
- ✅ HTTPS communication
- ✅ Platform keystore/keychain
- ✅ No plain text passwords
- ✅ Secure storage

---

## 📚 Documentation

- `ALL_FEATURES_SUMMARY.md` - Complete feature list
- `VOICE_CONTROL_FIXES_SUMMARY.md` - Voice control guide
- `BIOMETRIC_AUTHENTICATION_GUIDE.md` - Biometric guide
- `BIOMETRIC_SETUP_QUICK_START.md` - Quick setup

---

## 🆘 Need Help?

1. Check documentation files
2. Review error messages
3. Test on physical device
4. Verify permissions
5. Check console logs

---

## ✨ Tips & Tricks

### Voice Control
- Speak clearly and at normal pace
- Wait for prompts to finish
- Use "stop listening" to cancel
- Say "repeat" if you missed something

### Biometric
- Clean fingerprint sensor
- Try different fingers
- Use good lighting for Face ID
- Enable after first login for best experience

### Theme
- Use voice commands for hands-free
- Theme persists across sessions
- Works in all screens

### Add Relative
- Have photo ready
- Speak full names clearly
- Use common relationship terms
- Can skip optional fields

---

## 🎯 Common Tasks

### Login
1. Open app
2. Authenticate with biometric OR
3. Enter email/password
4. Tap Login

### Add Relative
1. Say "Hey Vision"
2. Say "add relative"
3. Follow voice prompts
4. Take photo
5. Say "save"

### Change Theme
1. Say "Hey Vision"
2. Say "toggle theme" OR
3. Say "dark mode" / "light mode"

### Stop Voice
1. Say "stop listening"
2. Tap microphone to restart

---

## 📊 Status Indicators

### Voice Control
- 🎤 **Listening** - Microphone active
- 🔵 **Processing** - Command being processed
- 🔊 **Speaking** - Audio feedback playing
- ⭕ **Idle** - Ready for hotword

### Biometric
- 🟢 **Available** - Fingerprint button enabled
- 🔴 **Not Available** - Fingerprint button disabled
- 🔒 **Enabled** - Auto-login active
- 🔓 **Disabled** - Manual login only

---

## 🚀 Performance Tips

- Close unused apps
- Ensure good network connection
- Keep device updated
- Clear app cache periodically
- Use physical device (not emulator)

---

**Version**: 1.0.0  
**Last Updated**: 2024  
**Platform**: Flutter (Android & iOS)
