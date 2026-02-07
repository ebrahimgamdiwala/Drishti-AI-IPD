# Mobile App Backend Connection Fix

## ✅ Issue Fixed

**Error**: "Sign up failed - No internet connection"

**Cause**: The Flutter app was trying to connect to the wrong IP address (`192.168.1.7` instead of `192.168.1.8`)

**Solution**: Updated the base URL to your computer's correct IP address.

---

## 🔧 What Was Changed

### File: `drishti_mobile_app/lib/core/constants/api_endpoints.dart`

**Before**:
```dart
static const String baseUrl = 'http://192.168.1.7:8000';
```

**After**:
```dart
static const String baseUrl = 'http://192.168.1.8:8000';
```

---

## 🚀 How to Test

### 1. Make Sure Backend is Running

```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

You should see:
```
✅ Connected to MongoDB
🚀 Drishti AI FastAPI Server is running!
```

### 2. Verify Backend is Accessible

Open your browser and go to:
```
http://192.168.1.8:8000/api/health
```

You should see:
```json
{
  "status": "healthy",
  "message": "Drishti AI API is running"
}
```

### 3. Rebuild and Run the Flutter App

```bash
cd drishti_mobile_app
flutter run -d <your-device-id>
```

Or if already running, hot restart:
- Press `R` in the terminal
- Or press the hot restart button in your IDE

### 4. Test Signup

1. Open the app on your phone
2. Go to Sign Up screen
3. Fill in the details
4. Tap Sign Up
5. Should now work! ✅

---

## 🔍 Troubleshooting

### Still Getting "No Internet Connection"?

#### Check 1: Phone and Computer on Same WiFi
- ✅ Both devices must be on the **same WiFi network**
- ❌ Won't work if phone is on mobile data
- ❌ Won't work if computer is on Ethernet and phone on WiFi (unless same network)

#### Check 2: Firewall Settings
Windows Firewall might be blocking the connection.

**Allow Python through firewall**:
1. Open Windows Defender Firewall
2. Click "Allow an app through firewall"
3. Find Python or add it manually
4. Check both "Private" and "Public" boxes

**Or temporarily disable firewall** (for testing):
```powershell
# Run as Administrator
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
```

**Re-enable after testing**:
```powershell
# Run as Administrator
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
```

#### Check 3: Backend is Listening on All Interfaces
Make sure you're using `--host 0.0.0.0` (not `127.0.0.1` or `localhost`):

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### Check 4: Port is Not Blocked
Test if port 8000 is accessible from your phone:

**From your phone's browser**, visit:
```
http://192.168.1.8:8000/api/health
```

If you see JSON response, the connection works!

#### Check 5: IP Address Changed
Your computer's IP might change. To check current IP:

**Windows**:
```powershell
ipconfig | Select-String -Pattern "IPv4"
```

**Mac/Linux**:
```bash
ifconfig | grep "inet "
```

Update `api_endpoints.dart` with the new IP if it changed.

---

## 📱 Alternative: Use ngrok (For Testing)

If local network connection doesn't work, use ngrok to expose your backend:

### 1. Install ngrok
Download from: https://ngrok.com/download

### 2. Start ngrok
```bash
ngrok http 8000
```

You'll get a URL like: `https://abc123.ngrok.io`

### 3. Update Flutter App
In `api_endpoints.dart`:
```dart
static const String baseUrl = 'https://abc123.ngrok.io';
```

### 4. Update Backend CORS
In `backend/app/main.py`, add ngrok URL to allowed origins:
```python
origins = [
    "http://localhost:5173",
    "https://abc123.ngrok.io",  # Add this
]
```

---

## 🔐 Security Notes

### For Development:
- ✅ Using local IP (192.168.1.8) is fine
- ✅ Using ngrok is fine for testing

### For Production:
- ❌ Don't hardcode IP addresses
- ✅ Use environment variables
- ✅ Use proper domain names
- ✅ Use HTTPS

---

## 📝 Quick Checklist

Before running the app:

- [ ] Backend server is running (`uvicorn ... --host 0.0.0.0`)
- [ ] Backend is accessible from browser (`http://192.168.1.8:8000/api/health`)
- [ ] Phone and computer on same WiFi
- [ ] Firewall allows Python/port 8000
- [ ] IP address in `api_endpoints.dart` is correct
- [ ] App has been rebuilt/restarted after changing IP

---

## 🎯 Expected Flow

### Successful Connection:
```
1. User taps "Sign Up"
2. App sends POST to http://192.168.1.8:8000/api/auth/signup
3. Backend receives request
4. Backend creates user in MongoDB
5. Backend returns success + token
6. App stores token
7. App navigates to dashboard
8. ✅ Success!
```

### Failed Connection:
```
1. User taps "Sign Up"
2. App tries to connect to http://192.168.1.8:8000
3. ❌ Connection timeout (wrong IP or firewall)
4. App shows "No internet connection"
```

---

## 🔄 If IP Changes Frequently

Create a configuration file that's easier to update:

### Option 1: Environment Variable (Recommended)

Create `drishti_mobile_app/.env`:
```
API_BASE_URL=http://192.168.1.8:8000
```

Then use a package like `flutter_dotenv` to load it.

### Option 2: Config File

Create `drishti_mobile_app/lib/config/app_config.dart`:
```dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.8:8000',
  );
}
```

Run with:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.8:8000
```

---

## 📞 Summary

**Problem**: App couldn't connect to backend
**Root Cause**: Wrong IP address in configuration
**Solution**: Updated IP from `192.168.1.7` to `192.168.1.8`
**Status**: ✅ Fixed

**Now your app should connect successfully!** 🎉

---

**Date**: February 7, 2026
**Status**: ✅ FIXED
