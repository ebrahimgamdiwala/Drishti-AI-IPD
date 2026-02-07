/// Drishti App - Locale Provider
///
/// Manages app language/locale with persistence and voice support.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/voice_service.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale _locale = const Locale('en', '');
  final VoiceService _voiceService = VoiceService();

  Locale get locale => _locale;

  // Language code to TTS code mapping
  final Map<String, String> _languageToTTS = {
    'en': 'en-IN',
    'hi': 'hi-IN',
    'ta': 'ta-IN',
    'te': 'te-IN',
    'bn': 'bn-IN',
  };

  // Language code to STT locale mapping
  final Map<String, String> _languageToSTT = {
    'en': 'en_IN',
    'hi': 'hi_IN',
    'ta': 'ta_IN',
    'te': 'te_IN',
    'bn': 'bn_IN',
  };

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_localeKey);
      
      if (languageCode != null) {
        _locale = Locale(languageCode, '');
        await _updateVoiceLanguage(languageCode);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[LocaleProvider] Error loading locale: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
      
      // Update voice service language
      await _updateVoiceLanguage(locale.languageCode);
      
      // Announce language change
      await _announceLanguageChange(locale.languageCode);
    } catch (e) {
      debugPrint('[LocaleProvider] Error saving locale: $e');
    }
  }

  Future<void> _updateVoiceLanguage(String languageCode) async {
    final ttsCode = _languageToTTS[languageCode] ?? 'en-IN';
    
    try {
      await _voiceService.initTts();
      await _voiceService.setLanguage(ttsCode);
      debugPrint('[LocaleProvider] Voice language updated to: $ttsCode');
    } catch (e) {
      debugPrint('[LocaleProvider] Error updating voice language: $e');
    }
  }

  Future<void> _announceLanguageChange(String languageCode) async {
    final messages = {
      'en': 'Language changed to English',
      'hi': 'भाषा हिंदी में बदली गई',
      'ta': 'மொழி தமிழாக மாற்றப்பட்டது',
      'te': 'భాష తెలుగులోకి మార్చబడింది',
      'bn': 'ভাষা বাংলায় পরিবর্তিত হয়েছে',
    };
    
    final message = messages[languageCode] ?? messages['en']!;
    await _voiceService.speak(message);
  }

  /// Get TTS language code for current locale
  String getTTSLanguageCode() {
    return _languageToTTS[_locale.languageCode] ?? 'en-IN';
  }

  /// Get STT locale ID for current locale
  String getSTTLocaleId() {
    return _languageToSTT[_locale.languageCode] ?? 'en_IN';
  }

  /// Get language name in its native script
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

  /// Get all supported locales
  List<Locale> getSupportedLocales() {
    return const [
      Locale('en', ''),
      Locale('hi', ''),
      Locale('ta', ''),
      Locale('te', ''),
      Locale('bn', ''),
    ];
  }

  /// Check if a language is supported
  bool isLanguageSupported(String code) {
    return _languageToTTS.containsKey(code);
  }
}
