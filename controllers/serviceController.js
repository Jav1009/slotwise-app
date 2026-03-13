// controllers/serviceController.js
//
// Changes from previous version:
//   • create: accepts category + created_by (set from req.user.id)
//   • create: auto-generates time slots for the next 30 days based on duration_minutes
//   • getAll: exposes category in response, supports category filter query param
//   • update: accepts category field
//   • All other logic unchanged

// const { status } = require('express/lib/response');
const pool = require('../config/db');

// ─────────────────────────────────────────────────────────────
// HELPER — Auto-generate slots for a service
//
// When a service is created, we generate slots for the next
// DAYS_AHEAD days using the service's duration_minutes.
//
// Business hours: 09:00 – 17:00 (configurable below)
// Each slot = duration_minutes long, back-to-back with no gap.
//
// Staff can then remove individual slots they don't want.
// ─────────────────────────────────────────────────────────────
const DAYS_AHEAD = 30;          // How many days ahead to pre-generate
const DAY_START = 9 * 60;      // 09:00 in minutes from midnight
const DAY_END = 17 * 60;     // 17:00 in minutes from midnight

function minutesToTime(minutes) {
  // Converts 570 → '09:30:00'
  const h = Math.floor(minutes / 60).toString().padStart(2, '0');
  const m = (minutes % 60).toString().padStart(2, '0');
  return `${h}:${m}:00`;
}

async function autoGenerateSlots(conn, serviceId, durationMinutes) {
  const today = new Date();
  const values = [];
  const params = [];

  for (let d = 0; d < DAYS_AHEAD; d++) {
    const date = new Date(today);
    date.setDate(today.getDate() + d);
    const dateStr = date.toISOString().split('T')[0]; // 'YYYY-MM-DD'

    let cursor = DAY_START;
    while (cursor + durationMinutes <= DAY_END) {
      const start = minutesToTime(cursor);
      const end = minutesToTime(cursor + durationMinutes);
      values.push('(?, ?, ?, ?)');
      params.push(serviceId, dateStr, start, end);
      cursor += durationMinutes;
    }
  }

  if (values.length === 0) return;

  // INSERT IGNORE — UNIQUE KEY on (service_id, slot_date, start_time) prevents dupes
  await conn.query(
    `INSERT IGNORE INTO time_slots (service_id, slot_date, start_time, end_time)
         VALUES ${values.join(', ')}`,
    params
  );
}



