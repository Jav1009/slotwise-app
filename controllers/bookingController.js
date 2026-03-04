// controllers/bookingController.js
// THIS IS THE MOST CRITICAL CONTROLLER - handles booking conflicts
// Using exports.functionName pattern

const db = require('../config/db');

/**
 * Get current user's bookings
 * GET /api/bookings/me
 */
exports.getMyBookings = async (req, res) => {
  try {
    const userId = req.user.id;

    const [bookings] = await db.query(
      `SELECT 
        b.id,
        b.status,
        b.notes,
        b.created_at,
        b.cancelled_at,
        s.name as service_name,
        s.duration_minutes,
        s.price,
        ts.date,
        ts.start_time,
        ts.end_time
      FROM bookings b
      JOIN services s ON b.service_id = s.id
      JOIN time_slots ts ON b.slot_id = ts.id
      WHERE b.user_id = ?
      ORDER BY ts.date DESC, ts.start_time DESC`,
      [userId]
    );

    res.json({
      success: true,
      data: { bookings }
    });
  } catch (error) {
    console.error('Get bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch bookings'
    });
  }
};

/**
 * Create new booking with conflict detection
 * POST /api/bookings
 * 
 * THIS IS THE MOST IMPORTANT FUNCTION IN YOUR APP
 * Viva question: "How do you prevent double-bookings?"
 */
exports.createBooking = async (req, res) => {
  // Start a database transaction
  // This ensures atomicity - either everything succeeds or nothing changes
  const connection = await db.getConnection();
  
  try {
    await connection.beginTransaction();

    const { service_id, slot_id, notes } = req.body;
    const userId = req.user.id;

    // Validation
    if (!service_id || !slot_id) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Service and slot are required'
      });
    }

    // CRITICAL STEP 1: Check if slot exists and is available
    // Use FOR UPDATE to lock this row - prevents concurrent bookings
    const [slots] = await connection.query(
      'SELECT * FROM time_slots WHERE id = ? FOR UPDATE',
      [slot_id]
    );

    if (slots.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: 'Time slot not found'
      });
    }

    const slot = slots[0];

    if (!slot.is_available) {
      await connection.rollback();
      return res.status(409).json({
        success: false,
        message: 'This time slot is no longer available'
      });
    }

    // CRITICAL STEP 2: Double-check no active booking exists for this slot
    // Extra safety layer
    const [existingBookings] = await connection.query(
      `SELECT id FROM bookings 
       WHERE slot_id = ? AND status IN ('pending', 'confirmed')`,
      [slot_id]
    );

    if (existingBookings.length > 0) {
      await connection.rollback();
      return res.status(409).json({
        success: false,
        message: 'Booking conflict detected. Please select another slot.'
      });
    }

    // CRITICAL STEP 3: Create the booking
    const [bookingResult] = await connection.query(
      `INSERT INTO bookings (user_id, service_id, slot_id, status, notes)
       VALUES (?, ?, ?, 'pending', ?)`,
      [userId, service_id, slot_id, notes || null]
    );

    // CRITICAL STEP 4: Mark slot as unavailable
    await connection.query(
      'UPDATE time_slots SET is_available = FALSE WHERE id = ?',
      [slot_id]
    );

    // STEP 5: Create notification
    await connection.query(
      `INSERT INTO notifications (user_id, booking_id, message, type)
       VALUES (?, ?, ?, ?)`,
      [userId, bookingResult.insertId, 'Your booking has been created and is pending confirmation.', 'booking_created']
    );

    // Commit transaction - all changes are now permanent
    await connection.commit();

    // Fetch complete booking details to return
    const [newBooking] = await db.query(
      `SELECT 
        b.id,
        b.status,
        b.notes,
        b.created_at,
        s.name as service_name,
        s.price,
        ts.date,
        ts.start_time,
        ts.end_time
      FROM bookings b
      JOIN services s ON b.service_id = s.id
      JOIN time_slots ts ON b.slot_id = ts.id
      WHERE b.id = ?`,
      [bookingResult.insertId]
    );

    res.status(201).json({
      success: true,
      message: 'Booking created successfully',
      data: { booking: newBooking[0] }
    });

  } catch (error) {
    // Rollback on any error
    await connection.rollback();
    console.error('Create booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create booking'
    });
  } finally {
    connection.release();
  }
};

