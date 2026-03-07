const pool = require('../config/database');

class Service {
    static async create(serviceData) {
        const { name, description, duration_minutes, price, image_url } = serviceData;
        
        const [result] = await pool.execute(
            `INSERT INTO services (name, description, duration_minutes, price, image_url) 
             VALUES (?, ?, ?, ?, ?)`,
            [name, description, duration_minutes, price, image_url || null]
        );
        return result.insertId;
    }

    static async findAll(includeInactive = false) {
        let query = 'SELECT * FROM services';
        if (!includeInactive) {
            query += ' WHERE is_active = TRUE';
        }
        query += ' ORDER BY name ASC';
        
        const [rows] = await pool.execute(query);
        return rows;
    }

    static async findById(id) {
        const [rows] = await pool.execute(
            'SELECT * FROM services WHERE id = ?',
            [id]
        );
        return rows[0];
    }

    static async update(id, updates) {
        const allowedFields = ['name', 'description', 'duration_minutes', 'price', 'image_url', 'is_active'];
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
            `UPDATE services SET ${updateFields.join(', ')} WHERE id = ?`,
            values
        );
        return result.affectedRows > 0;
    }

    static async delete(id) {
        // Soft delete
        const [result] = await pool.execute(
            'UPDATE services SET is_active = FALSE WHERE id = ?',
            [id]
        );
        return result.affectedRows > 0;
    }

    static async getStats() {
        const [rows] = await pool.execute(
            `SELECT 
                COUNT(*) as total_services,
                SUM(CASE WHEN is_active = TRUE THEN 1 ELSE 0 END) as active_services,
                AVG(price) as avg_price
             FROM services`
        );
        return rows[0];
    }
}

module.exports = Service;