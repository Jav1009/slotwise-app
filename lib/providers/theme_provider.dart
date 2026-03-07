import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isDarkMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(AppConstants.themeKey);
      
      if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
        _isDarkMode = true;
      } else {
        _themeMode = ThemeMode.light;
        _isDarkMode = false;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
      // Default to light theme if error occurs
      _themeMode = ThemeMode.light;
      _isDarkMode = false;
    }
  }

  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      _themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.themeKey, 
        _isDarkMode ? 'dark' : 'light'
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling theme: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      _themeMode = mode;
      _isDarkMode = mode == ThemeMode.dark;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.themeKey, 
        _isDarkMode ? 'dark' : 'light'
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting theme mode: $e');
    }
  }

  void setLightMode() {
    if (_isDarkMode) {
      toggleTheme();
    }
  }

  void setDarkMode() {
    if (!_isDarkMode) {
      toggleTheme();
    }
  }

  Color get primaryColor => const Color(0xFF2A4B7C);
  
  Color get secondaryColor => const Color(0xFF4A90E2);
  
  Color get accentColor => const Color(0xFF50C878);
  
  Color get errorColor => const Color(0xFFE74C3C);
  
  Color get warningColor => const Color(0xFFF39C12);
  
  Color get successColor => const Color(0xFF2ECC71);
  
  Color get backgroundColor => _isDarkMode ? const Color(0xFF121212) : Colors.white;
  
  Color get surfaceColor => _isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50]!;
  
  Color get textColor => _isDarkMode ? Colors.white : Colors.black87;
  
  Color get subtitleColor => _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
  
  Color get dividerColor => _isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
  
  Brightness get brightness => _isDarkMode ? Brightness.dark : Brightness.light;

  /// Get theme data for the current mode
  ThemeData get themeData {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  /// Light theme definition
  ThemeData get _lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2A4B7C),
        secondary: Color(0xFF4A90E2),
        error: Color(0xFFE74C3C),
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF2A4B7C),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: Color(0xFF2A4B7C)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: Colors.grey[600]),
        hintStyle: TextStyle(color: Colors.grey[400]),
        errorStyle: const TextStyle(color: Color(0xFFE74C3C)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A4B7C), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[100],
        selectedColor: primaryColor,
        labelStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        contentTextStyle: const TextStyle(fontSize: 16, color: Colors.black54),
        backgroundColor: Colors.white,
      ),
      dividerColor: Colors.grey[300],
      scaffoldBackgroundColor: Colors.white,
    );
  }

  /// Dark theme definition
  ThemeData get _darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2A4B7C),
        secondary: Color(0xFF4A90E2),
        error: Color(0xFFE74C3C),
        surface: Color(0xFF1E1E1E),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: Color(0xFF2A4B7C)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[800],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: Colors.grey[400]),
        hintStyle: TextStyle(color: Colors.grey[500]),
        errorStyle: const TextStyle(color: Color(0xFFE74C3C)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A4B7C), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        color: Colors.grey[850],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.grey[900],
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        contentTextStyle: const TextStyle(fontSize: 16, color: Colors.white70),
      ),
      dividerColor: Colors.grey[800],
      scaffoldBackgroundColor: const Color(0xFF121212),
    );
  }

  /// Get text style for headings
  TextStyle headline1({Color? color}) {
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: color ?? textColor,
    );
  }

  TextStyle headline2({Color? color}) {
    return TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: color ?? textColor,
    );
  }

  TextStyle headline3({Color? color}) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: color ?? textColor,
    );
  }

  TextStyle headline4({Color? color}) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: color ?? textColor,
    );
  }

  TextStyle bodyText1({Color? color}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: color ?? textColor,
    );
  }

  TextStyle bodyText2({Color? color}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: color ?? subtitleColor,
    );
  }

  TextStyle caption({Color? color}) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: color ?? subtitleColor,
    );
  }

  TextStyle buttonText({Color? color}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color ?? Colors.white,
    );
  }
}

/// Extension for easier theme access in widgets
extension ThemeExtension on BuildContext {
  ThemeProvider get themeProvider => Provider.of<ThemeProvider>(this, listen: true);
  
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  Color get primaryColor => Theme.of(this).primaryColor;
  
  Color get scaffoldBackgroundColor => Theme.of(this).scaffoldBackgroundColor;
  
  Color get cardColor => Theme.of(this).cardTheme.color ?? 
      (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white);
  
  Color get dividerColor => Theme.of(this).dividerColor;
  
  TextStyle? get headline1 => Theme.of(this).textTheme.headline1;
  
  TextStyle? get headline2 => Theme.of(this).textTheme.headline2;
  
  TextStyle? get headline3 => Theme.of(this).textTheme.headline3;
  
  TextStyle? get headline4 => Theme.of(this).textTheme.headline4;
  
  TextStyle? get bodyText1 => Theme.of(this).textTheme.bodyText1;
  
  TextStyle? get bodyText2 => Theme.of(this).textTheme.bodyText2;
  
  TextStyle? get caption => Theme.of(this).textTheme.caption;
}