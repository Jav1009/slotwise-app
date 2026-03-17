// controllers/adminController.js
const db = require('../config/db');

// ─────────────────────────────────────────────────────────────
// GET /api/admin/stats
// ─────────────────────────────────────────────────────────────
exports.getStats = async (req, res) => {
  try {
    const [[{ todayBookings }]] = await db.query(
      `SELECT COUNT(*) AS todayBookings
       FROM bookings
       WHERE DATE(created_at) = CURDATE()`
    );

    const [[{ pendingBookings }]] = await db.query(
      `SELECT COUNT(*) AS pendingBookings
       FROM bookings
       WHERE status = 'pending'`
    );

    const [[{ totalBookings }]] = await db.query(
      `SELECT COUNT(*) AS totalBookings FROM bookings`
    );

    const [[{ totalRevenue }]] = await db.query(
      `SELECT COALESCE(SUM(s.price), 0) AS totalRevenue
       FROM bookings b
       JOIN services s ON b.service_id = s.id
       WHERE b.status IN ('confirmed', 'completed')`
    );

    const [popularServices] = await db.query(
      `SELECT
         s.name,
         COALESCE(COUNT(b.id), 0) AS booking_count
       FROM services s
       LEFT JOIN bookings b
         ON b.service_id = s.id
        AND b.status != 'cancelled'
       GROUP BY s.id, s.name
       ORDER BY booking_count DESC
       LIMIT 5`
    );

    res.json({
      success: true,
      data: {
        todayBookings,
        pendingBookings,
        totalBookings,
        totalRevenue,
        popularServices,
      },
    });
  } catch (error) {
    console.error('getStats error:', error);
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
        b.id,
        b.status,
        b.notes,
        b.created_at,
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

    const [bookings] = await db.query(query, params);

    // Return as { data: { bookings: [...] } } — consistent with bookingController
    res.json({ success: true, data: { bookings } });
  } catch (err) {
    console.error('getAllBookings error:', err);
    res.status(500).json({ success: false, message: 'Failed to fetch bookings' });
  }
};