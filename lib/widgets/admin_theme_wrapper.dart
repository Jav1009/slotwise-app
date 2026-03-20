// lib/widgets/admin_theme_wrapper.dart
// Wraps any admin screen in a forced light theme regardless of the user's dark mode setting.
// Adds helper functions for sheets and dialogs

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

// ── Widget wrapper (existing) ─────────────────────────────────

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

// ── Bottom sheet helper ───────────────────────────────────────
// Use this instead of showModalBottomSheet() in all admin screens.
// It wraps the builder content in a forced light Theme so forms
// and menus inside the sheet are never affected by dark mode.

Future<T?> showAdminBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    enableDrag: false, // prevents Android gesture nav stealing the drag
    builder: (ctx) => Theme(
      data: AppTheme.lightTheme,
      child: builder(ctx),
    ),
  );
}

// ── Dialog helper ─────────────────────────────────────────────
// Use this instead of showDialog() in all admin screens.

Future<T?> showAdminDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => Theme(
      data: AppTheme.lightTheme,
      child: builder(ctx),
    ),
  );
}