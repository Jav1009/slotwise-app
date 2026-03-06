// controllers/bookingController.js
//
// KEY CONCEPT — DATABASE TRANSACTIONS:
//   A transaction groups multiple SQL statements atomically.
//   Either ALL succeed (commit) or NONE apply (rollback).
//   We use transactions because booking and cancellation each touch
//   TWO tables — leaving one half-updated would corrupt the data.
//
// KEY CONCEPT — SELECT FOR UPDATE:
//   Locks the row so only one transaction can proceed at a time.
//   Prevents two users booking the same slot simultaneously.
const pool = require('../config/db');
const { notifyBookingConfirmed, notifyBookingCancelled, notifyStatusUpdate } = require('./notificationController');

// POST /api/bookings
exports.createBooking = async (req, res) => {
  const { service_id, slot_id, notes } = req.body;
  const user_id = req.user.id;

  if (!service_id || !slot_id) {
    return res.status(400).json({ message: 'service_id and slot_id are required.' });
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // Lock the slot row — prevents race conditions
    const [slots] = await conn.execute(
      'SELECT id FROM time_slots WHERE id = ? AND is_available = TRUE FOR UPDATE',
      [slot_id]
    );

    if (slots.length === 0) {
      await conn.rollback();
      return res.status(409).json({ message: 'Sorry, this slot is no longer available.' });
    }

    // Mark slot as taken
    await conn.execute(
      'UPDATE time_slots SET is_available = FALSE WHERE id = ?',
      [slot_id]
    );

    // Create booking
    const [result] = await conn.execute(
      'INSERT INTO bookings (user_id, service_id, slot_id, notes) VALUES (?, ?, ?, ?)',
      [user_id, service_id, slot_id, notes || null]
    );

    // Create notification
    await conn.execute(
      'INSERT INTO notifications (user_id, booking_id, message) VALUES (?, ?, ?)',
      [user_id, result.insertId, 'Your booking has been received and is pending confirmation.']
    );

    await conn.commit();

    // Fetch service name and booking date for the notification
    const [services] = await conn.execute(
      'SELECT name FROM services WHERE id = ?',
      [service_id]
    );
    const [slotDetails] = await conn.execute(
      'SELECT slot_date FROM time_slots WHERE id = ?',
      [slot_id]
    );

    const serviceName = services[0]?.name || 'Unknown Service';
    const bookingDate = slotDetails[0]?.slot_date || 'Unknown Date';

    await notifyBookingConfirmed(user_id, result.insertId, serviceName, bookingDate);
    return res.status(201).json({ message: 'Booking created successfully.', booking_id: result.insertId });

  } catch (err) {
    await conn.rollback();
    console.error('[bookings create]', err);
    return res.status(500).json({ message: 'Booking failed. Please try again.' });
  } finally {
    conn.release(); // ALWAYS release back to pool
  }
};

// GET /api/bookings/my
// WHERE b.user_id = ? ensures users ONLY see their own bookings
exports.getMyBookings = async (req, res) => {
  const user_id = req.user.id;
  try {
    const [rows] = await pool.execute(
      `SELECT
         b.id, b.status, b.notes, b.created_at, b.updated_at,
         s.id   AS service_id,
         s.name AS service_name,
         s.price, s.image_url,
         t.slot_date, t.start_time, t.end_time
       FROM   bookings   b
       JOIN   services   s ON b.service_id = s.id
       JOIN   time_slots t ON b.slot_id    = t.id
       WHERE  b.user_id = ?
       ORDER  BY t.slot_date DESC, t.start_time DESC`,
      [user_id]
    );
    return res.json(rows);
  } catch (err) {
    console.error('[bookings myBookings]', err);
    return res.status(500).json({ message: 'Failed to fetch bookings.' });
  }
};

