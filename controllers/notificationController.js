// controllers/notificationController.js
// Sends push notifications via Firebase Admin SDK (firebase-admin)
// This controller handles: single-user notifications, multi-user broadcast,
// and booking-specific notification helpers used by bookingController.

const pool = require('../config/db');
const admin = require('../config/firebase');  // Firebase Admin SDK instance

// ─────────────────────────────────────────────────────────────
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
        console.warn('⚠️  sendToToken: No valid FCM token provided. Notification skipped.');
        return { success: false, reason: 'no_token' };
    }

    try {
        // Build the FCM message object
        const message = {
            // notification block: shown in the system notification tray
            notification: {
                title,
                body
            },
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
                priority: 'high',             // Wakes device even in Doze mode
                notification: {
                    channelId: 'slotwise_bookings',  // Must match channel created in Flutter main.dart
                    sound: 'default',
                    priority: 'high',
                    defaultSound: true,
                    defaultVibrateTimings: true
                }
            },
            // APNs (iOS) config
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                        contentAvailable: true  // Allows background processing on iOS
                    }
                },
                headers: {
                    'apns-priority': '10'       // 10 = immediate delivery
                }
            },
            token  // Target device FCM token
        };

        // Send via Firebase Admin SDK
        const response = await admin.messaging().send(message);
        console.log(`✅  Notification sent. Firebase message ID: ${response}`);
        return { success: true, messageId: response };
    } catch (error) {
        // messaging/registration-token-not-registered: token is stale
        // The user uninstalled the app, or FCM rotated the token and it wasn't updated
        if (error.errorInfo?.code === 'messaging/registration-token-not-registered') {
            console.warn(`⚠️  Stale FCM token detected for token: ${token.substring(0, 20)}...`);
            // Clear the stale token from the DB so future calls skip this user
            await clearStaleToken(token);
            return { success: false, reason: 'stale_token' };
        }

        // Other Firebase errors — log but don't crash the caller
        console.error('❌  Firebase send error:', error.message || error);
        return { success: false, reason: 'firebase_error', error: error.message };
    }
}

// ─────────────────────────────────────────────────────────────
// HELPER: Clear a stale FCM token from the DB
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
    } catch (dbError) {
        // DB error clearing token is non-fatal — just log it
        console.error('❌  Failed to clear stale FCM token:', dbError.message);
    }
}

// ─────────────────────────────────────────────────────────────
// SEND BOOKING CONFIRMATION NOTIFICATION
// Called by bookingController after a booking is successfully created
// Notifies the customer that their booking was confirmed
//
// Usage: await notifyBookingConfirmed(userId, bookingId, serviceName, bookingDate)
// ─────────────────────────────────────────────────────────────
exports.notifyBookingConfirmed = async (userId, bookingId, serviceName, bookingDate) => {
    try {
        // Fetch user's FCM token from DB
        const [rows] = await pool.query(
            'SELECT fcm_token FROM users WHERE id = ? AND is_active = 1',
            [userId]
        );

        if (rows.length === 0 || !rows[0].fcm_token) {
            // User has no FCM token — notifications not enabled on their device
            console.log(`ℹ️  No FCM token for user ${userId}. Booking confirmed notification skipped.`);
            return;
        }

        await sendToToken(
            rows[0].fcm_token,
            '✅ Booking Confirmed',
            `Your booking for ${serviceName} on ${bookingDate} has been confirmed.`,
            {
                type: 'booking_confirmed',     // Flutter reads this to navigate to the right screen
                booking_id: String(bookingId),
                service_name: serviceName,
                booking_date: bookingDate
            }
        );
    } catch (error) {
        // Notification failure is non-fatal — the booking was already saved
        console.error('❌  notifyBookingConfirmed error:', error.message);
    }
};

// ─────────────────────────────────────────────────────────────
// SEND BOOKING CANCELLATION NOTIFICATION
// Called by bookingController when a booking is cancelled (by user or admin)
// ─────────────────────────────────────────────────────────────
exports.notifyBookingCancelled = async (userId, bookingId, serviceName, bookingDate) => {
    try {
        const [rows] = await pool.query(
            'SELECT fcm_token FROM users WHERE id = ? AND is_active = 1',
            [userId]
        );

        if (rows.length === 0 || !rows[0].fcm_token) return;

        await sendToToken(
            rows[0].fcm_token,
            '❌ Booking Cancelled',
            `Your booking for ${serviceName} on ${bookingDate} has been cancelled.`,
            {
                type: 'booking_cancelled',
                booking_id: String(bookingId),
                service_name: serviceName,
                booking_date: bookingDate
            }
        );
    } catch (error) {
        console.error('❌  notifyBookingCancelled error:', error.message);
    }
};

