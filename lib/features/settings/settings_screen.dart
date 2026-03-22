// lib/features/settings/settings_screen.dart

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkNotificationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check permission when user returns from system settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission();
    }
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() =>
          _notificationsEnabled = status == PermissionStatus.granted);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (mounted) {
        setState(() =>
            _notificationsEnabled =
                status == PermissionStatus.granted);
        if (status == PermissionStatus.permanentlyDenied) {
          _showOpenSettingsDialog();
        }
      }
    } else {
      _showOpenSettingsDialog();
    }
  }

  void _showOpenSettingsDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Text(
          'To change notification permissions, '
          'please update them in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppSettings.openAppSettings(
                  type: AppSettingsType.notification);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Notifications ──────────────────────────────
          _SectionHeader(label: 'Notifications'),

          _SettingsTile(
            isDark: isDark,
            icon: _notificationsEnabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
            iconColor: _notificationsEnabled
                ? AppColors.primary
                : AppColors.textSecondary,
            title: 'Push Notifications',
            subtitle: _notificationsEnabled
                ? 'Booking updates enabled'
                : 'Tap to enable notifications',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
            ),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ── Appearance ─────────────────────────────────
          _SectionHeader(label: 'Appearance'),

          _SettingsTile(
            isDark: isDark,
            icon: isDark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            iconColor:
                isDark ? const Color(0xFF9C84FC) : AppColors.accent,
            title: 'Dark Mode',
            subtitle:
                isDark ? 'Dark theme is on' : 'Light theme is on',
            trailing: Switch(
              value: isDark,
              onChanged: (_) =>
                  context.read<ThemeProvider>().toggleTheme(),
            ),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ── About ──────────────────────────────────────
          _SectionHeader(label: 'About'),

          _SettingsTile(
            isDark: isDark,
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.primary,
            title: 'App Version',
            subtitle: '1.0.0',
          ),

          _SettingsTile(
            isDark: isDark,
            icon: Icons.code_rounded,
            iconColor: AppColors.primary,
            title: 'Built with Flutter',
            subtitle: 'Flutter · Firebase · Node.js · MySQL',
          ),
        ],
      ),
    );
  }
}

// ── Internal widgets ──────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final String   subtitle;
  final Widget?  trailing;
  final bool     isDark;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        trailing: trailing,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}