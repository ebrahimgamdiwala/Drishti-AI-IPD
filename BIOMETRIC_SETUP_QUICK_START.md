# Biometric Authentication - Quick Start

## Installation

### 1. Install Dependencies
```bash
cd drishti_mobile_app
flutter pub get
```

### 2. Android Setup
No additional setup required. Permissions are already added to `AndroidManifest.xml`.

### 3. iOS Setup
No additional setup required. Face ID permission is already added to `Info.plist`.

### 4. Build and Run
```bash
# Android
flutter run -d <android-device-id>

# iOS
flutter run -d <ios-device-id>
```

## Usage

### For Users

#### Enable Biometric Login
1. Open the app
2. Login with email and password
3. When prompted "Enable [Fingerprint/Face ID] Login?", tap **Enable**
4. Authenticate with your fingerprint or Face ID
5. Done! Next time you open the app, it will auto-login

#### Use Biometric Login
1. Open the app
2. Biometric prompt appears automatically
3. Authenticate with fingerprint or Face ID
4. You're logged in!

#### Manual Biometric Login
1. Open the app
2. Tap the fingerprint button (bottom right)
3. Authenticate with fingerprint or Face ID
4. You're logged in!

#### Disable Biometric Login
Currently, biometric can be disabled by:
1. Logging out of the app
2. Clearing app data in device settings

*Note: Settings screen integration coming soon*

### For Developers

#### Check Biometric Availability
```dart
import 'package:drishti_mobile_app/data/services/biometric_service.dart';

final biometricService = BiometricService();
final available = await biometricService.isBiometricAvailable();

if (available) {
  print('Biometric is available');
  final typeName = await biometricService.getBiometricTypeName();
  print('Type: $typeName'); // "Fingerprint" or "Face ID"
}
```

#### Enable Biometric
```dart
final success = await biometricService.enableBiometric(
  email: 'user@example.com',
  password: 'securePassword123',
);

if (success) {
  print('Biometric enabled successfully');
}
```

#### Authenticate and Login
```dart
final credentials = await biometricService.authenticateAndGetCredentials();

if (credentials != null) {
  final email = credentials['email'];
  final password = credentials['password'];
  // Proceed with login
}
```

#### Disable Biometric
```dart
await biometricService.disableBiometric();
print('Biometric disabled');
```

## Testing

### Test on Physical Device

#### Android
1. Go to Settings → Security → Fingerprint
2. Add at least one fingerprint
3. Run the app
4. Login and enable biometric
5. Close and reopen app to test auto-login

#### iOS
1. Go to Settings → Face ID & Passcode (or Touch ID)
2. Enroll Face ID or Touch ID
3. Run the app
4. Login and enable biometric
5. Close and reopen app to test auto-login

### Test on Emulator

#### Android Emulator
1. Open emulator settings
2. Go to Fingerprint section
3. Add virtual fingerprint
4. Use "Touch the sensor" button to simulate fingerprint

#### iOS Simulator
1. Face ID: Hardware → Face ID → Enrolled
2. Touch ID: Hardware → Touch ID → Enrolled
3. Simulate authentication: Hardware → Face ID/Touch ID → Matching Face/Touch

## Troubleshooting

### "Biometric not available"
- Ensure device has biometric hardware
- Check if at least one biometric is enrolled
- Verify app permissions in device settings

### Auto-login not working
- Ensure biometric was enabled after successful login
- Check if credentials are still valid
- Try disabling and re-enabling biometric

### Authentication fails repeatedly
- Clean your fingerprint sensor
- Try different finger or angle
- Re-enroll biometric in device settings
- Use device PIN/Pattern as fallback

## Features Summary

✅ **Implemented**:
- Fingerprint authentication (Android & iOS)
- Face ID authentication (iOS)
- Auto-login on app start
- Secure credential storage
- Enable biometric after login
- Manual biometric login button
- Voice announcements
- Error handling
- Platform-specific permissions

🚧 **Coming Soon**:
- Settings screen integration
- Disable biometric from settings
- Multiple account support
- Biometric for sensitive actions
- Voice commands for biometric

## Security Notes

- Credentials are encrypted using platform keystore/keychain
- Biometric authentication required to access credentials
- Credentials cleared on biometric disable
- No plain text password storage
- Secure storage using `flutter_secure_storage`

## Support

If you encounter issues:
1. Check device biometric settings
2. Verify app has necessary permissions
3. Test on physical device (emulators have limitations)
4. Check console logs for error messages
5. Ensure device is not rooted/jailbroken
