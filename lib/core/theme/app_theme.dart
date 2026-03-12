// lib/core/theme/app_theme.dart
//
// SlotWise Theme System — 3 colour palettes × 2 modes (light + dark) = 6 themes
//
// PALETTE SOURCES (from design files):
//   Theme A — Ocean Depth (vol1 Design 1)
//              Primary: #1A5276 deep navy blue  Accent: #2E86C1 / #5DADE2
//              → Familiar, brand-aligned, trustworthy
//
//   Theme B — Emerald Mint (vol1 Design 7  +  vol2 Design 1 / 4 green)
//              Primary: #0D5C3A deep forest green  Accent: #4ADE80 / #A8D5A2
//              → Fresh, clean, health-forward (Matcha Zen also used here)
//
//   Theme C — Midnight Sky (vol2 Design 3 — deep space blue-purple +
//                            Carbon Chrome accent #818CF8 indigo)
//              Primary: #253885 deep space blue  Accent: #7C9BFF / #818CF8
//              → Modern, tech, premium
//
// HOW TO ADD A NEW THEME:
//   1. Add an entry to SlotWiseTheme enum below
//   2. Add _seed() / _seeds() colors for it
//   3. Add a case in AppTheme.light() and AppTheme.dark()
//
// HOW TO APPLY PER-ROLE:
//   In main.dart's MaterialApp.theme, pass:
//     ThemeProvider.themeData(context)
//   The ThemeProvider reads the saved theme preference.
//   You can also force a theme per role in the provider logic.

import 'package:flutter/material.dart';

// ─── Palette enum ─────────────────────────────────────────────────────────────
enum SlotWiseTheme {
  oceanDepth,   // Theme A — blue (current brand)
  emeraldMint,  // Theme B — green
  midnightSky,  // Theme C — deep blue-indigo
}

// ─── Colour tokens for each palette ──────────────────────────────────────────
class _Palette {
  final Color primary;
  final Color primaryDark;     // darker shade — headers, appbars in dark mode
  final Color accent;          // secondary/highlight
  final Color accentSoft;      // light tint for chips, badges
  final Color surface;         // card / tile background (light)
  final Color surfaceDark;     // card / tile background (dark mode)
  final Color background;      // page bg (light)
  final Color backgroundDark;  // page bg (dark)
  final Color textOn;          // text on primary-coloured surface
  final Color navActive;       // bottom-nav active icon/label

  const _Palette({
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.accentSoft,
    required this.surface,
    required this.surfaceDark,
    required this.background,
    required this.backgroundDark,
    required this.textOn,
    required this.navActive,
  });
}

const _palettes = <SlotWiseTheme, _Palette>{
  // ── A: Ocean Depth ────────────────────────────────────────
  SlotWiseTheme.oceanDepth: _Palette(
    primary:        Color(0xFF1A5276),
    primaryDark:    Color(0xFF0B1929),
    accent:         Color(0xFF2E86C1),
    accentSoft:     Color(0xFFD6EAF8),
    surface:        Color(0xFFFFFFFF),
    surfaceDark:    Color(0xFF1A2E42),
    background:     Color(0xFFF4F8FB),
    backgroundDark: Color(0xFF0B1929),
    textOn:         Color(0xFFFFFFFF),
    navActive:      Color(0xFF2E86C1),
  ),

  // ── B: Emerald Mint ───────────────────────────────────────
  SlotWiseTheme.emeraldMint: _Palette(
    primary:        Color(0xFF0D5C3A),
    primaryDark:    Color(0xFF062418),
    accent:         Color(0xFF4ADE80),
    accentSoft:     Color(0xFFD4EDDA),
    surface:        Color(0xFFFFFFFF),
    surfaceDark:    Color(0xFF0F2D1E),
    background:     Color(0xFFF2F9F6),
    backgroundDark: Color(0xFF071A10),
    textOn:         Color(0xFFFFFFFF),
    navActive:      Color(0xFF2D5A27),
  ),

  // ── C: Midnight Sky ───────────────────────────────────────
  SlotWiseTheme.midnightSky: _Palette(
    primary:        Color(0xFF253885),
    primaryDark:    Color(0xFF080C1A),
    accent:         Color(0xFF7C9BFF),
    accentSoft:     Color(0xFFE8EDFF),
    surface:        Color(0xFFFFFFFF),
    surfaceDark:    Color(0xFF111830),
    background:     Color(0xFFF0F3FF),
    backgroundDark: Color(0xFF080C1A),
    textOn:         Color(0xFFFFFFFF),
    navActive:      Color(0xFF7C9BFF),
  ),
};