// PUT /api/bookings/:id/cancel
exports.cancelBooking = async (req, res) => {
  const { id }  = req.params;
  const user_id = req.user.id;

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [rows] = await conn.execute(
      'SELECT slot_id, service_id, status FROM bookings WHERE id = ? AND user_id = ?',
      [id, user_id]
    );

    if (rows.length === 0) {
      await conn.rollback();
      return res.status(404).json({ message: 'Booking not found.' });
    }

    const { slot_id, service_id, status } = rows[0];

    if (status === 'cancelled' || status === 'completed') {
      await conn.rollback();
      return res.status(400).json({ message: `Cannot cancel a booking with status '${status}'.` });
    }

    await conn.execute(
      "UPDATE bookings SET status = 'cancelled' WHERE id = ?", [id]
    );

    // Free the slot so another user can book it
    await conn.execute(
      'UPDATE time_slots SET is_available = TRUE WHERE id = ?', [slot_id]
    );

    await conn.execute(
      'INSERT INTO notifications (user_id, booking_id, message) VALUES (?, ?, ?)',
      [user_id, id, 'Your booking has been cancelled and the slot has been freed.']
    );

    // Fetch service name and booking date for notification
    const [serviceRows] = await conn.execute('SELECT name FROM services WHERE id = ?', [service_id]);
    const serviceName = serviceRows[0].name;

    const [slotRows] = await conn.execute('SELECT slot_date FROM time_slots WHERE id = ?', [slot_id]);
    const bookingDate = slotRows[0].slot_date;

    await conn.commit();
    await notifyBookingCancelled(user_id, id, serviceName, bookingDate);
    return res.json({ message: 'Booking cancelled successfully.' });

  } catch (err) {
    await conn.rollback();
    console.error('[bookings cancel]', err);
    return res.status(500).json({ message: 'Cancellation failed. Please try again.' });
  } finally {
    conn.release();
  }
};

// GET /api/bookings  (Admin)
exports.getAllBookings = async (req, res) => {
  const { status, date, service_id } = req.query;
  try {
    let sql = `
      SELECT
        b.id, b.status, b.notes, b.created_at, b.updated_at,
        CONCAT(u.first_name, ' ', u.last_name) AS customer_name, u.email AS customer_email,
        s.name AS service_name, s.price,
        t.slot_date, t.start_time, t.end_time
      FROM   bookings   b
      JOIN   users      u ON b.user_id    = u.id
      JOIN   services   s ON b.service_id = s.id
      JOIN   time_slots t ON b.slot_id    = t.id
      WHERE  1 = 1`;
    const params = [];

    if (status)     { sql += ' AND b.status = ?';     params.push(status); }
    if (date)       { sql += ' AND t.slot_date = ?';  params.push(date); }
    if (service_id) { sql += ' AND b.service_id = ?'; params.push(service_id); }

    sql += ' ORDER BY t.slot_date DESC, t.start_time DESC';

    const [rows] = await pool.execute(sql, params);
    return res.json(rows);
  } catch (err) {
    console.error('[bookings getAll]', err);
    return res.status(500).json({ message: 'Failed to fetch bookings.' });
  }
};

// PUT /api/bookings/:id/status  (Admin)
exports.updateStatus = async (req, res) => {
  const { id }     = req.params;
  const { status } = req.body;

  const allowed = ['pending', 'confirmed', 'completed', 'cancelled'];
  if (!allowed.includes(status)) {
    return res.status(400).json({ message: `Invalid status. Must be one of: ${allowed.join(', ')}` });
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [rows] = await conn.execute(
      'SELECT slot_id, service_id, status AS current_status, user_id FROM bookings WHERE id = ?', [id]
    );
    if (rows.length === 0) {
      await conn.rollback();
      return res.status(404).json({ message: 'Booking not found.' });
    }

    const { slot_id, service_id, current_status, user_id } = rows[0];

    // If cancelling, free the slot
    if (status === 'cancelled' && current_status !== 'cancelled') {
      await conn.execute(
        'UPDATE time_slots SET is_available = TRUE WHERE id = ?', [slot_id]
      );
    }

    await conn.execute('UPDATE bookings SET status = ? WHERE id = ?', [status, id]);

    const messages = {
      confirmed: 'Your booking has been confirmed!',
      completed: 'Thank you! Your appointment is complete.',
      cancelled: 'Your booking has been cancelled by the admin.',
    };
    if (messages[status]) {
      await conn.execute(
        'INSERT INTO notifications (user_id, booking_id, message) VALUES (?, ?, ?)',
        [user_id, id, messages[status]]
      );
    }

    // Fetch service name and booking date for notification
    const [serviceRows] = await conn.execute('SELECT name FROM services WHERE id = ?', [service_id]);
    const serviceName = serviceRows[0].name;

    const [slotRows] = await conn.execute('SELECT slot_date FROM time_slots WHERE id = ?', [slot_id]);
    const bookingDate = slotRows[0].slot_date;

    await conn.commit();
    await notifyStatusUpdate(user_id, id, serviceName, status);
    return res.json({ message: `Booking status updated to '${status}'.` });

  } catch (err) {
    await conn.rollback();
    console.error('[bookings updateStatus]', err);
    return res.status(500).json({ message: 'Failed to update status.' });
  } finally {
    conn.release();
  }
};