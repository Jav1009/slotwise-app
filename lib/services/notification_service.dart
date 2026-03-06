// ════════════════════════════════════════════════════════════════════════════
// FILE 2: lib/core/services/notification_service.dart
// Handles FCM token retrieval, registration with backend, and token refresh
// ════════════════════════════════════════════════════════════════════════════


import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';    // Your existing Dio + JWT interceptor service

class NotificationService {
    static final NotificationService _instance = NotificationService._internal();
    factory NotificationService() => _instance;
    NotificationService._internal();

    final FirebaseMessaging _messaging = FirebaseMessaging.instance;
    final ApiService _api = ApiService();

    // ─────────────────────────────────────────────────────────────
    // STEP 1: Request notification permissions
    // Must be called before attempting to get the FCM token
    // iOS requires explicit permission; Android 13+ also requires it
    // ─────────────────────────────────────────────────────────────
    Future<bool> requestPermission() async {
        final settings = await _messaging.requestPermission(
            alert: true,       // Show notification alerts
            badge: true,       // Update app badge count
            sound: true,       // Play notification sound
            announcement: false,
            carPlay: false,
            criticalAlert: false,
            provisional: false,  // true = quiet notifications without explicit prompt
        );

        final granted = settings.authorizationStatus == AuthorizationStatus.authorized
                     || settings.authorizationStatus == AuthorizationStatus.provisional;

        print('🔔 Notification permission: ${settings.authorizationStatus}');
        return granted;
    }

    // ─────────────────────────────────────────────────────────────
    // STEP 2: Get FCM token and register with backend
    // Call this after successful login
    // The token identifies this specific device — backend stores it in users.fcm_token
    // ─────────────────────────────────────────────────────────────
    Future<void> registerToken() async {
        try {
            // Request permission first — getToken returns null if not granted
            final permissionGranted = await requestPermission();
            if (!permissionGranted) {
                print('⚠️  Notification permission denied. Token not registered.');
                return;
            }

            // Get the unique FCM token for this device
            final token = await _messaging.getToken();

            if (token == null) {
                print('⚠️  FCM token is null — Firebase may not be configured correctly.');
                return;
            }

            print('📱 FCM Token: ${token.substring(0, 20)}...');

            // Send the token to your backend — stored in users.fcm_token
            // await _api.put('/auth/fcm-token', data: {'fcm_token': token});
            await _api.put('/auth/fcm-token',  {'fcm_token': token});
            print('✅  FCM token registered with backend.');
        } catch (e) {
            // Token registration failure is non-fatal — app still works, just no push
            print('❌  Failed to register FCM token: $e');
        }
    }

    // ─────────────────────────────────────────────────────────────
    // STEP 3: Listen for token refresh
    // Firebase occasionally rotates FCM tokens (e.g., after app reinstall)
    // When this happens, re-register the new token with the backend
    // Call this once during app startup (in main.dart or in AuthProvider)
    // ─────────────────────────────────────────────────────────────
    void listenForTokenRefresh() {
        _messaging.onTokenRefresh.listen((newToken) async {
            print('🔄 FCM token refreshed. Re-registering with backend...');
            try {
                // await _api.put('/auth/fcm-token', data: {'fcm_token': newToken});
                await _api.put('/auth/fcm-token',  {'fcm_token': newToken});
                print('✅  Refreshed FCM token registered.');
            } catch (e) {
                print('❌  Failed to update refreshed FCM token: $e');
            }
        });
    }

    // ─────────────────────────────────────────────────────────────
    // STEP 4: Unregister token on logout
    // Deletes the token from Firebase and signals the backend to clear it
    // After this, push notifications stop for this device
    // ─────────────────────────────────────────────────────────────
    Future<void> unregisterToken() async {
        try {
            // Tell Firebase to delete the token — it will be regenerated on next getToken()
            await _messaging.deleteToken();
            print('🧹  FCM token deleted from Firebase.');
            // Backend clears fcm_token via POST /api/auth/logout
        } catch (e) {
            print('❌  Failed to delete FCM token: $e');
        }
    }

    // ─────────────────────────────────────────────────────────────
    // STEP 5: Check if app was opened via a notification (cold start)
    // Call this in main() after Firebase.initializeApp()
    // If the app was launched by tapping a notification, this returns the message
    // ─────────────────────────────────────────────────────────────
    Future<RemoteMessage?> getInitialMessage() async {
        return await _messaging.getInitialMessage();
    }
}