// ─── Theme builder ────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  // Shared semantic colours (same across all themes)
  static const Color success   = Color(0xFF1E8449);
  static const Color danger    = Color(0xFFC0392B);
  static const Color warning   = Color(0xFFD35400);
  static const Color pending   = Color(0xFFFFA726);
  static const Color confirmed = Color(0xFF42A5F5);
  static const Color completed = Color(0xFF66BB6A);
  static const Color cancelled = Color(0xFFEF5350);

  static Color statusColor(String status) {
    switch (status) {
      case 'pending':   return pending;
      case 'confirmed': return confirmed;
      case 'completed': return completed;
      case 'cancelled': return cancelled;
      default:          return const Color(0xFF666666);
    }
  }

  // ── LIGHT theme ───────────────────────────────────────────
  static ThemeData light(SlotWiseTheme palette) {
    final p = _palettes[palette]!;
    final cs = ColorScheme.fromSeed(
      seedColor: p.primary,
      primary: p.primary,
      secondary: p.accent,
      surface: p.surface,
      background: p.background,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: p.background,
      fontFamily: 'PlusJakartaSans',

      appBarTheme: AppBarTheme(
        backgroundColor: p.primary,
        foregroundColor: p.textOn,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: p.textOn,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: p.textOn),
      ),

      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.primary.withOpacity(0.08)),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.textOn,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(color: p.primary),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.primary),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: p.primary.withOpacity(0.7)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.accentSoft,
        selectedColor: p.primary,
        labelStyle: TextStyle(fontSize: 12, color: p.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: p.primary.withOpacity(0.2)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? p.primary : Colors.white),
        trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected)
                ? p.primary.withOpacity(0.4)
                : Colors.grey.withOpacity(0.3)),
      ),

      dividerTheme: DividerThemeData(
        color: p.primary.withOpacity(0.08),
        thickness: 1,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.navActive,
        unselectedItemColor: const Color(0xFF999999),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),

      extensions: [SlotWiseColors.from(p, Brightness.light)],
    );
  }

  // ── DARK theme ────────────────────────────────────────────
  static ThemeData dark(SlotWiseTheme palette) {
    final p = _palettes[palette]!;
    final cs = ColorScheme.fromSeed(
      seedColor: p.primary,
      primary: p.accent,
      secondary: p.accent,
      surface: p.surfaceDark,
      background: p.backgroundDark,
      brightness: Brightness.dark,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: p.backgroundDark,
      fontFamily: 'PlusJakartaSans',

      appBarTheme: AppBarTheme(
        backgroundColor: p.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      cardTheme: CardThemeData(
        color: p.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.accent.withOpacity(0.12)),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.primaryDark,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.accent,
          side: BorderSide(color: p.accent),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.accent),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.accent.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.accent.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: p.accent.withOpacity(0.7)),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.accent.withOpacity(0.12),
        selectedColor: p.accent,
        labelStyle: TextStyle(fontSize: 12, color: p.accent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: p.accent.withOpacity(0.2)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? p.accent : Colors.grey),
        trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected)
                ? p.accent.withOpacity(0.4)
                : Colors.white12),
      ),

      dividerTheme: DividerThemeData(
        color: p.accent.withOpacity(0.1),
        thickness: 1,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.primaryDark,
        selectedItemColor: p.accent,
        unselectedItemColor: Colors.white30,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),

      extensions: [SlotWiseColors.from(p, Brightness.dark)],
    );
  }
}

// ─── ThemeExtension — gives access to brand tokens anywhere via Theme.of(ctx) ─
// Usage:  Theme.of(context).extension<SlotWiseColors>()!.primaryColor
@immutable
class SlotWiseColors extends ThemeExtension<SlotWiseColors> {
  final Color primaryColor;
  final Color accentColor;
  final Color accentSoft;
  final Color headerBg;
  final Color cardBg;
  final Color navActiveTint;
  final bool  isDark;

  const SlotWiseColors({
    required this.primaryColor,
    required this.accentColor,
    required this.accentSoft,
    required this.headerBg,
    required this.cardBg,
    required this.navActiveTint,
    required this.isDark,
  });

  factory SlotWiseColors.from(_Palette p, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return SlotWiseColors(
      primaryColor:  dark ? p.accent    : p.primary,
      accentColor:   dark ? p.accent    : p.accent,
      accentSoft:    dark ? p.accent.withOpacity(0.15) : p.accentSoft,
      headerBg:      dark ? p.primaryDark : p.primary,
      cardBg:        dark ? p.surfaceDark : p.surface,
      navActiveTint: p.navActive,
      isDark:        dark,
    );
  }

  /// Ocean Depth light-mode fallback — used when ThemeExtension isn't in the
  /// widget tree yet (e.g. in AppColors.of() before MaterialApp builds).
  /// This avoids crossing the private _Palette type across files.
  factory SlotWiseColors.fallback() => const SlotWiseColors(
    primaryColor:  Color(0xFF1A5276),
    accentColor:   Color(0xFF2E86C1),
    accentSoft:    Color(0xFFD6EAF8),
    headerBg:      Color(0xFF1A5276),
    cardBg:        Color(0xFFFFFFFF),
    navActiveTint: Color(0xFF2E86C1),
    isDark:        false,
  );

  @override
  SlotWiseColors copyWith({
    Color? primaryColor,
    Color? accentColor,
    Color? accentSoft,
    Color? headerBg,
    Color? cardBg,
    Color? navActiveTint,
    bool?  isDark,
  }) => SlotWiseColors(
    primaryColor:  primaryColor  ?? this.primaryColor,
    accentColor:   accentColor   ?? this.accentColor,
    accentSoft:    accentSoft    ?? this.accentSoft,
    headerBg:      headerBg      ?? this.headerBg,
    cardBg:        cardBg        ?? this.cardBg,
    navActiveTint: navActiveTint ?? this.navActiveTint,
    isDark:        isDark        ?? this.isDark,
  );

  @override
  SlotWiseColors lerp(ThemeExtension<SlotWiseColors>? other, double t) {
    if (other is! SlotWiseColors) return this;
    return SlotWiseColors(
      primaryColor:  Color.lerp(primaryColor,  other.primaryColor,  t)!,
      accentColor:   Color.lerp(accentColor,   other.accentColor,   t)!,
      accentSoft:    Color.lerp(accentSoft,    other.accentSoft,    t)!,
      headerBg:      Color.lerp(headerBg,      other.headerBg,      t)!,
      cardBg:        Color.lerp(cardBg,        other.cardBg,        t)!,
      navActiveTint: Color.lerp(navActiveTint, other.navActiveTint, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}