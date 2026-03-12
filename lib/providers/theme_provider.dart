// lib/core/theme/theme_provider.dart
//
// Manages which theme palette + brightness the app is using.
// Persisted to SharedPreferences so the user's choice survives restarts.
//
// HOW TO USE IN WIDGETS:
//   // Read current theme
//   final tp = context.watch<ThemeProvider>();
//   tp.palette      → SlotWiseTheme.oceanDepth
//   tp.isDark       → true / false
//   tp.currentThemeData  → the ThemeData to pass to MaterialApp
//
//   // Switch theme
//   context.read<ThemeProvider>().setPalette(SlotWiseTheme.emeraldMint);
//   context.read<ThemeProvider>().toggleDark();
//
// HOW TO APPLY PER-ROLE (optional, currently not enforced):
//   In main.dart after session restore, call:
//     if (auth.isAdmin)  themeProvider.setPalette(SlotWiseTheme.midnightSky);
//     else if (auth.isStaff) themeProvider.setPalette(SlotWiseTheme.emeraldMint);
//     else themeProvider.setPalette(SlotWiseTheme.oceanDepth);
//   This gives each role a default palette that users can later override in settings.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  SlotWiseTheme _palette = SlotWiseTheme.oceanDepth;
  bool _isDark = false;

  SlotWiseTheme get palette  => _palette;
  bool          get isDark   => _isDark;

  ThemeData get currentThemeData =>
      _isDark ? AppTheme.dark(_palette) : AppTheme.light(_palette);

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  // Human-readable name for Settings UI
  String get paletteName {
    switch (_palette) {
      case SlotWiseTheme.oceanDepth:  return 'Ocean Depth';
      case SlotWiseTheme.emeraldMint: return 'Emerald Mint';
      case SlotWiseTheme.midnightSky: return 'Midnight Sky';
    }
  }

  ThemeProvider() { _load(); }

  // ── Load from storage ─────────────────────────────────────
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final paletteIndex = prefs.getInt('sw_theme_palette') ?? 0;
    _isDark   = prefs.getBool('sw_theme_dark') ?? false;
    _palette  = SlotWiseTheme.values[paletteIndex.clamp(0, SlotWiseTheme.values.length - 1)];
    notifyListeners();
  }

  // ── Save to storage ───────────────────────────────────────
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sw_theme_palette', _palette.index);
    await prefs.setBool('sw_theme_dark',   _isDark);
  }

  // ── Public API ────────────────────────────────────────────
  void setPalette(SlotWiseTheme palette) {
    if (_palette == palette) return;
    _palette = palette;
    notifyListeners();
    _save();
  }

  void setDark(bool value) {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    _save();
  }

  void toggleDark() => setDark(!_isDark);

  /// Apply a default palette for a given role.
  /// Called after login / session restore — user can still override in settings.
  void applyRoleDefault(String role) {
    switch (role) {
      case 'admin':
        setPalette(SlotWiseTheme.midnightSky);
        break;
      case 'staff':
        setPalette(SlotWiseTheme.emeraldMint);
        break;
      default: // customer
        setPalette(SlotWiseTheme.oceanDepth);
        break;
    }
  }

  // Convenience — light ThemeData for a given palette (for previews)
  static ThemeData previewLight(SlotWiseTheme p) => AppTheme.light(p);
  static ThemeData previewDark(SlotWiseTheme p)  => AppTheme.dark(p);
}