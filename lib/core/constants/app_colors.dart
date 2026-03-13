// lib/core/constants/app_colors.dart
//
// UPDATED: Primary colours are now driven by the ThemeProvider / AppTheme.
// This file keeps backward-compatible static constants for screens that
// haven't been migrated to the new theme extension yet.
//
// PREFERRED WAY in new widgets:
//   final c = Theme.of(context).extension<SlotWiseColors>()!;
//   c.primaryColor  // adapts to selected theme + dark mode
//
// LEGACY WAY (still works, uses Ocean Depth blue):
//   AppColors.primary

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppColors {
  AppColors._();

  // Brand (Ocean Depth defaults — used by legacy screens)
  static const Color primary    = Color(0xFF1A5276);
  static const Color accent     = Color(0xFFE87722);
  static const Color success    = Color(0xFF1E8449);
  static const Color danger     = Color(0xFFC0392B);
  static const Color warning    = Color(0xFFD35400);

  // Booking status (shared across all themes)
  static const Color pending    = Color(0xFFFFA726);
  static const Color confirmed  = Color(0xFF42A5F5);
  static const Color completed  = Color(0xFF66BB6A);
  static const Color cancelled  = Color(0xFFEF5350);
  static const Color missed     = Color(0xFF9E9E9E); // grey — appointment passed

  // Backgrounds
  static const Color lightBlue  = Color(0xFFD6EAF8);
  static const Color lightGray  = Color(0xFFF4F6F7);
  static const Color cardBg     = Color(0xFFFFFFFF);

  // Text
  static const Color textDark   = Color(0xFF333333);
  static const Color textMid    = Color(0xFF666666);
  static const Color textLight  = Color(0xFF999999);

  // static Color statusColor(String status) => AppTheme.statusColor(status);
  static Color statusColor(String status) {
    switch (status) {
      case 'pending':   return pending;
      case 'confirmed': return confirmed;
      case 'completed': return completed;
      case 'cancelled': return cancelled;
      case 'missed':    return missed;
      default:          return textMid;
    }
  }
  // ── Convenience: get SlotWiseColors from context ──────────
  static SlotWiseColors of(BuildContext context) =>
      Theme.of(context).extension<SlotWiseColors>() ??
      SlotWiseColors.fallback( );
}

// // Fallback palette (Ocean Depth) used if extension isn't set
// class _FallbackPalette implements _PaletteInterface {
//   const _FallbackPalette();
//   Color get primary        => const Color(0xFF1A5276);
//   Color get primaryDark    => const Color(0xFF0B1929);
//   Color get accent         => const Color(0xFF2E86C1);
//   Color get accentSoft     => const Color(0xFFD6EAF8);
//   Color get surface        => const Color(0xFFFFFFFF);
//   Color get surfaceDark    => const Color(0xFF1A2E42);
//   Color get background     => const Color(0xFFF4F8FB);
//   Color get backgroundDark => const Color(0xFF0B1929);
//   Color get textOn         => const Color(0xFFFFFFFF);
//   Color get navActive      => const Color(0xFF2E86C1);
// }

// abstract class _PaletteInterface {
//   Color get primary;
//   Color get primaryDark;
//   Color get accent;
//   Color get accentSoft;
//   Color get surface;
//   Color get surfaceDark;
//   Color get background;
//   Color get backgroundDark;
//   Color get textOn;
//   Color get navActive;
// }