# Drishti Mobile App 👁️✨

**Your Vision Companion** - Accessibility-first mobile app with modern iOS-inspired glassmorphism design.

## 🎨 Design Features

### ✨ Glassmorphism UI
The app features a stunning **iOS-inspired glassmorphism design** with:

- 🔮 **Glass effect components** with blur and transparency
- 🎭 **Smooth animations** and transitions
- 🌈 **Beautiful gradients** throughout the app
- 📱 **Modern iOS aesthetics** with clean design
- 🌓 **Light and dark mode** support

### 🎬 Animated Splash Screen
A beautiful loading experience featuring:
- **Elegant glass orb** with pulsing glow effect
- **"Drishti AI"** branding with modern Outfit font
- **Circular expansion** animation on completion
- **Shimmer loading bar** with smooth animation
- **Purple-blue gradient** background

## 🚀 Quick Start

### Prerequisites
- Flutter SDK ^3.10.7
- Dart SDK ^3.10.7
- Android Studio / Xcode

### Installation
```bash
# Navigate to the directory
cd drishti_mobile_app

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## 🎯 Glassmorphism Components

### Reusable Widgets
- `GlassCard` - Cards with glass effect
- `GlassButton` - iOS-style buttons
- `GlassTextField` - Modern input fields
- `GlassAppBar` - Transparent app bars
- `GlassBottomNavBar` - Glass navigation
- `GlassContainer` - Base glass container
- `GradientBackground` - Gradient wrapper

### Example Usage
```dart
import 'package:drishti_mobile_app/presentation/widgets/glass_widgets.dart';

GradientBackground(
  child: Scaffold(
    backgroundColor: Colors.transparent,
    body: GlassCard(
      child: Column(
        children: [
          GlassTextField(
            labelText: 'Email',
            hintText: 'Enter email',
          ),
          GlassButton(
            text: 'Submit',
            onPressed: () {},
          ),
        ],
      ),
    ),
  ),
)
```

## 🎨 Design System

### Colors
- **Primary**: iOS Blue (#007AFF)
- **Glass Effects**: Frosted glass with blur
- **Gradients**: Purple → Blue → Cyan

### Typography
- **Display Font**: Outfit (Splash, Headers)
- **Body Font**: Inter (Content)
- **Weights**: 400, 500, 600, 700

### Spacing
- **Padding**: 12, 16, 20, 24px
- **Radius**: 12, 20, 30, 40px
- **Blur**: 10, 20, 30 sigma

## 📱 Screens

### Implemented
- ✅ Animated Splash Screen
- ✅ Login Screen (Glassmorphism)
- ✅ Home Screen
- ✅ Settings Screen
- ✅ Profile Screen

## 🛠️ Tech Stack

- **Framework**: Flutter 3.10.7
- **Language**: Dart 3.10.7
- **State Management**: Provider
- **Animations**: flutter_animate
- **Fonts**: Google Fonts (Outfit, Inter)
- **Storage**: Hive, Shared Preferences

## 📦 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_colors.dart     # Glassmorphism colors
│   └── themes/
│       ├── light_theme.dart    # iOS light theme
│       └── dark_theme.dart     # iOS dark theme
├── presentation/
│   ├── widgets/
│   │   ├── glass_widgets.dart  # Export file
│   │   ├── glass_card.dart
│   │   ├── glass_button.dart
│   │   ├── glass_text_field.dart
│   │   ├── glass_app_bar.dart
│   │   └── gradient_background.dart
│   └── screens/
│       ├── splash/
│       │   └── splash_screen.dart  # Animated splash
│       ├── auth/
│       │   └── login_screen.dart   # Glass login
│       └── home/
│           └── home_screen.dart
└── main.dart
```

## 🎯 Features

### Accessibility
- Screen reader support
- Voice feedback
- High contrast mode
- Adjustable text sizes
- Semantic labels

### Performance
- Optimized blur effects
- Smooth 60fps animations
- Efficient rendering
- Memory management

## 📄 License

MIT License

## 👥 Team

Drishti AI Development Team

---

**Made with ❤️** ✨
