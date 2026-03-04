// controllers/notificationController.js
// Notification management logic
// Using exports.functionName pattern

const db = require('../config/db');

/**
 * Get user's notifications
 * GET /api/notifications
 */
exports.getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;

    const [notifications] = await db.query(
      `SELECT 
        n.id,
        n.message,
        n.type,
        n.is_read,
        n.created_at,
        n.booking_id
      FROM notifications n
      WHERE n.user_id = ?
      ORDER BY n.created_at DESC
      LIMIT 50`,
      [userId]
    );

    // Get unread count
    const [countResult] = await db.query(
      'SELECT COUNT(*) as unread_count FROM notifications WHERE user_id = ? AND is_read = FALSE',
      [userId]
    );

    res.json({
      success: true,
      data: {
        notifications,
        unread_count: countResult[0].unread_count
      }
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch notifications'
    });
  }
};

/**
 * Mark notification as read
 * PUT /api/notifications/:id/read
 */
exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const [result] = await db.query(
      'UPDATE notifications SET is_read = TRUE WHERE id = ? AND user_id = ?',
      [id, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.json({
      success: true,
      message: 'Notification marked as read'
    });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update notification'
    });
  }
};

/**
 * Mark all notifications as read
 * PUT /api/notifications/read-all
 */
exports.markAllAsRead = async (req, res) => {
  try {
    const userId = req.user.id;

    await db.query(
      'UPDATE notifications SET is_read = TRUE WHERE user_id = ? AND is_read = FALSE',
      [userId]
    );

    res.json({
      success: true,
      message: 'All notifications marked as read'
    });
  } catch (error) {
    console.error('Mark all as read error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update notifications'
    });
  }
};