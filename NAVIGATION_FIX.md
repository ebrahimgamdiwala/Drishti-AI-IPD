# Voice Navigation Fix - January 26, 2026

## Issue
Voice navigation was not working. When saying "go to dashboard" or using test buttons, the app would announce navigation but not actually change screens.

## Root Cause
The app uses a `MainShell` with `IndexedStack` for bottom navigation (Home, Dashboard, Settings, etc.). These screens are not separate routes - they're all part of the same main screen with different tabs.

The `VoiceRouter` was trying to use `Navigator.pushNamed()` to navigate to routes like `/dashboard`, but these routes don't exist as separate navigation destinations. They're just different indices in the IndexedStack.

## Solution

### 1. Added Navigation Method to MainShell
Created `navigateToRoute(String route)` method in `MainShell` that:
- Maps route names to tab indices
- Changes the `_currentIndex` to switch tabs
- Announces the new screen after navigation

### 2. Exposed MainShell State via GlobalKey
Added `static final GlobalKey<_MainShellState> shellKey` to MainShell so VoiceRouter can access it.

### 3. Updated VoiceRouter
Modified `navigateTo()` method to:
- Check if the route is a main shell route (home, dashboard, settings, etc.)
- If yes: Use `MainShell.shellKey.currentState.navigateToRoute()`
- If no: Fall back to regular `Navigator.pushNamed()` for other routes

## Route Mapping

```dart
'/home' → Tab 0 (HomeScreen)
'/dashboard' → Tab 1 (DashboardScreen)
'/vision' → Tab 2 (VLMChatScreen)
'/relatives' → Tab 3 (RelativesScreen)
'/activity' → Tab 4 (ActivityScreen)
'/settings' → Tab 5 (SettingsScreen)
```

## Files Modified

- `lib/presentation/screens/main_shell.dart`
  - Added `shellKey` static field
  - Added `navigateToRoute()` method
  - Updated build method to use the key

- `lib/data/services/voice_navigation/voice_router.dart`
  - Imported MainShell
  - Updated `navigateTo()` to use MainShell navigation for tab screens

## Testing

1. Open the app
2. Tap microphone or use test buttons
3. Say "go to dashboard" or tap "Dashboard" test button
4. Should switch to Dashboard tab ✅
5. Try other screens: Settings, Relatives, Activity
6. All should navigate correctly ✅

## Status

✅ Voice navigation now works correctly
✅ Test buttons work
✅ Screen announcements work
✅ No more redirects to permissions screen
✅ No compilation errors

The navigation is now fully functional!
