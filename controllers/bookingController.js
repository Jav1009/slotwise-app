// controllers/bookingController.js
// Added FCM push calls after createBooking and updateBookingStatus

const db = require('../config/db');
const fcm = require('../utils/fcm');

/** GET /api/bookings/me */
exports.getMyBookings = async (req, res) => {
  try {
    const [bookings] = await db.query(
      `SELECT b.id, b.status, b.notes, b.created_at, b.cancelled_at,
              s.name AS service_name, s.duration_minutes, s.price,
              ts.date, ts.start_time, ts.end_time
       FROM bookings b
       JOIN services s   ON b.service_id = s.id
       JOIN time_slots ts ON b.slot_id   = ts.id
       WHERE b.user_id = ?
       ORDER BY ts.date DESC, ts.start_time DESC`,
      [req.user.id]
    );
    res.json({ success: true, data: { bookings } });
  } catch (err) {
    console.error('getMyBookings error:', err);
    res.status(500).json({ success: false, message: 'Failed to fetch bookings' });
  }
};

/** POST /api/bookings — conflict-safe with transaction + push to admins */
exports.createBooking = async (req, res) => {
  const connection = await db.getConnection();
  try {
    await connection.beginTransaction();

    const { service_id, slot_id, notes } = req.body;
    const userId = req.user.id;

    if (!service_id || !slot_id) {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'Service and slot are required' });
    }

    // Lock row to prevent double-booking
    const [slots] = await connection.query(
      'SELECT * FROM time_slots WHERE id = ? FOR UPDATE', [slot_id]
    );
    if (slots.length === 0 || !slots[0].is_available) {
      await connection.rollback();
      return res.status(409).json({ success: false, message: 'This time slot is no longer available' });
    }

    const [existing] = await connection.query(
      `SELECT id FROM bookings WHERE slot_id = ? AND status IN ('pending','confirmed')`,
      [slot_id]
    );
    if (existing.length > 0) {
      await connection.rollback();
      return res.status(409).json({ success: false, message: 'Booking conflict. Please select another slot.' });
    }

    const [bookingResult] = await connection.query(
      `INSERT INTO bookings (user_id, service_id, slot_id, status, notes) VALUES (?, ?, ?, 'pending', ?)`,
      [userId, service_id, slot_id, notes || null]
    );

    await connection.query('UPDATE time_slots SET is_available = FALSE WHERE id = ?', [slot_id]);

    await connection.query(
      `INSERT INTO notifications (user_id, booking_id, message, type) VALUES (?, ?, ?, ?)`,
      [userId, bookingResult.insertId, 'Your booking has been created and is pending confirmation.', 'booking_created']
    );

    await connection.commit();

    // Fetch user name for admin notification
    const [[user]] = await db.query('SELECT name FROM users WHERE id = ?', [userId]);
    const [[service]] = await db.query('SELECT name FROM services WHERE id = ?', [service_id]);

    // Push to all admins — fire and forget (non-blocking)
    fcm.sendToAdmins(
      '📅 New Booking',
      `${user.name} booked ${service.name}`,
      { booking_id: String(bookingResult.insertId), type: 'new_booking' }
    );

    const [newBooking] = await db.query(
      `SELECT b.id, b.status, b.notes, b.created_at,
              s.name AS service_name, s.price, ts.date, ts.start_time, ts.end_time
       FROM bookings b
       JOIN services s ON b.service_id = s.id
       JOIN time_slots ts ON b.slot_id = ts.id
       WHERE b.id = ?`,
      [bookingResult.insertId]
    );

    res.status(201).json({ success: true, message: 'Booking created', data: { booking: newBooking[0] } });
  } catch (err) {
    await connection.rollback();
    console.error('createBooking error:', err);
    res.status(500).json({ success: false, message: 'Failed to create booking' });
  } finally {
    connection.release();
  }
};