// ─────────────────────────────────────────────────────────────
// SEND STATUS UPDATE NOTIFICATION
// Called by bookingController when admin updates a booking status
// e.g., Pending → Confirmed, Confirmed → Completed
// ─────────────────────────────────────────────────────────────
exports.notifyStatusUpdate = async (userId, bookingId, serviceName, newStatus) => {
    try {
        const [rows] = await pool.query(
            'SELECT fcm_token FROM users WHERE id = ? AND is_active = 1',
            [userId]
        );

        if (rows.length === 0 || !rows[0].fcm_token) return;

        // Map status values to user-friendly messages
        const statusMessages = {
            Confirmed:  `Your booking for ${serviceName} has been confirmed.`,
            Completed:  `Your ${serviceName} appointment has been marked as completed.`,
            Cancelled:  `Your booking for ${serviceName} has been cancelled by an admin.`,
            Pending:    `Your booking for ${serviceName} is pending review.`
        };

        const body = statusMessages[newStatus] || `Your booking status has been updated to: ${newStatus}`;

        await sendToToken(
            rows[0].fcm_token,
            '📋 Booking Update',
            body,
            {
                type: 'status_update',
                booking_id: String(bookingId),
                service_name: serviceName,
                new_status: newStatus
            }
        );
    } catch (error) {
        console.error('❌  notifyStatusUpdate error:', error.message);
    }
};

// ─────────────────────────────────────────────────────────────
// ADMIN BROADCAST — Send notification to ALL active users
// POST /api/notifications/broadcast
// Admin only — protected by authMiddleware + adminMiddleware
// Body: { title, body, data (optional) }
// ─────────────────────────────────────────────────────────────
exports.broadcastToAll = async (req, res, next) => {
    try {
        const { title, body, data } = req.body;

        if (!title || !body) {
            res.status(400);
            throw new Error('title and body are required');
        }

        // Fetch all active users who have an FCM token registered
        const [users] = await pool.query(
            'SELECT id, fcm_token FROM users WHERE is_active = 1 AND fcm_token IS NOT NULL'
        );

        if (users.length === 0) {
            return res.status(200).json({
                status: 'success',
                message: 'No users with registered FCM tokens found.',
                data: { sent: 0, failed: 0 }
            });
        }

        // Send to all users concurrently using Promise.allSettled
        // allSettled continues even if some sends fail — doesn't abort on first error
        const results = await Promise.allSettled(
            users.map(user => sendToToken(user.fcm_token, title, body, data || {}))
        );

        // Count successes and failures
        const sent = results.filter(r => r.status === 'fulfilled' && r.value?.success).length;
        const failed = results.length - sent;

        res.status(200).json({
            status: 'success',
            message: `Broadcast complete. Sent: ${sent}, Failed/Skipped: ${failed}`,
            data: { total: users.length, sent, failed }
        });
    } catch (error) {
        next(error);
    }
};

// ─────────────────────────────────────────────────────────────
// SEND NOTIFICATION TO SPECIFIC USER (Admin use)
// POST /api/notifications/send
// Admin only
// Body: { userId, title, body, data (optional) }
// ─────────────────────────────────────────────────────────────
exports.sendToUser = async (req, res, next) => {
    try {
        const { userId, title, body, data } = req.body;

        if (!userId || !title || !body) {
            res.status(400);
            throw new Error('userId, title, and body are required');
        }

        const [rows] = await pool.query(
            'SELECT fcm_token FROM users WHERE id = ? AND is_active = 1',
            [userId]
        );

        if (rows.length === 0) {
            res.status(404);
            throw new Error('User not found or inactive');
        }

        if (!rows[0].fcm_token) {
            return res.status(200).json({
                status: 'success',
                message: 'User has no FCM token registered. Notification skipped.',
                data: null
            });
        }

        const result = await sendToToken(rows[0].fcm_token, title, body, data || {});

        res.status(200).json({
            status: 'success',
            message: result.success ? 'Notification sent' : 'Notification failed',
            data: result
        });
    } catch (error) {
        next(error);
    }
};

// GET /api/notifications
exports.getAll = async (req, res) => {
  const user_id = req.user.id;
  try {
    const [rows] = await pool.execute(
      `SELECT id, booking_id, message, is_read, created_at
       FROM   notifications
       WHERE  user_id = ?
       ORDER  BY created_at DESC`,
      [user_id]
    );
    return res.json(rows);
  } catch (err) {
    console.error('[notifications getAll]', err);
    return res.status(500).json({ message: 'Failed to fetch notifications.' });
  }
};

// PUT /api/notifications/:id/read
exports.markRead = async (req, res) => {
  const { id }  = req.params;
  const user_id = req.user.id;
  try {
    // user_id check prevents users marking other users' notifications
    await pool.execute(
      'UPDATE notifications SET is_read = TRUE WHERE id = ? AND user_id = ?',
      [id, user_id]
    );
    return res.json({ message: 'Notification marked as read.' });
  } catch (err) {
    console.error('[notifications markRead]', err);
    return res.status(500).json({ message: 'Failed to update notification.' });
  }
};

// PUT /api/notifications/read-all
exports.markAllRead = async (req, res) => {
  const user_id = req.user.id;
  try {
    await pool.execute(
      'UPDATE notifications SET is_read = TRUE WHERE user_id = ? AND is_read = FALSE',
      [user_id]
    );
    return res.json({ message: 'All notifications marked as read.' });
  } catch (err) {
    console.error('[notifications markAllRead]', err);
    return res.status(500).json({ message: 'Failed to update notifications.' });
  }
};