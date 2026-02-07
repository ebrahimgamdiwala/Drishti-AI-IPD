# Quick Multilingual Implementation - 1 Hour Setup

## 🎯 Goal
Add Hindi, Tamil, Telugu, and Bengali support to Drishti app in 1 hour.

---

## Step 1: Update pubspec.yaml (2 minutes)

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0  # Already have this

flutter:
  generate: true  # Add this
```

Run:
```bash
flutter pub get
```

---

## Step 2: Create l10n.yaml (1 minute)

Create `l10n.yaml` in project root:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

---

## Step 3: Create Translation Files (15 minutes)

### Create `lib/l10n/` folder

### app_en.arb (English - Base)
```json
{
  "@@locale": "en",
  "appTitle": "Drishti",
  "welcome": "Welcome",
  "login": "Login",
  "signup": "Sign Up",
  "email": "Email",
  "password": "Password",
  "forgotPassword": "Forgot Password?",
  "addRelative": "Add Relative",
  "relatives": "Relatives",
  "settings": "Settings",
  "profile": "Profile",
  "dashboard": "Dashboard",
  "scanSurroundings": "Scan Surroundings",
  "readText": "Read Text",
  "detectObstacles": "Detect Obstacles",
  "identifyPeople": "Identify People",
  "darkMode": "Dark Mode",
  "lightMode": "Light Mode",
  "language": "Language",
  "logout": "Logout",
  "cancel": "Cancel",
  "save": "Save",
  "delete": "Delete",
  "edit": "Edit",
  "name": "Name",
  "relationship": "Relationship",
  "notes": "Notes",
  "takePhoto": "Take Photo",
  "skip": "Skip",
  "confirm": "Confirm",
  "loginSuccessful": "Login successful. Welcome!",
  "addRelativePrompt": "Let's add a new relative. I'll guide you through each step.",
  "speakName": "What is the person's name? Please speak clearly.",
  "speakRelationship": "What is their relationship to you?",
  "biometricLogin": "Biometric Login",
  "enableBiometric": "Enable {biometricType} Login?",
  "@enableBiometric": {
    "placeholders": {
      "biometricType": {
        "type": "String"
      }
    }
  }
}
```

### app_hi.arb (Hindi)
```json
{
  "@@locale": "hi",
  "appTitle": "दृष्टि",
  "welcome": "स्वागत है",
  "login": "लॉगिन",
  "signup": "साइन अप करें",
  "email": "ईमेल",
  "password": "पासवर्ड",
  "forgotPassword": "पासवर्ड भूल गए?",
  "addRelative": "रिश्तेदार जोड़ें",
  "relatives": "रिश्तेदार",
  "settings": "सेटिंग्स",
  "profile": "प्रोफ़ाइल",
  "dashboard": "डैशबोर्ड",
  "scanSurroundings": "आसपास स्कैन करें",
  "readText": "टेक्स्ट पढ़ें",
  "detectObstacles": "बाधाओं का पता लगाएं",
  "identifyPeople": "लोगों की पहचान करें",
  "darkMode": "डार्क मोड",
  "lightMode": "लाइट मोड",
  "language": "भाषा",
  "logout": "लॉगआउट",
  "cancel": "रद्द करें",
  "save": "सहेजें",
  "delete": "हटाएं",
  "edit": "संपादित करें",
  "name": "नाम",
  "relationship": "रिश्ता",
  "notes": "नोट्स",
  "takePhoto": "फोटो लें",
  "skip": "छोड़ें",
  "confirm": "पुष्टि करें",
  "loginSuccessful": "लॉगिन सफल। स्वागत है!",
  "addRelativePrompt": "आइए एक नया रिश्तेदार जोड़ें। मैं आपको हर कदम पर मार्गदर्शन करूंगा।",
  "speakName": "व्यक्ति का नाम क्या है? कृपया स्पष्ट रूप से बोलें।",
  "speakRelationship": "आपके साथ उनका क्या रिश्ता है?",
  "biometricLogin": "बायोमेट्रिक लॉगिन",
  "enableBiometric": "{biometricType} लॉगिन सक्षम करें?"
}
```

### app_ta.arb (Tamil)
```json
{
  "@@locale": "ta",
  "appTitle": "திருஷ்டி",
  "welcome": "வரவேற்கிறோம்",
  "login": "உள்நுழைய",
  "signup": "பதிவு செய்க",
  "email": "மின்னஞ்சல்",
  "password": "கடவுச்சொல்",
  "forgotPassword": "கடவுச்சொல்லை மறந்துவிட்டீர்களா?",
  "addRelative": "உறவினரைச் சேர்க்கவும்",
  "relatives": "உறவினர்கள்",
  "settings": "அமைப்புகள்",
  "profile": "சுயவிவரம்",
  "dashboard": "டாஷ்போர்டு",
  "scanSurroundings": "சுற்றுப்புறத்தை ஸ்கேன் செய்யவும்",
  "readText": "உரையைப் படிக்கவும்",
  "detectObstacles": "தடைகளைக் கண்டறியவும்",
  "identifyPeople": "மக்களை அடையாளம் காணவும்",
  "darkMode": "இருண்ட பயன்முறை",
  "lightMode": "ஒளி பயன்முறை",
  "language": "மொழி",
  "logout": "வெளியேறு",
  "cancel": "ரத்து செய்",
  "save": "சேமி",
  "delete": "நீக்கு",
  "edit": "திருத்து",
  "name": "பெயர்",
  "relationship": "உறவு",
  "notes": "குறிப்புகள்",
  "takePhoto": "புகைப்படம் எடு",
  "skip": "தவிர்",
  "confirm": "உறுதிப்படுத்து",
  "loginSuccessful": "உள்நுழைவு வெற்றிகரமாக இருந்தது. வரவேற்கிறோம்!",
  "addRelativePrompt": "ஒரு புதிய உறவினரைச் சேர்ப்போம். ஒவ்வொரு படியிலும் நான் உங்களுக்கு வழிகாட்டுவேன்.",
  "speakName": "நபரின் பெயர் என்ன? தயவுசெய்து தெளிவாகப் பேசுங்கள்.",
  "speakRelationship": "உங்களுடன் அவர்களின் உறவு என்ன?",
  "biometricLogin": "பயோமெட்ரிக் உள்நுழைவு",
  "enableBiometric": "{biometricType} உள்நுழைவை இயக்கவா?"
}
```

### app_te.arb (Telugu)
```json
{
  "@@locale": "te",
  "appTitle": "దృష్టి",
  "welcome": "స్వాగతం",
  "login": "లాగిన్",
  "signup": "సైన్ అప్",
  "email": "ఇమెయిల్",
  "password": "పాస్‌వర్డ్",
  "forgotPassword": "పాస్‌వర్డ్ మర్చిపోయారా?",
  "addRelative": "బంధువును జోడించండి",
  "relatives": "బంధువులు",
  "settings": "సెట్టింగ్‌లు",
  "profile": "ప్రొఫైల్",
  "dashboard": "డాష్‌బోర్డ్",
  "scanSurroundings": "పరిసరాలను స్కాన్ చేయండి",
  "readText": "టెక్స్ట్ చదవండి",
  "detectObstacles": "అడ్డంకులను గుర్తించండి",
  "identifyPeople": "వ్యక్తులను గుర్తించండి",
  "darkMode": "డార్క్ మోడ్",
  "lightMode": "లైట్ మోడ్",
  "language": "భాష",
  "logout": "లాగ్అవుట్",
  "cancel": "రద్దు చేయండి",
  "save": "సేవ్ చేయండి",
  "delete": "తొలగించండి",
  "edit": "సవరించండి",
  "name": "పేరు",
  "relationship": "సంబంధం",
  "notes": "గమనికలు",
  "takePhoto": "ఫోటో తీయండి",
  "skip": "దాటవేయండి",
  "confirm": "నిర్ధారించండి",
  "loginSuccessful": "లాగిన్ విజయవంతమైంది. స్వాగతం!",
  "addRelativePrompt": "కొత్త బంధువును జోడిద్దాం. ప్రతి దశలో నేను మీకు మార్గనిర్దేశం చేస్తాను.",
  "speakName": "వ్యక్తి పేరు ఏమిటి? దయచేసి స్పష్టంగా మాట్లాడండి.",
  "speakRelationship": "మీతో వారి సంబంధం ఏమిటి?",
  "biometricLogin": "బయోమెట్రిక్ లాగిన్",
  "enableBiometric": "{biometricType} లాగిన్‌ను ప్రారంభించాలా?"
}
```

### app_bn.arb (Bengali)
```json
{
  "@@locale": "bn",
  "appTitle": "দৃষ্টি",
  "welcome": "স্বাগতম",
  "login": "লগইন",
  "signup": "সাইন আপ",
  "email": "ইমেইল",
  "password": "পাসওয়ার্ড",
  "forgotPassword": "পাসওয়ার্ড ভুলে গেছেন?",
  "addRelative": "আত্মীয় যোগ করুন",
  "relatives": "আত্মীয়রা",
  "settings": "সেটিংস",
  "profile": "প্রোফাইল",
  "dashboard": "ড্যাশবোর্ড",
  "scanSurroundings": "চারপাশ স্ক্যান করুন",
  "readText": "টেক্সট পড়ুন",
  "detectObstacles": "বাধা সনাক্ত করুন",
  "identifyPeople": "মানুষ সনাক্ত করুন",
  "darkMode": "ডার্ক মোড",
  "lightMode": "লাইট মোড",
  "language": "ভাষা",
  "logout": "লগআউট",
  "cancel": "বাতিল",
  "save": "সংরক্ষণ",
  "delete": "মুছুন",
  "edit": "সম্পাদনা",
  "name": "নাম",
  "relationship": "সম্পর্ক",
  "notes": "নোট",
  "takePhoto": "ছবি তুলুন",
  "skip": "এড়িয়ে যান",
  "confirm": "নিশ্চিত করুন",
  "loginSuccessful": "লগইন সফল হয়েছে। স্বাগতম!",
  "addRelativePrompt": "চলুন একটি নতুন আত্মীয় যোগ করি। আমি প্রতিটি ধাপে আপনাকে গাইড করব।",
  "speakName": "ব্যক্তির নাম কী? দয়া করে স্পষ্টভাবে বলুন।",
  "speakRelationship": "আপনার সাথে তাদের সম্পর্ক কী?",
  "biometricLogin": "বায়োমেট্রিক লগইন",
  "enableBiometric": "{biometricType} লগইন সক্ষম করবেন?"
}
```

---

## Step 4: Update main.dart (5 minutes)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        // ... your other providers
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          title: 'Drishti',
          
          // Localization delegates
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          
          // Supported locales
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('hi', ''), // Hindi
            Locale('ta', ''), // Tamil
            Locale('te', ''), // Telugu
            Locale('bn', ''), // Bengali
          ],
          
          // Current locale
          locale: localeProvider.locale,
          
          // ... rest of your app config
        );
      },
    );
  }
}
```

