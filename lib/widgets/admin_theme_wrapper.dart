// lib/widgets/admin_theme_wrapper.dart
// Wraps any admin screen in a forced light theme regardless of
// the user's dark mode setting.

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AdminThemeWrapper extends StatelessWidget {
  final Widget child;
  const AdminThemeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: child,
    );
  }
}