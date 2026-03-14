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
//
// Changes from previous version:
//   • createBooking: now also notifies the staff/admin who created the service
//     via FCM push (looks up services.created_by → users.fcm_token)
//   • Added: rescheduleBooking — moves booking to a new slot atomically
//   • All other logic (transactions, SELECT FOR UPDATE, cancel, status) unchanged

const pool = require('../config/db');
const { notifyBookingConfirmed, notifyBookingCancelled, notifyStatusUpdate, notifyStaffNewBooking } = require('./notificationController');

// ─────────────────────────────────────────────────────────────
// CREATE BOOKING
// POST /api/bookings
// Body: { service_id, slot_id, notes? }
// Protected — customer or any authenticated user
//
// Flow:
//   1. Lock slot row (SELECT FOR UPDATE) — prevents race conditions
//   2. Mark slot is_available = FALSE
//   3. Insert booking row
//   4. Insert notification for the customer
//   5. Notify customer via FCM
//   6. Notify the staff/admin who owns the service via FCM
// ─────────────────────────────────────────────────────────────
exports.createBooking = async (req, res, next) => {
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

    // Fetch service name and booking date for the notification
    const [services] = await conn.execute(
      'SELECT name, created_by FROM services WHERE id = ?',
      [service_id]
    );
    if (services.length === 0) {
      await conn.rollback();
      return res.status(404).json({ message: 'Service not found.' });
    }

    const [slotDetails] = await conn.execute(
      'SELECT slot_date FROM time_slots WHERE id = ?',
      [slot_id]
    );
    if (slotDetails.length === 0) {
      await conn.rollback();
      return res.status(404).json({ message: 'Slot not found.' });
    }

    const bookingId = result.insertId;
    const serviceName = services[0].name || 'Unknown Service';
    const bookingDate = slotDetails[0].slot_date || 'Unknown Date';
    const serviceOwner = services[0].created_by || null;

    // Create notification - In-app notification for the customer
    await conn.execute(
      'INSERT INTO notifications (user_id, booking_id, message) VALUES (?, ?, ?)',
      [user_id, bookingId, 'Your booking has been received and is pending confirmation.']
    );

    // Create notification - In-app notification for the admin/staff
    if (serviceOwner) {
      await conn.execute(
        'INSERT INTO notifications (user_id, booking_id, message) VALUES (?, ?, ?)',
        [serviceOwner, bookingId, `New booking: ${serviceName} on ${bookingDate} by .`]
      );
    }

    await conn.commit();

    // FCM: notify user
    await notifyBookingConfirmed(user_id, bookingId, serviceName, bookingDate);

    // FCM: notify staff/admin who owns the service (if created_by is set)
    if (serviceOwner) {
      await notifyStaffNewBooking(serviceOwner, bookingId, serviceName, bookingDate);
    }

    return res.status(201).json({
      message: 'Booking created successfully.',
      booking_id: bookingId
    });

  } catch (err) {
    await conn.rollback();
    console.error('[bookings create]', err);
    next(err)
    return res.status(500).json({ message: 'Booking failed. Please try again.' });
  } finally {
    conn.release(); // ALWAYS release back to pool
  }
};

// ─────────────────────────────────────────────────────────────
// GET MY BOOKINGS
// GET /api/bookings/my
// Returns all bookings for the authenticated user.
// WHERE b.user_id = ? ensures users ONLY see their own bookings
// ─────────────────────────────────────────────────────────────
exports.getMyBookings = async (req, res, next) => {
  const user_id = req.user.id;
  try {
    const [rows] = await pool.execute(
      `SELECT
         b.id, b.status, b.notes, b.created_at, b.updated_at,
         s.id   AS service_id,
         s.name AS service_name,
         s.price, s.image_url, s.category,
         t.id       AS slot_id,
         t.slot_date, t.start_time, t.end_time
       FROM   bookings   b
       JOIN   services   s ON b.service_id = s.id
       JOIN   time_slots t ON b.slot_id    = t.id
       WHERE  b.user_id = ?
       ORDER  BY t.slot_date DESC, t.start_time DESC`,
      [user_id]
    );
    // Wrap in consistent {status, data} shape — matches all other endpoints
    return res.status(200).json({status: 'success', data: rows});
  } catch (err) {
    console.error('[bookings myBookings]', err);
    next(err)
    return res.status(500).json({ message: 'Failed to fetch bookings.' });
  }
};