---

## Step 5: Create LocaleProvider (10 minutes)

Create `lib/data/providers/locale_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale _locale = const Locale('en', '');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_localeKey);
      
      if (languageCode != null) {
        _locale = Locale(languageCode, '');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading locale: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  // Helper method to get language name
  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी';
      case 'ta':
        return 'தமிழ்';
      case 'te':
        return 'తెలుగు';
      case 'bn':
        return 'বাংলা';
      default:
        return 'English';
    }
  }
}
```

---

## Step 6: Add Language Selector to Settings (10 minutes)

Update your settings screen:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/locale_provider.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // Language Selector
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(localeProvider.getLanguageName(
              localeProvider.locale.languageCode,
            )),
            onTap: () => _showLanguageDialog(context),
          ),
          
          // ... other settings
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(context, 'en', 'English', localeProvider),
            _buildLanguageOption(context, 'hi', 'हिंदी', localeProvider),
            _buildLanguageOption(context, 'ta', 'தமிழ்', localeProvider),
            _buildLanguageOption(context, 'te', 'తెలుగు', localeProvider),
            _buildLanguageOption(context, 'bn', 'বাংলা', localeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String code,
    String name,
    LocaleProvider provider,
  ) {
    final isSelected = provider.locale.languageCode == code;
    
    return RadioListTile<String>(
      title: Text(name),
      value: code,
      groupValue: provider.locale.languageCode,
      onChanged: (value) {
        if (value != null) {
          provider.setLocale(Locale(value, ''));
          Navigator.pop(context);
        }
      },
      selected: isSelected,
    );
  }
}
```

---

## Step 7: Update Voice Service for Multilingual TTS (10 minutes)

Update `lib/data/services/voice_service.dart`:

```dart
class VoiceService {
  // ... existing code
  
