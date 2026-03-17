// utils/fcm.js
// Firebase Cloud Messaging helper — sends push notifications
// Uses the Firebase Admin SDK already initialised in config/firebase.js

const admin = require('firebase-admin');
const db    = require('../config/db');

/**
 * Send a push notification to a specific user.
 * Silently skips if the user has no FCM token stored.
 *
 * @param {number} userId  - Target user's MySQL id
 * @param {string} title   - Notification title
 * @param {string} body    - Notification body text
 * @param {Object} data    - Optional key/value payload (strings only)
 */
exports.sendToUser = async (userId, title, body, data = {}) => {
  try {
    const [rows] = await db.query(
      'SELECT token FROM fcm_tokens WHERE user_id = ?',
      [userId]
    );

    if (rows.length === 0) return; // User hasn't granted notification permission yet

    const token = rows[0].token;

    await admin.messaging().send({
      token,
      notification: { title, body },
      data: { ...data },                    // FCM data payload (must be strings)
      android: { priority: 'high' },
      apns:    { payload: { aps: { sound: 'default' } } },
    });

    console.log(`✅ Push sent to user ${userId}`);
  } catch (err) {
    // Log but never crash the booking flow over a failed push
    console.error(`❌ Push failed for user ${userId}:`, err.message);
  }
};

/**
 * Send to ALL admins (used when a new booking is created by a user).
 */
exports.sendToAdmins = async (title, body, data = {}) => {
  try {
    const [admins] = await db.query(
      `SELECT ft.token
       FROM fcm_tokens ft
       JOIN users u ON ft.user_id = u.id
       WHERE u.role = 'admin'`
    );

    if (admins.length === 0) return;

    const tokens = admins.map(r => r.token);

    // sendEachForMulticast is the current recommended method (replaces sendMulticast)
    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data:         { ...data },
      android:      { priority: 'high' },
      apns:         { payload: { aps: { sound: 'default' } } },
    });

    console.log(`✅ Push sent to ${tokens.length} admin(s)`);
  } catch (err) {
    console.error('❌ Admin push failed:', err.message);
  }
};