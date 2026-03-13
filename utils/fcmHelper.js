// utils/fcmHelper.js
//
// Shared FCM sending utility.
// Both notificationController.js and scheduler.js import from here
// so there is exactly ONE copy of sendToToken.

const pool  = require('../config/db');
const admin = require('../config/firebase');

// ─────────────────────────────────────────────────────────────
// SEND TO SINGLE FCM TOKEN
// HELPER: Send a push notification to a single FCM token
// Called internally by other functions — not exposed as a route directly
//
// token      — the device FCM token stored in users.fcm_token
// title      — notification title shown in the system tray
// body       — notification body text
// data       — optional key-value pairs sent as a data payload to the app
//              (Flutter can read these via onMessage, onMessageOpenedApp)
// ─────────────────────────────────────────────────────────────
async function sendToToken(token, title, body, data = {}) {
    // Validate token before attempting to send — avoids unnecessary Firebase API call
  if (!token || typeof token !== 'string' || token.trim() === '') {
    console.warn('⚠️  sendToToken: No valid FCM token. Skipped.');
    return { success: false, reason: 'no_token' };
  }

  try {
    // Build the FCM message object
    const message = {
        // notification block: shown in the system notification tray
      notification: { title, body },
      // data block: key-value strings delivered to the app even when closed
        // Flutter reads this in FirebaseMessaging.onBackgroundMessage
      data: {
        // All values in the data block MUST be strings
        ...Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        ),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',  // Required for Flutter tap-to-open
      },
      // Android-specific config: set notification channel and priority
      android: {
        priority: 'high', // Wakes device even in Doze mode
        notification: {
          channelId: 'slotwise_bookings',  // Must match channel created in Flutter main.dart
          sound: 'default',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      // APNs (iOS) config
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1, contentAvailable: true // Allows background processing on iOS
          },
        },
        headers: { 'apns-priority': '10' }, // 10 = immediate delivery
      },
      token, // Target device FCM token
    };

    // Send via Firebase Admin SDK
    const response = await admin.messaging().send(message);
    console.log(`✅  Notification sent. Firebase message ID: ${response}`);
    return { success: true, messageId: response };
  } catch (error) {
    // messaging/registration-token-not-registered: token is stale
        // The user uninstalled the app, or FCM rotated the token and it wasn't updated
    if (error.errorInfo?.code === 'messaging/registration-token-not-registered') {
      console.warn(`⚠️  Stale FCM token: ${token.substring(0, 20)}...`);
      // Clear the stale token from the DB so future calls skip this user
      await clearStaleToken(token);
      return { success: false, reason: 'stale_token' };
    }
    // Other Firebase errors — log but don't crash the caller
    console.error('❌  Firebase FCM error:', error.message || error);
    return { success: false, reason: 'firebase_error', error: error.message };
  }
}

// ─────────────────────────────────────────────────────────────
// CLEAR STALE TOKEN FROM DB
// Called when Firebase returns registration-token-not-registered
// ─────────────────────────────────────────────────────────────
async function clearStaleToken(token) {
  try {
    const [result] = await pool.query(
      'UPDATE users SET fcm_token = NULL WHERE fcm_token = ?',
      [token]
    );
    if (result.affectedRows > 0) {
      console.log(`🧹  Cleared stale FCM token from ${result.affectedRows} user(s).`);
    }
  } catch (err) {
    // DB error clearing token is non-fatal — just log it
    console.error('❌  Failed to clear stale token:', err.message);
  }
}

module.exports = { sendToToken, clearStaleToken };