  String _currentLanguageCode = 'en-IN';
  
  // Map language codes to TTS codes
  final Map<String, String> _languageToTTS = {
    'en': 'en-IN',
    'hi': 'hi-IN',
    'ta': 'ta-IN',
    'te': 'te-IN',
    'bn': 'bn-IN',
  };
  
  /// Set language for TTS
  Future<void> setLanguage(String languageCode) async {
    final ttsCode = _languageToTTS[languageCode] ?? 'en-IN';
    _currentLanguageCode = ttsCode;
    
    if (!kIsWeb) {
      await _tts.setLanguage(ttsCode);
    }
  }
  
  /// Speak with current language
  Future<void> speak(String text) async {
    if (!_ttsInitialized) await initTts();
    if (kIsWeb) return;

    // Ensure language is set
    await _tts.setLanguage(_currentLanguageCode);
    await _tts.stop();
    await _tts.speak(text);
  }
}
```

---

## Step 8: Update Usage in Widgets (5 minutes)

Replace hardcoded strings with localized versions:

### Before:
```dart
Text('Welcome')
```

### After:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Text(AppLocalizations.of(context)!.welcome)
```

### Example in Login Screen:
```dart
// Before
Text('Login')

// After
Text(AppLocalizations.of(context)!.login)
```

---

