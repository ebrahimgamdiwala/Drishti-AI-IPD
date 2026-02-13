# App Crash Fix - setState During Build

## 🔴 The Problem

The app was crashing with this error:
```
setState() or markNeedsBuild() called during build.
```

This happened because `AuthProvider.init()` was calling `notifyListeners()` during the widget build phase, which is not allowed in Flutter.

## 🔍 Root Cause

**Location:** `SplashScreen._initialize()` → `AuthProvider.init()`

**What was happening:**
1. `SplashScreen.initState()` calls `_initialize()`
2. `_initialize()` immediately calls `authProvider.init()`
3. `authProvider.init()` calls `notifyListeners()` TWICE
4. This happens while Flutter is still building the widget tree
5. ❌ Flutter throws an exception

## ✅ The Fix

### 1. Deferred Initialization in SplashScreen

**File:** `lib/presentation/screens/splash/splash_screen.dart`

```dart
// Before:
Future<void> _initialize() async {
  final authProvider = context.read<AuthProvider>();
  await authProvider.init();
  _isAuthenticated = authProvider.isAuthenticated;
  // ...
}

// After:
Future<void> _initialize() async {
  // Defer initialization until after the first frame
  await Future.microtask(() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.init();
    
    if (!mounted) return;
    
    _isAuthenticated = authProvider.isAuthenticated;
  });
  // ...
}
```

**Why this works:**
- `Future.microtask()` defers execution until after the current build phase
- This ensures `notifyListeners()` is called AFTER the widget tree is built

### 2. Optimized AuthProvider.init()

**File:** `lib/data/providers/auth_provider.dart`

```dart
// Before:
Future<void> init() async {
  _status = AuthStatus.loading;
  notifyListeners(); // ❌ Called during build
  
  // ... do work ...
  
  notifyListeners(); // ❌ Called again
}

// After:
Future<void> init() async {
  _status = AuthStatus.loading;
  // Don't notify yet
  
  // ... do work ...
  
  notifyListeners(); // ✅ Only notify once at the end
}
```

**Why this works:**
- Reduces unnecessary notifications
- Only notifies listeners once when initialization is complete
- More efficient and avoids potential race conditions

## 🧪 Testing

After this fix:
1. ✅ App launches without crashing
2. ✅ Splash screen displays correctly
3. ✅ Auth state is properly initialized
4. ✅ Navigation works as expected

## 📚 Flutter Best Practices

### When to Call notifyListeners()

✅ **DO:**
- Call after async operations complete
- Call in response to user actions
- Call in event handlers
- Use `Future.microtask()` or `WidgetsBinding.instance.addPostFrameCallback()` if needed during init

❌ **DON'T:**
- Call during `initState()` without deferring
- Call during `build()` method
- Call synchronously during widget construction
- Call multiple times unnecessarily

### Alternative Approaches

If you need to initialize a provider, you can also:

1. **Use WidgetsBinding.addPostFrameCallback:**
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<AuthProvider>().init();
  });
}
```

2. **Use FutureBuilder:**
```dart
FutureBuilder(
  future: context.read<AuthProvider>().init(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return LoadingWidget();
    }
    return MainWidget();
  },
)
```

3. **Initialize in main() before runApp():**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.init();
  runApp(MyApp(authProvider: authProvider));
}
```

## 🔗 Related Issues

This fix also prevents:
- "Looking up a deactivated widget's ancestor is unsafe" errors
- Race conditions during initialization
- Unnecessary rebuilds
- Performance issues from multiple notifications

## 📝 Summary

**Changed Files:**
1. `lib/data/providers/auth_provider.dart` - Removed duplicate notifyListeners()
2. `lib/presentation/screens/splash/splash_screen.dart` - Deferred initialization with Future.microtask()

**Result:** App no longer crashes on startup! 🎉
