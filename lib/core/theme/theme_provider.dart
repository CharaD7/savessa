import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Theme mode key for shared preferences
  static const String _themeKey = 'theme_mode';
  
  // Default theme mode
  ThemeMode _themeMode = ThemeMode.system;
  
  // Getter for current theme mode
  ThemeMode get themeMode => _themeMode;
  
  // Constructor - loads saved theme mode
  ThemeProvider() {
    _loadThemeMode();
  }
  
  // Load theme mode from shared preferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeMode = prefs.getString(_themeKey);
      
      if (savedThemeMode != null) {
        _themeMode = _getThemeModeFromString(savedThemeMode);
        notifyListeners();
      }
    } catch (e) {
      // If there's an error, fallback to system theme
      _themeMode = ThemeMode.system;
    }
  }
  
  // Save theme mode to shared preferences
  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.toString());
    } catch (e) {
      // Handle error silently
      debugPrint('Error saving theme mode: $e');
    }
  }
  
  // Convert string to ThemeMode
  ThemeMode _getThemeModeFromString(String themeModeString) {
    switch (themeModeString) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      case 'ThemeMode.system':
      default:
        return ThemeMode.system;
    }
  }
  
  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    await _saveThemeMode(mode);
  }
  
  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }
  
  // Set to system theme
  Future<void> useSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }
  
  // Check if current theme is dark
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  // Check if current theme is light
  bool get isLightMode => _themeMode == ThemeMode.light;
  
  // Check if current theme is system
  bool get isSystemMode => _themeMode == ThemeMode.system;
}