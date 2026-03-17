const db = require('../config/database');
const FCMService = require('../services/fcmService');

class NotificationController {
  /**
   * Register or update FCM token for a user
   */
  static async registerToken(req, res) {
    try {
      const userId = req.user.id;
      const { fcmToken, deviceType } = req.body;

      // Check if token exists
      const [existing] = await db.execute(
        'SELECT id FROM user_devices WHERE user_id = ? AND fcm_token = ?',
        [userId, fcmToken]
      );

      if (existing.length > 0) {
        // Update existing token
        await db.execute(
          'UPDATE user_devices SET last_used = NOW() WHERE id = ?',
          [existing[0].id]
        );
      } else {
        // Insert new token
        await db.execute(
          'INSERT INTO user_devices (user_id, fcm_token, device_type) VALUES (?, ?, ?)',
          [userId, fcmToken, deviceType || 'mobile']
        );
      }

      res.json({ success: true, message: 'Token registered successfully' });
    } catch (error) {
      console.error('Error registering token:', error);
      res.status(500).json({ success: false, message: 'Failed to register token' });
    }
  }

  /**
   * Remove FCM token (logout)
   */
  static async removeToken(req, res) {
    try {
      const userId = req.user.id;
      const { fcmToken } = req.body;

      await db.execute(
        'DELETE FROM user_devices WHERE user_id = ? AND fcm_token = ?',
        [userId, fcmToken]
      );

      res.json({ success: true, message: 'Token removed successfully' });
    } catch (error) {
      console.error('Error removing token:', error);
      res.status(500).json({ success: false, message: 'Failed to remove token' });
    }
  }

  /**
   * Get user's devices
   */
  static async getUserDevices(req, res) {
    try {
      const userId = req.user.id;

      const [devices] = await db.execute(
        'SELECT id, device_type, last_used, created_at FROM user_devices WHERE user_id = ?',
        [userId]
      );

      res.json({ success: true, devices });
    } catch (error) {
      console.error('Error getting devices:', error);
      res.status(500).json({ success: false, message: 'Failed to get devices' });
    }
  }

  /**
   * Get all admin FCM tokens
   */
  static async getAdminTokens() {
    try {
      const [tokens] = await db.execute(`
        SELECT ud.fcm_token 
        FROM user_devices ud
        JOIN users u ON u.id = ud.user_id
        WHERE u.role = 'admin'
      `);

      return tokens.map(t => t.fcm_token);
    } catch (error) {
      console.error('Error getting admin tokens:', error);
      return [];
    }
  }

  /**
   * Get user's FCM tokens
   */
  static async getUserTokens(userId) {
    try {
      const [tokens] = await db.execute(
        'SELECT fcm_token FROM user_devices WHERE user_id = ?',
        [userId]
      );

      return tokens.map(t => t.fcm_token);
    } catch (error) {
      console.error('Error getting user tokens:', error);
      return [];
    }
  }
}

module.exports = NotificationController;
