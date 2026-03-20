// lib/data/services/fcm_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:slotwise/features/admin/manage_bookings_screen.dart';
import 'package:slotwise/main.dart'; // for navigatorKey

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
        // Local notifications carry the booking_id as the payload string
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
          // Pass booking_id as payload so tapping the local
          // notification also navigates correctly
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
      // Delay slightly so the navigator is mounted before we push
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateFromMessage(initial);
      });
    }
  }

  // ── Navigation helpers ─────────────────────────────────────

  /// Navigate based on a full FCM RemoteMessage (has typed data map).
  void _navigateFromMessage(RemoteMessage msg) {
    final type      = msg.data['type'] as String?;
    final bookingId = int.tryParse(msg.data['booking_id'] ?? '');

    if (type == 'new_booking' && bookingId != null) {
      _pushManageBookings(bookingId);
    }
  }

  /// Navigate based on a raw payload string (from local notification tap).
  void _navigateFromPayload(String? payload) {
    final bookingId = int.tryParse(payload ?? '');
    if (bookingId != null) {
      _pushManageBookings(bookingId);
    }
  }

  /// Actually push ManageBookingsScreen via the global navigator key.
  void _pushManageBookings(int bookingId) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ManageBookingsScreen(highlightBookingId: bookingId),
      ),
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
      payload: payload,  // booking_id string
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