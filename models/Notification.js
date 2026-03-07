const pool = require('../config/database');

class Notification {
    static async create(notificationData) {
        const { user_id, booking_id, message, type } = notificationData;
        
        const [result] = await pool.execute(
            `INSERT INTO notifications (user_id, booking_id, message, type) 
             VALUES (?, ?, ?, ?)`,
            [user_id, booking_id, message, type]
        );
        return result.insertId;
    }

    static async findByUser(userId, onlyUnread = false) {
        let query = `
            SELECT n.*, 
                   b.status as booking_status
            FROM notifications n
            LEFT JOIN bookings b ON n.booking_id = b.id
            WHERE n.user_id = ?
        `;
        
        if (onlyUnread) {
            query += ' AND n.is_read = FALSE';
        }
        
        query += ' ORDER BY n.created_at DESC';
        
        const [rows] = await pool.execute(query, [userId]);
        return rows;
    }

    static async markAsRead(id, userId) {
        const [result] = await pool.execute(
            'UPDATE notifications SET is_read = TRUE WHERE id = ? AND user_id = ?',
            [id, userId]
        );
        return result.affectedRows > 0;
    }

    static async markAllAsRead(userId) {
        const [result] = await pool.execute(
            'UPDATE notifications SET is_read = TRUE WHERE user_id = ? AND is_read = FALSE',
            [userId]
        );
        return result.affectedRows;
    }

    static async getUnreadCount(userId) {
        const [rows] = await pool.execute(
            'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = FALSE',
            [userId]
        );
        return rows[0].count;
    }

    static async createBookingNotifications(bookingId, userId, serviceName, date, time) {
        // Create notification for customer
        await this.create({
            user_id: userId,
            booking_id: bookingId,
            message: `Your booking for ${serviceName} on ${date} at ${time} has been confirmed.`,
            type: 'booking_confirmed'
        });

        // Create notification for admin (you might want to notify all admins)
        const [adminRows] = await pool.execute(
            'SELECT id FROM users WHERE role = "admin"'
        );

        for (const admin of adminRows) {
            await this.create({
                user_id: admin.id,
                booking_id: bookingId,
                message: `New booking: ${serviceName} on ${date} at ${time}`,
                type: 'new_booking'
            });
        }
    }
}

module.exports = Notification;