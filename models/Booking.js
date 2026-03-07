const pool = require('../config/database');

class Booking {
    static async create(bookingData) {
        const { user_id, service_id, slot_id, notes } = bookingData;
        const connection = await pool.getConnection();
        
        try {
            await connection.beginTransaction();

            // Check if slot is still available (with lock)
            const [slotRows] = await connection.execute(
                'SELECT is_available FROM time_slots WHERE id = ? FOR UPDATE',
                [slot_id]
            );

            if (!slotRows.length || !slotRows[0].is_available) {
                throw new Error('Slot is no longer available');
            }

            // Create booking
            const [bookingResult] = await connection.execute(
                `INSERT INTO bookings (user_id, service_id, slot_id, notes) 
                 VALUES (?, ?, ?, ?)`,
                [user_id, service_id, slot_id, notes || null]
            );

            // Mark slot as unavailable
            await connection.execute(
                'UPDATE time_slots SET is_available = FALSE WHERE id = ?',
                [slot_id]
            );

            await connection.commit();
            return bookingResult.insertId;
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    }

    static async findByUser(userId) {
        const [rows] = await pool.execute(
            `SELECT b.*, 
                    s.name as service_name, s.price, s.duration_minutes,
                    ts.date, ts.start_time, ts.end_time
             FROM bookings b
             JOIN services s ON b.service_id = s.id
             JOIN time_slots ts ON b.slot_id = ts.id
             WHERE b.user_id = ?
             ORDER BY ts.date DESC, ts.start_time DESC`,
            [userId]
        );
        return rows;
    }

    static async findById(id) {
        const [rows] = await pool.execute(
            `SELECT b.*, 
                    s.name as service_name, s.price, s.duration_minutes, s.description,
                    ts.date, ts.start_time, ts.end_time,
                    u.name as user_name, u.email, u.phone
             FROM bookings b
             JOIN services s ON b.service_id = s.id
             JOIN time_slots ts ON b.slot_id = ts.id
             JOIN users u ON b.user_id = u.id
             WHERE b.id = ?`,
            [id]
        );
        return rows[0];
    }

    static async findAll(filters = {}) {
        let query = `
            SELECT b.*, 
                   s.name as service_name,
                   ts.date, ts.start_time, ts.end_time,
                   u.name as user_name, u.email
            FROM bookings b
            JOIN services s ON b.service_id = s.id
            JOIN time_slots ts ON b.slot_id = ts.id
            JOIN users u ON b.user_id = u.id
            WHERE 1=1
        `;
        const values = [];

        if (filters.status && filters.status !== 'all') {
            query += ' AND b.status = ?';
            values.push(filters.status);
        }

        if (filters.date) {
            query += ' AND ts.date = ?';
            values.push(filters.date);
        }

        if (filters.service_id) {
            query += ' AND b.service_id = ?';
            values.push(filters.service_id);
        }

        query += ' ORDER BY ts.date DESC, ts.start_time DESC';

        const [rows] = await pool.execute(query, values);
        return rows;
    }

    static async updateStatus(id, status, userId = null, isAdmin = false) {
        const connection = await pool.getConnection();
        
        try {
            await connection.beginTransaction();

            // Get booking details
            const [bookingRows] = await connection.execute(
                'SELECT * FROM bookings WHERE id = ?',
                [id]
            );

            if (!bookingRows.length) {
                throw new Error('Booking not found');
            }

            const booking = bookingRows[0];

            // Check authorization (if not admin)
            if (!isAdmin && booking.user_id !== userId) {
                throw new Error('Not authorized to update this booking');
            }

            // Update booking status
            const updates = ['status = ?'];
            const values = [status];

            if (status === 'cancelled') {
                updates.push('cancelled_at = NOW()');
                // Make slot available again
                await connection.execute(
                    'UPDATE time_slots SET is_available = TRUE WHERE id = ?',
                    [booking.slot_id]
                );
            }

            values.push(id);
            await connection.execute(
                `UPDATE bookings SET ${updates.join(', ')} WHERE id = ?`,
                values
            );

            await connection.commit();
            return true;
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    }

    static async getStats(userId = null, isAdmin = false) {
        let query = `
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
                SUM(CASE WHEN status = 'confirmed' THEN 1 ELSE 0 END) as confirmed,
                SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
                SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled
            FROM bookings
        `;
        const values = [];

        if (!isAdmin && userId) {
            query += ' WHERE user_id = ?';
            values.push(userId);
        }

        const [rows] = await pool.execute(query, values);
        return rows[0];
    }

    static async getUpcoming(userId) {
        const [rows] = await pool.execute(
            `SELECT b.*, 
                    s.name as service_name,
                    ts.date, ts.start_time, ts.end_time
             FROM bookings b
             JOIN services s ON b.service_id = s.id
             JOIN time_slots ts ON b.slot_id = ts.id
             WHERE b.user_id = ? 
               AND b.status IN ('pending', 'confirmed')
               AND CONCAT(ts.date, ' ', ts.start_time) > NOW()
             ORDER BY ts.date ASC, ts.start_time ASC`,
            [userId]
        );
        return rows;
    }
}

module.exports = Booking;