// core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color primary    = Color(0xFF1A5276); // Deep blue
  static const Color accent     = Color(0xFFE87722); // Orange
  static const Color success    = Color(0xFF1E8449); // Green
  static const Color danger     = Color(0xFFC0392B); // Red
  static const Color warning    = Color(0xFFD35400); // Amber-orange

  // Booking status colours
  static const Color pending    = Color(0xFFFFA726);
  static const Color confirmed  = Color(0xFF42A5F5);
  static const Color completed  = Color(0xFF66BB6A);
  static const Color cancelled  = Color(0xFFEF5350);

  // Backgrounds
  static const Color lightBlue  = Color(0xFFD6EAF8);
  static const Color lightGray  = Color(0xFFF4F6F7);
  static const Color cardBg     = Color(0xFFFFFFFF);

  // Text
  static const Color textDark   = Color(0xFF333333);
  static const Color textMid    = Color(0xFF666666);
  static const Color textLight  = Color(0xFF999999);

  static Color statusColor(String status) {
    switch (status) {
      case 'pending':   return pending;
      case 'confirmed': return confirmed;
      case 'completed': return completed;
      case 'cancelled': return cancelled;
      default:          return textMid;
    }
  }
}