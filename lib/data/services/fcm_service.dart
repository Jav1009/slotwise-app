// lib/data/services/fcm_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:slotwise/data/services/storage_service.dart';
import 'package:slotwise/main.dart'; // for navigatorKey
import 'package:slotwise/providers/booking_provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM: ${message.messageId}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId   = 'booking_channel';
  static const _channelName = 'Booking Notifications';
  static const _channelDesc = 'Notifications for booking events';

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // ── Local notifications setup ──────────────────────────
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        debugPrint('Local notification tapped: ${r.payload}');
        _navigateFromPayload(r.payload);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );

    // ── Foreground FCM: show local notification ────────────
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n != null) {
        showLocalNotification(
          id: msg.hashCode,
          title: n.title ?? 'New Notification',
          body:  n.body  ?? '',
          payload: msg.data['booking_id'],
        );
      }
    });

    // ── Background → foreground (app was running) ──────────
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('Push tapped (background): ${msg.data}');
      _navigateFromMessage(msg);
    });

    // ── Terminated → opened (app was killed) ──────────────
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('Push tapped (terminated): ${initial.data}');
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateFromMessage(initial);
      });
    }
  }

  // ── Navigation helpers ─────────────────────────────────────

  /// Determine the user's role from secure storage, then route accordingly.
  Future<void> _navigateFromMessage(RemoteMessage msg) async {
    final type      = msg.data['type'] as String?;
    final bookingId = int.tryParse(msg.data['booking_id'] ?? '');
    final status    = msg.data['status'] as String?;

    if (bookingId == null) return;

    final role = await StorageService.getUserRole();

    if (role == 'admin' && type == 'new_booking') {
      _pushAdminBookings(bookingId);
    } else {
      // Cancelled/completed bookings land on Past tab (index 1),
      // everything else (confirmed, pending) on Upcoming (index 0).
      final tabIndex = (status == 'cancelled' || status == 'completed') ? 1 : 0;
      await _pushUserBookings(tabIndex);
    }
  }

  /// Navigate from a local-notification tap (payload = booking_id string).
  Future<void> _navigateFromPayload(String? payload) async {
    final bookingId = int.tryParse(payload ?? '');
    if (bookingId == null) return;

    final role = await StorageService.getUserRole();

    if (role == 'admin') {
      _pushAdminBookings(bookingId);
    } else {
      // No status in a local-notification payload — default to Upcoming.
      await _pushUserBookings(0);
    }
  }

  // ── Concrete push helpers ──────────────────────────────────

  void _pushAdminBookings(int bookingId) {
    navigatorKey.currentState?.pushNamed(
      '/admin/bookings',
      arguments: bookingId,
    );
  }

  /// Fires a forceRefresh on BookingProvider BEFORE pushing the route so
  /// the fetch is already in-flight (or complete) by the time the screen
  /// mounts.  This prevents the user seeing a stale "pending" status when
  /// the booking has already been confirmed/cancelled by the admin.
  Future<void> _pushUserBookings(int tabIndex) async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      // forceRefresh bypasses the in-flight guard so we always get fresh
      // data on a notification tap, even if a fetch is already running.
      context.read<BookingProvider>().fetchMyBookings(forceRefresh: true);
    }

    navigatorKey.currentState?.pushNamed(
      '/bookings',
      arguments: tabIndex,
    );
  }

  // ── Public helpers ─────────────────────────────────────────

  Future<void> showLocalNotification({
    required int    id,
    required String title,
    required String body,
    String?         payload,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority:   Priority.high,
          showWhen:   true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM token acquired');
      return token;
    } catch (e) {
      debugPrint('FCM getToken error: $e');
      return null;
    }
  }

  Future<void> saveTokenToBackend(void Function(String) onToken) async {
    final token = await getToken();
    if (token != null) onToken(token);
    _messaging.onTokenRefresh.listen(onToken);
  }
}