const pool = require('../config/database');

class Slot {
    static async create(slotData) {
        const { service_id, date, start_time, end_time, created_by } = slotData;
        
        const [result] = await pool.execute(
            `INSERT INTO time_slots (service_id, date, start_time, end_time, created_by) 
             VALUES (?, ?, ?, ?, ?)`,
            [service_id, date, start_time, end_time, created_by]
        );
        return result.insertId;
    }

    static async createBatch(slots) {
        const connection = await pool.getConnection();
        try {
            await connection.beginTransaction();
            
            const results = [];
            for (const slot of slots) {
                const [result] = await connection.execute(
                    `INSERT INTO time_slots (service_id, date, start_time, end_time, created_by) 
                     VALUES (?, ?, ?, ?, ?)`,
                    [slot.service_id, slot.date, slot.start_time, slot.end_time, slot.created_by]
                );
                results.push(result.insertId);
            }
            
            await connection.commit();
            return results;
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    }

    static async findAvailable(serviceId, date) {
        const [rows] = await pool.execute(
            `SELECT * FROM time_slots 
             WHERE service_id = ? AND date = ? AND is_available = TRUE 
             ORDER BY start_time ASC`,
            [serviceId, date]
        );
        return rows;
    }

    static async findByServiceAndDateRange(serviceId, startDate, endDate) {
        const [rows] = await pool.execute(
            `SELECT * FROM time_slots 
             WHERE service_id = ? AND date BETWEEN ? AND ? 
             ORDER BY date ASC, start_time ASC`,
            [serviceId, startDate, endDate]
        );
        return rows;
    }

    static async findById(id) {
        const [rows] = await pool.execute(
            'SELECT * FROM time_slots WHERE id = ?',
            [id]
        );
        return rows[0];
    }

    static async update(id, updates) {
        const allowedFields = ['date', 'start_time', 'end_time', 'is_available'];
        const updateFields = [];
        const values = [];

        for (const [key, value] of Object.entries(updates)) {
            if (allowedFields.includes(key) && value !== undefined) {
                updateFields.push(`${key} = ?`);
                values.push(value);
            }
        }

        if (updateFields.length === 0) return false;

        values.push(id);
        const [result] = await pool.execute(
            `UPDATE time_slots SET ${updateFields.join(', ')} WHERE id = ?`,
            values
        );
        return result.affectedRows > 0;
    }

    static async delete(id) {
        // Only allow deletion if slot is not booked
        const [result] = await pool.execute(
            'DELETE FROM time_slots WHERE id = ? AND is_available = TRUE',
            [id]
        );
        return result.affectedRows > 0;
    }

    static async checkAvailability(slotId) {
        const [rows] = await pool.execute(
            'SELECT is_available FROM time_slots WHERE id = ?',
            [slotId]
        );
        return rows[0]?.is_available || false;
    }

    static async markAsBooked(slotId) {
        const [result] = await pool.execute(
            'UPDATE time_slots SET is_available = FALSE WHERE id = ?',
            [slotId]
        );
        return result.affectedRows > 0;
    }

    static async markAsAvailable(slotId) {
        const [result] = await pool.execute(
            'UPDATE time_slots SET is_available = TRUE WHERE id = ?',
            [slotId]
        );
        return result.affectedRows > 0;
    }
}

module.exports = Slot;