// ─────────────────────────────────────────────────────────────
// GET ALL SERVICES
// GET /api/services?search=&category=
// Public — no auth required
// ─────────────────────────────────────────────────────────────
exports.getAll = async (req, res, next) => {
  const { search, category } = req.query;
  const includeInactive = req.query.include_inactive === 'true';

   try {
    // Build WHERE clause dynamically
    const conditions = [];
    const params     = [];
 
    // Only filter by is_active when NOT requesting inactive services too
    if (!includeInactive) {
      conditions.push('is_active = 1');
    }
    // let sql = 'SELECT * FROM services WHERE is_active = TRUE';
    // let params = [];

    if (search) {
      // sql += ' AND name LIKE ?';
      conditions.push('name LIKE ?');
      params.push(`%${search}%`);
    }

    if (category) {
      // sql += ' AND category = ?';
      conditions.push('category = ?');
      params.push(category);
    }

    const whereClause = conditions.length > 0
      ? 'WHERE ' + conditions.join(' AND ')
      : '';

    const sql = `SELECT * FROM services ${whereClause} ORDER BY category ASC, name ASC`;

    // sql += ' ORDER BY category asc, name ASC';

    const [rows] = await pool.execute(sql, params);
    //   return res.json(rows);
    // } catch (err) {
    //   console.error('[services getAll]', err);
    //   return res.status(500).json({ message: 'Failed to fetch services.' });
    // }
    return res.status(200).json({ status: 'success', data: rows });
  } catch (err) {
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────
// GET ONE SERVICE + available slots
// GET /api/services/:id
// Public — no auth required
// ─────────────────────────────────────────────────────────────
exports.getOne = async (req, res, next) => {
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

    return res.status(200).json({ status: 'success', data: { ...services[0], slots } });
  } catch (err) {
    // console.error('[services getOne]', err);
    // return res.status(500).json({ message: 'Failed to fetch service.' });
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────
// CREATE SERVICE
// POST /api/services  (staff or admin)
// Body: { name, description, duration_minutes, price, image_url, category }
// Auto-generates slots for next 30 days after creation.
// ─────────────────────────────────────────────────────────────
exports.create = async (req, res, next) => {
  const { name, description, duration_minutes, price, image_url, category } = req.body;

  if (!name || !duration_minutes || price === undefined || !category) {
    return res.status(400).json({ message: 'name, duration_minutes, category and price are required.' });
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const userId = req.user.id;

    // const [result] = await pool.execute(
    const [result] = await conn.query(
      `INSERT INTO services (name, description, duration_minutes, price, image_url, category, created_by) 
      VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        name.trim(),
        description || null,
        duration_minutes,
        price,
        image_url || null,
        category,
        userId  // Track who created this service (for staff notifications)
      ]
    );
    const serviceId = result.insertId;

    // Auto-generate time slots for next 30 days
    await autoGenerateSlots(conn, serviceId, duration_minutes);

    await conn.commit();

    return res.status(201).json({
      status: 'success',
      message: 'Service created and slots auto-generated.',
      data: { id: serviceId }
    });
  } catch (err) {
    await conn.rollback();
    next(err);
  } finally {
    conn.release();
  }
};

// ─────────────────────────────────────────────────────────────
// UPDATE SERVICE
// PUT /api/services/:id  (staff or admin)
// Supports partial update — only provided fields are changed.
// ─────────────────────────────────────────────────────────────
exports.update = async (req, res, next) => {
  const { id } = req.params;
  const { name, description, duration_minutes, price, image_url, category, is_active } = req.body;

  try {
    const fields = [];
    const params = [];

    if (name !== undefined) { fields.push('name = ?'); params.push(name); }
    if (description !== undefined) { fields.push('description = ?'); params.push(description); }
    if (duration_minutes !== undefined) { fields.push('duration_minutes = ?'); params.push(duration_minutes); }
    if (price !== undefined) { fields.push('price = ?'); params.push(price); }
    if (image_url !== undefined) { fields.push('image_url = ?'); params.push(image_url); }
    if (category !== undefined) { fields.push('category = ?'); params.push(category); }
    if (is_active !== undefined) { fields.push('is_active = ?'); params.push(is_active); }

    if (fields.length === 0) {
      return res.status(400).json({ message: 'No fields to update.' });
    }

    params.push(id);
    await pool.execute(`UPDATE services SET ${fields.join(', ')} WHERE id = ?`, params);

    return res.json({ message: 'Service updated.' });
  } catch (err) {
    console.error('[services update]', err);
    // return res.status(500).json({ message: 'Failed to update service.' });
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────
// SOFT DELETE SERVICE
// DELETE /api/services/:id  (admin only)
// Sets is_active = FALSE — does not remove data.
// ─────────────────────────────────────────────────────────────
exports.softDelete = async (req, res, next) => {
  const { id } = req.params;
  try {
    await pool.execute('UPDATE services SET is_active = FALSE WHERE id = ?', [id]);
    return res.json({ message: 'Service deactivated.' });
  } catch (err) {
    console.error('[services delete]', err);
    // return res.status(500).json({ message: 'Failed to delete service.' });
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────
// GET CATEGORIES
// GET /api/services/categories
// Returns distinct non-null categories for the filter chips.
// ─────────────────────────────────────────────────────────────
exports.getCategories = async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT DISTINCT category
             FROM services
             WHERE is_active = TRUE AND category IS NOT NULL
             ORDER BY category ASC`
    );
    const categories = rows.map(r => r.category);
    return res.status(200).json({ status: 'success', data: categories });
  } catch (err) {
    next(err);
  }
};
