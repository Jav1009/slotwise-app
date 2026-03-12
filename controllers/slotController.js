// controllers/slotController.js
const pool = require('../config/db');

// GET /api/slots?service_id=&date=
exports.getSlots = async (req, res) => {
  const { service_id, date } = req.query;

  //---------------------------------------------------
  const includeAll = req.query.all === 'true';
  const dateParam = req.query.date || req.query.slot_date;

  let query = `SELECT * FROM time_slots WHERE service_id = ?`;
  const params = [serviceId];

  if (dateParam) {
    query += ` AND slot_date = ?`;
    params.push(dateParam);
  }
  // Only filter is_available if NOT requesting all
  if (!includeAll) {
    query += ` AND is_available = 1`;
  }
  query += ` ORDER BY start_time ASC`;

  //------------------------------------------
  if (!service_id || !date) {
    return res.status(400).json({ message: 'service_id and date are required query params.' });
  }

  try {
    const [rows] = await pool.execute(
      `SELECT * FROM time_slots
       WHERE service_id = ? AND slot_date = ? AND is_available = TRUE
       ORDER BY start_time ASC`,
      [service_id, date]
    );
    return res.json(rows);
  } catch (err) {
    console.error('[slots getSlots]', err);
    return res.status(500).json({ message: 'Failed to fetch slots.' });
  }
};

// POST /api/slots
// Accepts slots = [{ start_time, end_time }, ...]
// INSERT IGNORE skips duplicates — UNIQUE KEY handles conflicts at DB level
exports.createSlots = async (req, res) => {
  const { service_id, slot_date, slots } = req.body;

  if (!service_id || !slot_date || !Array.isArray(slots) || slots.length === 0) {
    return res.status(400).json({ message: 'service_id, slot_date, and slots array are required.' });
  }

  try {
    const values = slots.map(() => '(?, ?, ?, ?)').join(', ');
    const params = slots.flatMap(s => [service_id, slot_date, s.start_time, s.end_time]);

    await pool.execute(
      `INSERT IGNORE INTO time_slots (service_id, slot_date, start_time, end_time) VALUES ${values}`,
      params
    );

    return res.status(201).json({ message: `${slots.length} slot(s) created (duplicates ignored).` });
  } catch (err) {
    console.error('[slots createSlots]', err);
    return res.status(500).json({ message: 'Failed to create slots.' });
  }
};

// PUT /api/slots/:id
exports.update = async (req, res) => {
  const { id } = req.params;
  const { start_time, end_time, is_available } = req.body;

  try {
    const fields = [];
    const params = [];

    if (start_time !== undefined) { fields.push('start_time = ?'); params.push(start_time); }
    if (end_time !== undefined) { fields.push('end_time = ?'); params.push(end_time); }
    if (is_available !== undefined) { fields.push('is_available = ?'); params.push(is_available); }

    if (fields.length === 0) return res.status(400).json({ message: 'No fields to update.' });

    params.push(id);
    await pool.execute(`UPDATE time_slots SET ${fields.join(', ')} WHERE id = ?`, params);
    return res.json({ message: 'Slot updated.' });
  } catch (err) {
    console.error('[slots update]', err);
    return res.status(500).json({ message: 'Failed to update slot.' });
  }
};

// DELETE /api/slots/:id
exports.deleteSlot = async (req, res) => {
  const { id } = req.params;
  try {
    const [bookings] = await pool.execute(
      `SELECT id FROM bookings WHERE slot_id = ? AND status NOT IN ('cancelled')`,
      [id]
    );

    if (bookings.length > 0) {
      return res.status(409).json({
        message: 'Cannot delete a slot that has an active booking. Cancel the booking first.'
      });
    }

    await pool.execute('DELETE FROM time_slots WHERE id = ?', [id]);
    return res.json({ message: 'Slot deleted.' });
  } catch (err) {
    console.error('[slots delete]', err);
    return res.status(500).json({ message: 'Failed to delete slot.' });
  }
};