// ─────────────────────────────────────────────────────────────
// GET BOOKING BY ID
// GET /api/bookings/:id
// Customer can only see their own. Staff/admin can see any.
// ─────────────────────────────────────────────────────────────
exports.getBookingById = async (req, res, next) => {
  const { id } = req.params;
  const { role, id: userId } = req.user;

  try {
    const [rows] = await pool.execute(
      `SELECT
               b.id, b.status, b.notes, b.created_at, b.updated_at,
               b.user_id,
               CONCAT(u.first_name, ' ', u.last_name) AS customer_name,
               u.email AS customer_email,
               s.id   AS service_id,
               s.name AS service_name,
               s.price, s.image_url, s.category,
               t.id   AS slot_id,
               t.slot_date, t.start_time, t.end_time
             FROM   bookings   b
             JOIN   users      u ON b.user_id    = u.id
             JOIN   services   s ON b.service_id = s.id
             JOIN   time_slots t ON b.slot_id    = t.id
             WHERE  b.id = ?`,
      [id]
    );

    if (rows.length === 0) {
      res.status(404);
      throw new Error('Booking not found');
    }

    const booking = rows[0];

    // Customers can only view their own bookings
    if ((role === 'user' || role === 'customer') && booking.user_id !== userId) {
      res.status(403);
      throw new Error('Access denied');
    }

    return res.status(200).json({ status: 'success', data: booking });
  } catch (err) {
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────
// CANCEL BOOKING
// PUT /api/bookings/:id/cancel
// Customer can only cancel their own.
// ─────────────────────────────────────────────────────────────
exports.cancelBooking = async (req, res, next) => {
  const { id } = req.params;
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

    if (status === 'cancelled' || status === 'completed' || status === 'missed') {
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

    // Fetch service name and booking date for notification
    const [serviceRows] = await conn.execute('SELECT name, created_by FROM services WHERE id = ?', [service_id]);
    const serviceName = serviceRows[0].name;

    const [slotRows] = await conn.execute('SELECT slot_date FROM time_slots WHERE id = ?', [slot_id]);
    const bookingDate = slotRows[0].slot_date;

    const serviceOwner = serviceRows[0]?.created_by || null;

    // Create notification - In-app notification for the customer
    await conn.execute(
      'INSERT INTO notifications (user_id, booking_id, message) VALUES (?, ?, ?)',
      [user_id, id, 'Your booking has been cancelled and the slot has been freed.']
    );

    // Create notification - In-app notification for the admin/staff
    if (serviceOwner) {
      await conn.execute(
        'INSERT INTO notifications (user_id, booking_id, message) VALUES (?, ?, ?)',
        [serviceOwner, id, `A booking '${serviceName}' has been cancelled.\n${bookingDate}`]
      );
    }

    await conn.commit();

    // FCM: notify customer
    await notifyBookingCancelled(user_id, id, serviceName, bookingDate);

    // FCM: notify staff/admin who owns the service (if created_by is set)
    if (serviceOwner) {
      await notifyStaffNewBooking(serviceOwner, id, serviceName, bookingDate);
    }
    return res.json({ message: 'Booking cancelled successfully.' });

  } catch (err) {
    await conn.rollback();
    console.error('[bookings cancel]', err);
    next(err);
    return res.status(500).json({ message: 'Cancellation failed. Please try again.' });
  } finally {
    conn.release();
  }
};

// ─────────────────────────────────────────────────────────────
// RESCHEDULE BOOKING
// PUT /api/bookings/:id/reschedule
// Body: { new_slot_id }
// Customer can only reschedule their own pending/confirmed bookings.
//
// Flow:
//   1. Verify booking belongs to user and is not cancelled/completed
//   2. Lock new slot (SELECT FOR UPDATE) — ensure it's still available
//   3. Free old slot → mark new slot taken → update booking.slot_id
//   4. Notify customer of the change
// ─────────────────────────────────────────────────────────────
exports.rescheduleBooking = async (req, res, next) => {
  const { id } = req.params;
  const { new_slot_id } = req.body;
  const user_id = req.user.id;

  if (!new_slot_id) {
    res.status(400);
    return next(new Error('new_slot_id is required'));
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // Fetch current booking — must belong to this user
    const [bookingRows] = await conn.execute(
      'SELECT slot_id, service_id, status FROM bookings WHERE id = ? AND user_id = ?',
      [id, user_id]
    );

    if (bookingRows.length === 0) {
      await conn.rollback();
      res.status(404);
      throw new Error('Booking not found');
    }

    const { slot_id: old_slot_id, service_id, status } = bookingRows[0];

    if (status === 'cancelled' || status === 'completed' || status === 'missed') {
      await conn.rollback();
      res.status(400);
      throw new Error(`Cannot reschedule a booking with status '${status}'`);
    }

    if (old_slot_id === new_slot_id) {
      await conn.rollback();
      res.status(400);
      throw new Error('New slot is the same as the current slot');
    }

    // Lock the new slot
    const [newSlots] = await conn.execute(
      'SELECT id FROM time_slots WHERE id = ? AND service_id = ? AND is_available = TRUE FOR UPDATE',
      [new_slot_id, service_id]
    );

    if (newSlots.length === 0) {
      await conn.rollback();
      res.status(409);
      throw new Error('The selected slot is no longer available');
    }

    // ------SWAP SLOTS--------
    // Free old slot
    await conn.execute(
      'UPDATE time_slots SET is_available = TRUE WHERE id = ?', [old_slot_id]
    );

    // Mark new slot taken
    await conn.execute(
      'UPDATE time_slots SET is_available = FALSE WHERE id = ?', [new_slot_id]
    );

    // Update booking to point to new slot
    await conn.execute(
      'UPDATE bookings SET slot_id = ?, status = ? WHERE id = ?',
      [new_slot_id, 'pending', id] // Reset to pending after reschedule
    );

    // Fetch details for notification
    // Fetch service name and booking date for notification
    const [serviceRows] = await conn.execute('SELECT name FROM services WHERE id = ?', [service_id]);
    const serviceName = serviceRows[0].name;

    const [slotRows] = await conn.execute('SELECT slot_date, start_time FROM time_slots WHERE id = ?', [new_slot_id]);
    const newDate = slotRows[0].slot_date;
    const newTime = slotRows[0].start_time;

    const serviceOwner = serviceRows[0]?.created_by || null;

    await conn.execute(
      'INSERT INTO notifications (user_id, booking_id, message) VALUES (?, ?, ?)',
      [user_id, id, `Your booking has been rescheduled to ${newDate} at ${newTime}.`]
    );

    if (serviceOwner) {
      await conn.execute(
        'INSERT INTO notifications (user_id, booking_id, message) VALUES (?, ?, ?)',
        [serviceOwner, id, `A booking has been rescheduled to ${newDate} at ${newTime}.`]
      );
    }

    await conn.commit();

    // FCM: notify customer
    await notifyStatusUpdate(user_id, id, serviceName, newDate);

    // FCM: notify staff/admin who owns the service (if created_by is set)
    if (serviceOwner) {
      await notifyStaffNewBooking(serviceOwner, id, serviceName, newDate);
    }

    return res.status(200).json({
      status: 'success',
      message: 'Booking rescheduled successfully.',
      data: {
        booking_id: parseInt(id),
        new_slot_id,
        slot_date: newDate,
        start_time: newTime,
        service: serviceName
      }
    });
  } catch (err) {
    await conn.rollback();
    next(err);
  } finally {
    conn.release();
  }
};

// ─────────────────────────────────────────────────────────────
// GET ALL BOOKINGS
// GET /api/bookings?status=&date=&service_id=
// Staff or Admin — sees all bookings with filter support
// ─────────────────────────────────────────────────────────────
exports.getAllBookings = async (req, res, next) => {
  const { status, date, service_id } = req.query;
  const { role, id: requesterId } = req.user;
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

    // Staff can only see bookings for services THEY created
    // Admin sees everything
    if (role === 'staff') {
      sql += ' AND s.created_by = ?';
      params.push(requesterId);
    }

    if (status)     { sql += ' AND b.status = ?'; params.push(status); }
    if (date)       { sql += ' AND t.slot_date = ?'; params.push(date); }
    if (service_id) { sql += ' AND b.service_id = ?'; params.push(service_id); }

    sql += ' ORDER BY t.slot_date DESC, t.start_time DESC';

    const [rows] = await pool.execute(sql, params);
    return res.status(200).json({status:'success', data:rows});
  } catch (err) {
    console.error('[bookings getAll]', err);
    next(err)
    return res.status(500).json({ message: 'Failed to fetch bookings.' });
  }
};

// ─────────────────────────────────────────────────────────────
// UPDATE BOOKING STATUS
// PUT /api/bookings/:id/status  (staff or admin)
// Body: { status }
// ─────────────────────────────────────────────────────────────
exports.updateStatus = async (req, res, next) => {
  const { id } = req.params;
  const { status } = req.body;

  const allowed = ['pending', 'confirmed', 'completed', 'cancelled', 'missed'];
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
      missed:    'Your booking was marked as missed because the appointment time has passed.',
    };
    if (messages[status]) {
      await conn.execute(
        'INSERT INTO notifications (user_id, booking_id, message) VALUES (?, ?, ?)',
        [user_id, id, messages[status]]
      );
      // await conn.execute(
      //   'INSERT INTO notifications (user_id, booking_id, message) VALUES (?, ?, ?)',
      //   [{sender}, id, messages[status]]
      // );
    }

    // Fetch service name and booking date for notification
    const [serviceRows] = await conn.execute('SELECT name FROM services WHERE id = ?', [service_id]);
    const serviceName = serviceRows[0].name;

    const [slotRows] = await conn.execute('SELECT slot_date FROM time_slots WHERE id = ?', [slot_id]);
    const date = slotRows[0].slot_date;

    await conn.commit();
    await notifyStatusUpdate(user_id, id, serviceName, status);

    return res.json({ message: `Booking status updated to '${status}' for booking date ${date}.` });

  } catch (err) {
    await conn.rollback();
    console.error('[bookings updateStatus]', err);
    next(err)
    return res.status(500).json({ message: 'Failed to update status.' });
  } finally {
    conn.release();
  }
};