// lib/providers/notification_preferences_provider.dart
//
// Manages the user's notification & reminder preferences.
// Persisted to SharedPreferences locally for instant UI reads,
// and synced to the backend (PUT /api/notifications/preferences).
//
// USAGE:
//   // In widget tree (above MaterialApp):
//   ChangeNotifierProvider(create: (_) => NotificationPreferencesProvider()..load())
//
//   // Read:
//   final prefs = context.watch<NotificationPreferencesProvider>();
//   prefs.notificationsEnabled   → bool
//   prefs.remindersEnabled       → bool
//
//   // Write (saves locally + syncs to backend):
//   context.read<NotificationPreferencesProvider>().setNotificationsEnabled(false);

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slot_wise_booking/services/api_service.dart';
import '../core/constants/api_constants.dart';

class NotificationPreferencesProvider extends ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _remindersEnabled     = true;
  bool _isSyncing            = false;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get remindersEnabled     => _remindersEnabled;
  bool get isSyncing            => _isSyncing;

  // When notifications are off, reminders are implicitly off too
  bool get effectiveRemindersEnabled => _notificationsEnabled && _remindersEnabled;

  final _api = ApiService();

  static const _keyNotif   = 'sw_notif_enabled';
  static const _keyRemind  = 'sw_remind_enabled';

  // ── Load (call on app start / login) ──────────────────────
  Future<void> load() async {
    // 1. Load from local cache for instant display
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(_keyNotif)  ?? true;
    _remindersEnabled     = prefs.getBool(_keyRemind) ?? true;
    notifyListeners();

    // 2. Sync from backend (source of truth)
    try {
      final res = await _api.get('${ApiConstants.notifications}/preferences');
      if (res.data is Map && res.data['data'] != null) {
        final d = res.data['data'] as Map<String, dynamic>;
        _notificationsEnabled = (d['notifications_enabled'] == 1 || d['notifications_enabled'] == true);
        _remindersEnabled     = (d['reminders_enabled']     == 1 || d['reminders_enabled']     == true);
        await _saveLocal();
        notifyListeners();
      }
    } catch (_) {
      // Backend unavailable — keep local values
    }
  }

  // ── Toggle notifications (master switch) ──────────────────
  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    await _saveLocal();
    await _syncToBackend();
  }

  // ── Toggle reminders (only meaningful when notifs are on) ─
  Future<void> setRemindersEnabled(bool value) async {
    _remindersEnabled = value;
    notifyListeners();
    await _saveLocal();
    await _syncToBackend();
  }

  // ── Internal ──────────────────────────────────────────────
  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotif,  _notificationsEnabled);
    await prefs.setBool(_keyRemind, _remindersEnabled);
  }

  Future<void> _syncToBackend() async {
    _isSyncing = true; notifyListeners();
    try {
      await _api.put('${ApiConstants.notifications}/preferences', {
        'notifications_enabled': _notificationsEnabled ? 1 : 0,
        'reminders_enabled':     _remindersEnabled     ? 1 : 0,
      });
    } catch (_) {
      // Backend sync failed — local state is still saved
    } finally {
      _isSyncing = false; notifyListeners();
    }
  }
}