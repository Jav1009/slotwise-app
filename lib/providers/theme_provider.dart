// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const _key = 'is_dark_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode  => _themeMode;
  bool      get isDarkMode => _themeMode == ThemeMode.dark;

  /// Call once on app start (in main.dart before runApp, or in MyApp.initState)
  Future<void> loadFromPrefs() async {
    final prefs   = await SharedPreferences.getInstance();
    final isDark  = prefs.getBool(_key) ?? false;
    _themeMode    = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isDarkMode);
  }
}