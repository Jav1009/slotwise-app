// lib/core/utils/snackbar_utils.dart
// Centralised SnackBar helpers so every screen shows
// consistent success / error / info feedback.

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SnackbarUtils {
  /// Shows a green success snackbar
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.success, Icons.check_circle_outline);
  }

  /// Shows a red error snackbar
  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.error, Icons.error_outline);
  }

  /// Shows a blue info snackbar
  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppColors.info, Icons.info_outline);
  }

  // ── Internal builder ──────────────────────────────────────────
  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    // Remove any existing snackbar before showing a new one
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}