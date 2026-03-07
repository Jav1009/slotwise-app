const pool = require('../config/database');
const bcrypt = require('bcryptjs');

class User {
    static async create(userData) {
        const { name, email, password, role = 'user', phone } = userData;
        const password_hash = await bcrypt.hash(password, 10);
        
        const [result] = await pool.execute(
            `INSERT INTO users (name, email, password_hash, role, phone) 
             VALUES (?, ?, ?, ?, ?)`,
            [name, email, password_hash, role, phone || null]
        );
        return result.insertId;
    }

    static async findByEmail(email) {
        const [rows] = await pool.execute(
            'SELECT * FROM users WHERE email = ?',
            [email]
        );
        return rows[0];
    }

    static async findById(id) {
        const [rows] = await pool.execute(
            `SELECT id, name, email, role, avatar_url, phone, created_at 
             FROM users WHERE id = ?`,
            [id]
        );
        return rows[0];
    }

    static async updateProfile(id, updates) {
        const allowedFields = ['name', 'avatar_url', 'phone'];
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
            `UPDATE users SET ${updateFields.join(', ')} WHERE id = ?`,
            values
        );
        return result.affectedRows > 0;
    }

    static async validatePassword(user, password) {
        return bcrypt.compare(password, user.password_hash);
    }

    static async getAllUsers() {
        const [rows] = await pool.execute(
            'SELECT id, name, email, role, created_at FROM users ORDER BY created_at DESC'
        );
        return rows;
    }
}

module.exports = User;