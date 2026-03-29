import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'jikah_theme_mode';
  
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLoaded => _isLoaded;

  ThemeService() {
    _loadTheme();
  }

  // Load saved theme from storage
  Future<void> _loadTheme() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme != null) {
        _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (e) {
      _themeMode = ThemeMode.light;
    }
    _isLoaded = true;
    notifyListeners();
  }

  // Toggle theme
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _saveTheme();
    notifyListeners();
  }

  // Set specific theme
  Future<void> setTheme(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _saveTheme();
    notifyListeners();
  }

  // Save theme to storage
  Future<void> _saveTheme() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');
    } catch (e) {
      // Handle error silently
    }
  }
}