/** PUT /api/bookings/:id/cancel */
exports.cancelBooking = async (req, res) => {
  const connection = await db.getConnection();
  try {
    await connection.beginTransaction();
    const { id } = req.params;
    const userId = req.user.id;

    const [bookings] = await connection.query(
      'SELECT * FROM bookings WHERE id = ? AND user_id = ? FOR UPDATE', [id, userId]
    );
    if (bookings.length === 0) {
      await connection.rollback();
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const booking = bookings[0];
    if (!['pending', 'confirmed'].includes(booking.status)) {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'This booking cannot be cancelled' });
    }

    await connection.query(
      'UPDATE bookings SET status = ?, cancelled_at = NOW() WHERE id = ?', ['cancelled', id]
    );
    await connection.query('UPDATE time_slots SET is_available = TRUE WHERE id = ?', [booking.slot_id]);
    await connection.query(
      `INSERT INTO notifications (user_id, booking_id, message, type) VALUES (?, ?, ?, ?)`,
      [userId, id, 'Your booking has been cancelled.', 'booking_cancelled']
    );

    await connection.commit();
    res.json({ success: true, message: 'Booking cancelled' });
  } catch (err) {
    await connection.rollback();
    console.error('cancelBooking error:', err);
    res.status(500).json({ success: false, message: 'Failed to cancel booking' });
  } finally {
    connection.release();
  }
};

/** PUT /api/admin/bookings/:id/status — push notification to user */
exports.updateBookingStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const validStatuses = ['pending', 'confirmed', 'cancelled', 'completed'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status' });
    }

    const [result] = await db.query('UPDATE bookings SET status = ? WHERE id = ?', [status, id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const [[booking]] = await db.query(
      `SELECT b.user_id, s.name AS service_name
       FROM bookings b JOIN services s ON b.service_id = s.id
       WHERE b.id = ?`, [id]
    );

    // Build a human-readable message
    const statusMessages = {
      confirmed: `Your ${booking.service_name} booking has been confirmed! ✅`,
      completed: `Your ${booking.service_name} appointment is complete. Thanks for visiting! 🎉`,
      cancelled: `Your ${booking.service_name} booking was cancelled by the admin.`,
      pending: `Your ${booking.service_name} booking is pending review.`,
    };
    const message = statusMessages[status] ?? `Booking status updated to ${status}.`;

    // In-app notification
    await db.query(
      `INSERT INTO notifications (user_id, booking_id, message, type) VALUES (?, ?, ?, ?)`,
      [booking.user_id, id, message, 'status_update']
    );

    // Push notification to user
    fcm.sendToUser(
      booking.user_id,
      'Booking Update',
      message,
      { booking_id: String(id), type: 'status_update', status }
    );

    res.json({ success: true, message: 'Booking status updated' });
  } catch (err) {
    console.error('updateBookingStatus error:', err);
    res.status(500).json({ success: false, message: 'Failed to update booking status' });
  }
};

/** GET /api/admin/bookings */
exports.getAllBookings = async (req, res) => {
  try {
    const { status, date } = req.query;
    let query = `
      SELECT b.id, b.status, b.notes, b.created_at, b.cancelled_at,
             u.name AS user_name, u.email AS user_email,
             s.name AS service_name, s.price,
             ts.date, ts.start_time, ts.end_time
      FROM bookings b
      JOIN users u ON b.user_id = u.id
      JOIN services s ON b.service_id = s.id
      JOIN time_slots ts ON b.slot_id = ts.id
      WHERE 1=1`;
    const params = [];
    if (status) { query += ' AND b.status = ?'; params.push(status); }
    if (date) { query += ' AND ts.date = ?'; params.push(date); }
    query += ' ORDER BY ts.date DESC, ts.start_time DESC';

    const [bookings] = await db.query(query, params);
    res.json({ success: true, data: { bookings } });
  } catch (err) {
    console.error('getAllBookings error:', err);
    res.status(500).json({ success: false, message: 'Failed to fetch bookings' });
  }
};