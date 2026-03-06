// controllers/serviceController.js
const pool = require('../config/db');

// GET /api/services
exports.getAll = async (req, res) => {
  const { search } = req.query;
  try {
    let sql    = 'SELECT * FROM services WHERE is_active = TRUE';
    let params = [];

    if (search) {
      sql += ' AND name LIKE ?';
      params.push(`%${search}%`);
    }

    sql += ' ORDER BY name ASC';
    const [rows] = await pool.execute(sql, params);
    return res.json(rows);
  } catch (err) {
    console.error('[services getAll]', err);
    return res.status(500).json({ message: 'Failed to fetch services.' });
  }
};

// GET /api/services/:id
exports.getOne = async (req, res) => {
  const { id } = req.params;
  try {
    const [services] = await pool.execute(
      'SELECT * FROM services WHERE id = ? AND is_active = TRUE',
      [id]
    );
    if (services.length === 0) {
      return res.status(404).json({ message: 'Service not found.' });
    }

    const [slots] = await pool.execute(
      `SELECT * FROM time_slots
       WHERE service_id = ? AND is_available = TRUE AND slot_date >= CURDATE()
       ORDER BY slot_date ASC, start_time ASC`,
      [id]
    );

    return res.json({ ...services[0], slots });
  } catch (err) {
    console.error('[services getOne]', err);
    return res.status(500).json({ message: 'Failed to fetch service.' });
  }
};

// POST /api/services
exports.create = async (req, res) => {
  const { name, description, duration_minutes, price, image_url } = req.body;

  if (!name || !duration_minutes || price === undefined) {
    return res.status(400).json({ message: 'name, duration_minutes, and price are required.' });
  }

  try {
    const [result] = await pool.execute(
      'INSERT INTO services (name, description, duration_minutes, price, image_url) VALUES (?, ?, ?, ?, ?)',
      [name.trim(), description || null, duration_minutes, price, image_url || null]
    );
    return res.status(201).json({ message: 'Service created.', id: result.insertId });
  } catch (err) {
    console.error('[services create]', err);
    return res.status(500).json({ message: 'Failed to create service.' });
  }
};

// PUT /api/services/:id
exports.update = async (req, res) => {
  const { id } = req.params;
  const { name, description, duration_minutes, price, image_url, is_active } = req.body;

  try {
    const fields = [];
    const params = [];

    if (name             !== undefined) { fields.push('name = ?');             params.push(name); }
    if (description      !== undefined) { fields.push('description = ?');      params.push(description); }
    if (duration_minutes !== undefined) { fields.push('duration_minutes = ?'); params.push(duration_minutes); }
    if (price            !== undefined) { fields.push('price = ?');            params.push(price); }
    if (image_url        !== undefined) { fields.push('image_url = ?');        params.push(image_url); }
    if (is_active        !== undefined) { fields.push('is_active = ?');        params.push(is_active); }

    if (fields.length === 0) {
      return res.status(400).json({ message: 'No fields to update.' });
    }

    params.push(id);
    await pool.execute(`UPDATE services SET ${fields.join(', ')} WHERE id = ?`, params);
    return res.json({ message: 'Service updated.' });
  } catch (err) {
    console.error('[services update]', err);
    return res.status(500).json({ message: 'Failed to update service.' });
  }
};

// DELETE /api/services/:id  (soft delete)
exports.softDelete = async (req, res) => {
  const { id } = req.params;
  try {
    await pool.execute('UPDATE services SET is_active = FALSE WHERE id = ?', [id]);
    return res.json({ message: 'Service deactivated.' });
  } catch (err) {
    console.error('[services delete]', err);
    return res.status(500).json({ message: 'Failed to delete service.' });
  }
};