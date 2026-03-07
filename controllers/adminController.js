// controllers/adminController.js
const db = require('../config/db');

// ─────────────────────────────────────────────────────────────
// GET /api/admin/stats
// ─────────────────────────────────────────────────────────────
exports.getStats = async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];

    // ✅ FIXED: removed .promise() — db is already a promise pool
    const [[{ todayBookings }]] = await db.query(
      `SELECT COUNT(*) AS todayBookings FROM bookings WHERE DATE(created_at) = ?`,
      [today]
    );

    const [[{ totalBookings }]] = await db.query(
      `SELECT COUNT(*) AS totalBookings FROM bookings`
    );

    const [[{ totalRevenue }]] = await db.query(
      `SELECT COALESCE(SUM(s.price), 0) AS totalRevenue
       FROM bookings b
       JOIN services s ON b.service_id = s.id
       WHERE b.status = 'completed'`
    );

    const [[{ activeServices }]] = await db.query(
      `SELECT COUNT(*) AS activeServices FROM services WHERE is_active = 1`
    );

    const [[{ pendingBookings }]] = await db.query(
      `SELECT COUNT(*) AS pendingBookings FROM bookings WHERE status = 'pending'`
    );

    const [popularServices] = await db.query(
      `SELECT s.name, COUNT(b.id) AS bookingCount
       FROM services s
       LEFT JOIN bookings b ON b.service_id = s.id
       WHERE s.is_active = 1
       GROUP BY s.id, s.name
       ORDER BY bookingCount DESC
       LIMIT 5`
    );

    res.json({
      success: true,
      data: {
        todayBookings,
        totalBookings,
        totalRevenue: parseFloat(totalRevenue),
        activeServices,
        pendingBookings,
        popularServices,
      },
    });
  } catch (err) {
    console.error('getStats error:', err);
    res.status(500).json({ success: false, message: 'Failed to fetch stats' });
  }
};

// ─────────────────────────────────────────────────────────────
// GET /api/admin/bookings?status=pending&date=YYYY-MM-DD
// ─────────────────────────────────────────────────────────────
exports.getAllBookings = async (req, res) => {
  try {
    const { status, date } = req.query;

    let query = `
      SELECT
        b.id, b.status, b.notes, b.created_at,
        u.name  AS customerName,
        u.email AS customerEmail,
        s.name  AS serviceName,
        s.price,
        sl.date,
        sl.start_time,
        sl.end_time
      FROM bookings b
      JOIN users      u  ON b.user_id    = u.id
      JOIN services   s  ON b.service_id = s.id
      JOIN time_slots sl ON b.slot_id    = sl.id
      WHERE 1=1
    `;
    // ✅ FIXED: 'slots' → 'time_slots' (matches actual table name)

    const params = [];

    if (status) {
      query += ' AND b.status = ?';
      params.push(status);
    }
    if (date) {
      query += ' AND sl.date = ?';
      params.push(date);
    }

    query += ' ORDER BY sl.date DESC, sl.start_time ASC';

    // ✅ FIXED: db.query() instead of db.promise().query()
    const [bookings] = await db.query(query, params);
    res.json({ success: true, data: bookings });
  } catch (err) {
    console.error('getAllBookings error:', err);
    res.status(500).json({ success: false, message: 'Failed to fetch bookings' });
  }
};

// ─────────────────────────────────────────────────────────────
// PUT /api/admin/bookings/:id/status
// ─────────────────────────────────────────────────────────────
exports.updateBookingStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const validStatuses = ['pending', 'confirmed', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status value' });
    }

    // Free the slot if cancelling so it becomes bookable again
    if (status === 'cancelled') {
      // ✅ FIXED: db.query() instead of db.promise().query()
      const [[booking]] = await db.query(
        'SELECT slot_id FROM bookings WHERE id = ?',
        [id]
      );
      if (booking) {
        // ✅ FIXED: 'slots' → 'time_slots'
        await db.query(
          'UPDATE time_slots SET is_available = 1 WHERE id = ?',
          [booking.slot_id]
        );
      }
    }

    // ✅ FIXED: db.query() instead of db.promise().query()
    const [result] = await db.query(
      'UPDATE bookings SET status = ? WHERE id = ?',
      [status, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    res.json({ success: true, message: `Booking status updated to ${status}` });
  } catch (err) {
    console.error('updateBookingStatus error:', err);
    res.status(500).json({ success: false, message: 'Failed to update booking status' });
  }
};