/// Drishti App - Theme Provider
/// 
/// Manages light/dark theme state with persistence.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

enum ThemeType { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeType _themeType = ThemeType.system;
  ThemeData _themeData = lightTheme;
  
  ThemeType get themeType => _themeType;
  ThemeData get themeData => _themeData;
  bool get isDarkMode => _themeData.brightness == Brightness.dark;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  /// Load saved theme preference
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            _themeType = ThemeType.light;
            _themeData = lightTheme;
            break;
          case 'dark':
            _themeType = ThemeType.dark;
            _themeData = darkTheme;
            break;
          case 'system':
          default:
            _themeType = ThemeType.system;
            _setSystemTheme();
            break;
        }
      } else {
        _setSystemTheme();
      }
      
      notifyListeners();
    } catch (e) {
      // Default to light theme on error
      _themeData = lightTheme;
    }
  }
  
  /// Set theme based on system preference
  void _setSystemTheme() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _themeData = brightness == Brightness.dark ? darkTheme : lightTheme;
  }
  
  /// Update system theme when platform brightness changes
  void updateSystemTheme(Brightness brightness) {
    if (_themeType == ThemeType.system) {
      _themeData = brightness == Brightness.dark ? darkTheme : lightTheme;
      notifyListeners();
    }
  }
  
  /// Set specific theme
  Future<void> setTheme(ThemeType type) async {
    _themeType = type;
    
    switch (type) {
      case ThemeType.light:
        _themeData = lightTheme;
        break;
      case ThemeType.dark:
        _themeData = darkTheme;
        break;
      case ThemeType.system:
        _setSystemTheme();
        break;
    }
    
    // Save preference
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, type.name);
    } catch (e) {
      // Ignore save errors
    }
    
    notifyListeners();
  }
  
  /// Toggle between light and dark
  Future<void> toggleTheme() async {
    if (_themeData.brightness == Brightness.light) {
      await setTheme(ThemeType.dark);
    } else {
      await setTheme(ThemeType.light);
    }
  }
}
