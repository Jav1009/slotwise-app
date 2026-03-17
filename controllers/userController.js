// controllers/userController.js
// Profile management — update name/phone/avatar, save FCM token

const db = require('../config/db');

/**
 * Update own profile
 * PUT /api/users/profile
 * Body: { name?, phone?, avatar_url? }
 */
exports.updateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, phone, avatar_url } = req.body;

    const updates = [];
    const values  = [];

    if (name)       { updates.push('name = ?');       values.push(name.trim()); }
    if (phone !== undefined) { updates.push('phone = ?'); values.push(phone || null); }
    if (avatar_url) { updates.push('avatar_url = ?'); values.push(avatar_url); }

    if (updates.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields to update' });
    }

    values.push(userId);
    await db.query(`UPDATE users SET ${updates.join(', ')} WHERE id = ?`, values);

    // Return updated user
    const [rows] = await db.query(
      'SELECT id, name, email, role, avatar_url, phone, created_at FROM users WHERE id = ?',
      [userId]
    );

    res.json({ success: true, message: 'Profile updated', data: { user: rows[0] } });
  } catch (err) {
    console.error('updateProfile error:', err);
    res.status(500).json({ success: false, message: 'Failed to update profile' });
  }
};

/**
 * Save FCM device token for push notifications
 * POST /api/users/fcm-token
 * Body: { token }
 */
exports.saveFcmToken = async (req, res) => {
  try {
    const userId = req.user.id;
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({ success: false, message: 'Token is required' });
    }

    // Upsert: update if exists, insert if not
    await db.query(
      `INSERT INTO fcm_tokens (user_id, token, updated_at)
       VALUES (?, ?, NOW())
       ON DUPLICATE KEY UPDATE token = VALUES(token), updated_at = NOW()`,
      [userId, token]
    );

    res.json({ success: true, message: 'FCM token saved' });
  } catch (err) {
    console.error('saveFcmToken error:', err);
    res.status(500).json({ success: false, message: 'Failed to save FCM token' });
  }
};