/**
 * Cancel own booking
 * PUT /api/bookings/:id/cancel
 */
exports.cancelBooking = async (req, res) => {
  const connection = await db.getConnection();
  
  try {
    await connection.beginTransaction();

    const { id } = req.params;
    const userId = req.user.id;

    // Check if booking exists and belongs to user
    const [bookings] = await connection.query(
      'SELECT * FROM bookings WHERE id = ? AND user_id = ? FOR UPDATE',
      [id, userId]
    );

    if (bookings.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    const booking = bookings[0];

    // Can only cancel pending or confirmed bookings
    if (!['pending', 'confirmed'].includes(booking.status)) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'This booking cannot be cancelled'
      });
    }

    // Update booking status
    await connection.query(
      'UPDATE bookings SET status = ?, cancelled_at = NOW() WHERE id = ?',
      ['cancelled', id]
    );

    // Make slot available again
    await connection.query(
      'UPDATE time_slots SET is_available = TRUE WHERE id = ?',
      [booking.slot_id]
    );

    // Create notification
    await connection.query(
      `INSERT INTO notifications (user_id, booking_id, message, type)
       VALUES (?, ?, ?, ?)`,
      [userId, id, 'Your booking has been cancelled.', 'booking_cancelled']
    );

    await connection.commit();

    res.json({
      success: true,
      message: 'Booking cancelled successfully'
    });

  } catch (error) {
    await connection.rollback();
    console.error('Cancel booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to cancel booking'
    });
  } finally {
    connection.release();
  }
};

/**
 * Get all bookings (Admin only)
 * GET /api/admin/bookings
 */
exports.getAllBookings = async (req, res) => {
  try {
    const { status, date } = req.query;

    let query = `
      SELECT 
        b.id,
        b.status,
        b.notes,
        b.created_at,
        b.cancelled_at,
        u.name as user_name,
        u.email as user_email,
        s.name as service_name,
        s.price,
        ts.date,
        ts.start_time,
        ts.end_time
      FROM bookings b
      JOIN users u ON b.user_id = u.id
      JOIN services s ON b.service_id = s.id
      JOIN time_slots ts ON b.slot_id = ts.id
      WHERE 1=1
    `;

    const params = [];

    if (status) {
      query += ' AND b.status = ?';
      params.push(status);
    }

    if (date) {
      query += ' AND ts.date = ?';
      params.push(date);
    }

    query += ' ORDER BY ts.date DESC, ts.start_time DESC';

    const [bookings] = await db.query(query, params);

    res.json({
      success: true,
      data: { bookings }
    });
  } catch (error) {
    console.error('Get all bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch bookings'
    });
  }
};

/**
 * Update booking status (Admin only)
 * PUT /api/admin/bookings/:id/status
 */
exports.updateBookingStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const validStatuses = ['pending', 'confirmed', 'cancelled', 'completed'];
    
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status'
      });
    }

    const [result] = await db.query(
      'UPDATE bookings SET status = ? WHERE id = ?',
      [status, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Get user_id for notification
    const [bookings] = await db.query(
      'SELECT user_id FROM bookings WHERE id = ?',
      [id]
    );

    // Create notification
    await db.query(
      `INSERT INTO notifications (user_id, booking_id, message, type)
       VALUES (?, ?, ?, ?)`,
      [bookings[0].user_id, id, `Your booking status has been updated to ${status}.`, 'status_update']
    );

    res.json({
      success: true,
      message: 'Booking status updated successfully'
    });
  } catch (error) {
    console.error('Update booking status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update booking status'
    });
  }
};