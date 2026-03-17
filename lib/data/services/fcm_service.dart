import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

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
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission from the user
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM auth status: ${settings.authorizationStatus}');

    // ── Local notifications setup ──────────────────────────────
    // Use the unified initialize() call — works for both Android and iOS
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
        debugPrint('Notification tapped: ${r.payload}');
      },
    );

    // Create the Android notification channel
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

    // ── FCM message listeners ──────────────────────────────────

    // Foreground messages — show a local notification
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n != null) {
        showLocalNotification(
          id: msg.hashCode,
          title: n.title ?? 'New Notification',
          body: n.body ?? '',
          payload: msg.data['type'],
        );
      }
    });

    // App opened by tapping a background notification
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('Opened from background: type=${msg.data['type']}');
    });

    // App opened from a terminated state
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('Opened from terminated: type=${initial.data['type']}');
    }
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
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
          priority: Priority.high,
          showWhen: true,
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

  /// Calls [onToken] immediately with the current token,
  /// then again whenever the token refreshes.
  Future<void> saveTokenToBackend(void Function(String) onToken) async {
    final token = await getToken();
    if (token != null) onToken(token);
    _messaging.onTokenRefresh.listen(onToken);
  }
}