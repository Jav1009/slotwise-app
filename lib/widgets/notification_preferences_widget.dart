// lib/widgets/notification_preferences_widget.dart
//
// Standalone, reusable notification/reminder preference widget.
// Can be embedded:
//   • In SettingsDialog (already wired in settings_dialog.dart)
//   • On ProfileScreen
//   • Anywhere you need a quick notification toggle card
//
// USAGE:
//   const NotificationPreferencesWidget()
//
//   // Compact single-row toggle (for a list):
//   const NotificationPreferencesWidget(compact: true)
//
// REQUIRES: NotificationPreferencesProvider in the widget tree.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slot_wise_booking/providers/notificationPreferencesProvider.dart';
import '../core/theme/app_theme.dart';

class NotificationPreferencesWidget extends StatelessWidget {
  /// If true, renders as a compact two-row tile list instead of a card.
  final bool compact;

  const NotificationPreferencesWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return compact
        ? _CompactView()
        : _CardView();
  }
}

// ─── Card view ────────────────────────────────────────────────────────────────
class _CardView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c    = Theme.of(context).extension<SlotWiseColors>()!;
    final pref = context.watch<NotificationPreferencesProvider>();

    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.primaryColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: c.primaryColor.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.notifications_outlined, size: 17, color: c.primaryColor),
              ),
              const SizedBox(width: 10),
              Text('Notifications & Reminders',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.primaryColor)),
              if (pref.isSyncing) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: c.primaryColor),
                ),
              ],
            ]),
          ),

          Divider(height: 1, indent: 16, endIndent: 16,
              color: c.primaryColor.withOpacity(0.06)),

          // Push notifications master toggle
          _PrefTile(
            icon: Icons.notifications_active_outlined,
            title: 'Push Notifications',
            subtitle: pref.notificationsEnabled
                ? 'You\'ll receive alerts for bookings and updates'
                : 'All push notifications are off',
            value: pref.notificationsEnabled,
            onChanged: (v) =>
                context.read<NotificationPreferencesProvider>().setNotificationsEnabled(v),
          ),

          Divider(height: 1, indent: 60, endIndent: 16,
              color: c.primaryColor.withOpacity(0.05)),

          // Reminders toggle — dimmed when notifications are off
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: pref.notificationsEnabled ? 1.0 : 0.4,
            child: _PrefTile(
              icon: Icons.alarm_outlined,
              title: 'Booking Reminders',
              subtitle: pref.effectiveRemindersEnabled
                  ? '1-hour and 24-hour alerts before appointments'
                  : pref.notificationsEnabled
                      ? 'Reminders are off'
                      : 'Enable notifications first',
              value: pref.remindersEnabled,
              onChanged: pref.notificationsEnabled
                  ? (v) => context
                      .read<NotificationPreferencesProvider>()
                      .setRemindersEnabled(v)
                  : null, // disabled when master is off
            ),
          ),

          // Helper text when both are enabled
          if (pref.effectiveRemindersEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 12,
                      color: c.primaryColor.withOpacity(0.5)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reminders are sent automatically by the server — you\'ll still receive them if the app is closed.',
                      style: TextStyle(
                          fontSize: 11,
                          color: c.primaryColor.withOpacity(0.5),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Compact view ─────────────────────────────────────────────────────────────
class _CompactView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c    = Theme.of(context).extension<SlotWiseColors>()!;
    final pref = context.watch<NotificationPreferencesProvider>();

    return Column(children: [
      _PrefTile(
        icon: Icons.notifications_active_outlined,
        title: 'Push Notifications',
        subtitle: pref.notificationsEnabled ? 'On' : 'Off',
        value: pref.notificationsEnabled,
        onChanged: (v) =>
            context.read<NotificationPreferencesProvider>().setNotificationsEnabled(v),
      ),
      const SizedBox(height: 4),
      AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: pref.notificationsEnabled ? 1.0 : 0.4,
        child: _PrefTile(
          icon: Icons.alarm_outlined,
          title: 'Booking Reminders',
          subtitle: pref.effectiveRemindersEnabled
              ? 'On (1h + 24h before)'
              : pref.notificationsEnabled ? 'Off' : 'Enable notifications first',
          value: pref.remindersEnabled,
          onChanged: pref.notificationsEnabled
              ? (v) => context
                  .read<NotificationPreferencesProvider>()
                  .setRemindersEnabled(v)
              : null,
        ),
      ),
    ]);
  }
}

// ─── Shared preference tile ───────────────────────────────────────────────────
class _PrefTile extends StatelessWidget {
  final IconData  icon;
  final String    title;
  final String    subtitle;
  final bool      value;
  final ValueChanged<bool>? onChanged;

  const _PrefTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<SlotWiseColors>()!;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: value
              ? c.accentSoft
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18,
            color: value ? c.primaryColor : Colors.grey[400]),
      ),
      title: Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: onChanged == null ? Colors.grey[400] : null)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 11,
              color: onChanged == null ? Colors.grey[300] : Colors.grey[500])),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: c.primaryColor,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}