## Step 9: Generate Localization Files (1 minute)

```bash
flutter gen-l10n
# or
flutter pub get
```

This generates `app_localizations.dart` in `.dart_tool/flutter_gen/gen_l10n/`

---

## Step 10: Test (5 minutes)

```bash
flutter run
```

1. Open app
2. Go to Settings
3. Change language
4. Verify UI updates
5. Test voice output in different languages

---

## 🎯 Result

You now have:
- ✅ 5 languages (English, Hindi, Tamil, Telugu, Bengali)
- ✅ Language selector in settings
- ✅ Persistent language preference
- ✅ Multilingual TTS
- ✅ All UI text translated

---

## 📝 Next Steps

### Add More Languages (5 min each)
1. Create `app_XX.arb` file
2. Add translations
3. Add to `supportedLocales` in main.dart
4. Add to language selector
5. Add TTS mapping

### Add Voice Command Translation
```yaml
dependencies:
  google_mlkit_translation: ^0.11.0
```

### Add Auto Language Detection
```dart
import 'dart:ui' as ui;

final deviceLocale = ui.window.locale;
// Set as default language
```

---

## 🐛 Troubleshooting

### "AppLocalizations not found"
```bash
flutter clean
flutter pub get
flutter gen-l10n
```

### "Locale not changing"
- Check LocaleProvider is in MultiProvider
- Verify locale is being saved to SharedPreferences
- Restart app to test persistence

### "TTS not speaking in selected language"
- Check device has TTS engine for that language
- Install Google TTS from Play Store
- Download language pack in device settings

---

## 📊 File Structure

```
lib/
  l10n/
    app_en.arb
    app_hi.arb
    app_ta.arb
    app_te.arb
    app_bn.arb
  data/
    providers/
      locale_provider.dart
  main.dart
l10n.yaml
```

---

**Total Time**: ~1 hour
**Cost**: $0
**Offline**: ✅ Yes
**Maintenance**: Easy (just update .arb files)
