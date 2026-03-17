// lib/providers/notification_provider.dart

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../data/services/api_service.dart';
import '../core/constants/api_constants.dart';

// ── AppNotification model ─────────────────────────────────────

class AppNotification {
  final int id;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final int? bookingId;

  AppNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.bookingId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id:        j['id'] as int,
    message:   j['message'] as String,
    type:      j['type'] as String,
    isRead:    j['is_read'] == 1 || j['is_read'] == true,
    createdAt: DateTime.parse(j['created_at'] as String),
    bookingId: j['booking_id'] as int?,
  );

  AppNotification copyWithRead() => AppNotification(
    id:        id,
    message:   message,
    type:      type,
    isRead:    true,
    createdAt: createdAt,
    bookingId: bookingId,
  );
}

// ── NotificationProvider ──────────────────────────────────────

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<AppNotification> _notifications = [];
  int     _unreadCount = 0;
  bool    _isLoading   = false;
  String? _error;

  // FCM foreground listener — kept so we can cancel it on dispose
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  List<AppNotification> get notifications => _notifications;
  int     get unreadCount => _unreadCount;
  bool    get isLoading   => _isLoading;
  String? get error       => _error;

  // ── Start listening for foreground FCM messages ────────────
  //
  // Call this once after the user logs in (from AuthProvider or
  // wherever you call fetchNotifications for the first time).
  // When a push arrives while the app is open, we immediately
  // re-fetch from the backend so the new notification appears
  // without the user having to pull-to-refresh.

  void startListening() {
    // Avoid duplicate subscriptions
    _fcmSubscription?.cancel();

    _fcmSubscription = FirebaseMessaging.onMessage.listen((message) {
      debugPrint('📩 FCM foreground message received — refreshing notifications');
      fetchNotifications();
    });
  }

  void stopListening() {
    _fcmSubscription?.cancel();
    _fcmSubscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  // ── Fetch ──────────────────────────────────────────────────

  Future<void> fetchNotifications() async {
    await Future.microtask(() {
      _isLoading = true;
      _error     = null;
      notifyListeners();
    });

    try {
      final res  = await _apiService.get(ApiConstants.notifications);
      final data = res.data['data'];
      _notifications = (data['notifications'] as List)
          .map((j) => AppNotification.fromJson(j))
          .toList();
      _unreadCount = data['unread_count'] as int? ?? 0;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Mark single as read ────────────────────────────────────

  Future<bool> markAsRead(int id) async {
    try {
      await _apiService.put(ApiConstants.markNotificationRead(id));
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1 && !_notifications[idx].isRead) {
        _notifications[idx] = _notifications[idx].copyWithRead();
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Mark all as read ───────────────────────────────────────

  Future<bool> markAllAsRead() async {
    try {
      await _apiService.put(ApiConstants.markAllNotificationsRead);
      _notifications = _notifications
          .map((n) => n.isRead ? n : n.copyWithRead())
          .toList();
      _unreadCount = 0;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}