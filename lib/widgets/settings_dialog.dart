// lib/widgets/settings_dialog.dart
//
// Settings bottom sheet.
// Sections:
//   • Appearance — dark mode toggle + 3 palette swatches
//   • Notifications  — push + reminder toggles (NotificationPreferencesWidget)
//   • Account     — edit profile, change password
//   • About       — version info
//
// Usage:
//   SettingsDialog.show(context);

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slot_wise_booking/providers/notificationPreferencesProvider.dart';
import 'package:slot_wise_booking/providers/theme_provider.dart';
import 'package:slot_wise_booking/widgets/notification_preferences_widget.dart';
import '../core/theme/app_theme.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<ThemeProvider>()),
          ChangeNotifierProvider.value(
            value: context.read<NotificationPreferencesProvider>(),
          ),
        ],
        child: const SettingsDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<SlotWiseColors>()!;
    final tp = context.watch<ThemeProvider>();

    return Container(
      // Allow scrolling when keyboard is open / content is long
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // padding: EdgeInsets.fromLTRB(
      //     20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, MediaQuery.of(context).padding.bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: c.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
              
                  // ── Appearance ──────────────────────────────────────
                  _SectionTitle('Appearance'),
                  const SizedBox(height: 12),
              
                  // Dark mode toggle
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: tp.isDark ? 'On' : 'Off',
                    trailing: Switch(
                      value: tp.isDark,
                      onChanged: (_) => context.read<ThemeProvider>().toggleDark(),
                      activeColor: c.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
              
                  // Theme palette
                  Text(
                    'Colour Theme',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ThemePaletteSelector(tp: tp),
              
                  const SizedBox(height: 24),
                  Divider(color: c.primaryColor.withOpacity(0.08)),
                  const SizedBox(height: 12),
              
                  // ── Notifications ────────────────────────────
                  _SectionTitle('Notifications & Reminders'),
                  const SizedBox(height: 12),
 
                  // Uses the standalone widget in compact mode
                  // (card mode is for profile pages; compact fits settings list)
                  const NotificationPreferencesWidget(compact: true),
 
                  const SizedBox(height: 24),
                  Divider(color: c.primaryColor.withOpacity(0.08)),
                  const SizedBox(height: 12),
 
                  // ── Account ─────────────────────────────────────────
                  _SectionTitle('Account'),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.person_outlined,
                    title: 'Edit Profile',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to edit profile
                      Navigator.pushNamed(context, '/edit-profile');
                    },
                  ),
              
                  const SizedBox(height: 4),
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/forgot-password');
                    },
                  ),
              
                  const SizedBox(height: 24),
                  Divider(color: c.primaryColor.withOpacity(0.08)),
                  const SizedBox(height: 12),
              
                  // ── About ────────────────────────────────────────────
                  _SectionTitle('About'),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'SlotWise',
                    subtitle: 'Version 2.0.0',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: Colors.grey[400],
      textBaseline: TextBaseline.alphabetic,
    ).copyWith(inherit: true),
  );
}

// ─── Generic settings tile ────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<SlotWiseColors>()!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c.accentSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: c.primaryColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: Colors.grey[400])
              : null),
      onTap: onTap,
    );
  }
}

// ── Theme palette selector ────────────────────────────────────────────────────
class _ThemePaletteSelector extends StatelessWidget {
  final ThemeProvider tp;
  const _ThemePaletteSelector({required this.tp});

  @override
  Widget build(BuildContext context) {
    final palettes = [
      (
        theme: SlotWiseTheme.oceanDepth,
        name: 'Ocean',
        color: const Color(0xFF1A5276),
        accent: const Color(0xFF2E86C1),
      ),
      (
        theme: SlotWiseTheme.emeraldMint,
        name: 'Emerald',
        color: const Color(0xFF0D5C3A),
        accent: const Color(0xFF4ADE80),
      ),
      (
        theme: SlotWiseTheme.midnightSky,
        name: 'Midnight',
        color: const Color(0xFF253885),
        accent: const Color(0xFF7C9BFF),
      ),
    ];

    return Row(
      children: palettes.map((p) {
        final selected = tp.palette == p.theme;
        return Expanded(
          child: GestureDetector(
            onTap: () => context.read<ThemeProvider>().setPalette(p.theme),
            child: Container(
              margin: EdgeInsets.only(right: p == palettes.last ? 0 : 10),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: p.color.withOpacity(selected ? 1 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? p.color : p.color.withOpacity(0.2),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  // Mini palette swatch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: p.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: p.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : p.color,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(height: 2),
                    const Icon(Icons.check, size: 12, color: Colors.white),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
