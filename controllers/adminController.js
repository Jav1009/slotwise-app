// controllers/adminController.js

const db = require('../config/db');

// ─────────────────────────────────────────────────────────────
// GET /api/admin/stats?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
//
// IMPORTANT: All date filtering is on b.created_at (when the
// booking was MADE), NOT sl.date (when the appointment is
// scheduled). This is what "bookings in a period" means for
// analytics — it answers "how many bookings were created
// during this window?" not "how many appointments are
// scheduled during this window?"
// ─────────────────────────────────────────────────────────────
exports.getStats = async (req, res) => {
  try {
    const { start_date, end_date } = req.query;
    const hasRange = start_date && end_date;

    // Filter on booking creation date — no JOIN to time_slots needed
    const createdFilter = hasRange
      ? `AND DATE(b.created_at) BETWEEN ? AND ?`
      : '';
    const rangeParams = hasRange ? [start_date, end_date] : [];

    // ── Today's bookings (always today, unaffected by range) ───────────
    const [[{ todayBookings }]] = await db.query(
      `SELECT COUNT(*) AS todayBookings
       FROM bookings
       WHERE DATE(created_at) = CURDATE()`
    );

    // ── Pending bookings within range ──────────────────────────────────
    const [[{ pendingBookings }]] = await db.query(
      `SELECT COUNT(*) AS pendingBookings
       FROM bookings b
       WHERE b.status = 'pending' ${createdFilter}`,
      rangeParams
    );

    // ── Confirmed/completed bookings within range ──────────────────────
    const [[{ confirmedBookings }]] = await db.query(
      `SELECT COUNT(*) AS confirmedBookings
       FROM bookings b
       WHERE b.status IN ('confirmed','completed') ${createdFilter}`,
      rangeParams
    );

    // ── Cancelled bookings within range ───────────────────────────────
    const [[{ cancelledBookings }]] = await db.query(
      `SELECT COUNT(*) AS cancelledBookings
       FROM bookings b
       WHERE b.status = 'cancelled' ${createdFilter}`,
      rangeParams
    );

    // ── Total bookings within range ────────────────────────────────────
    const [[{ totalBookings }]] = await db.query(
      `SELECT COUNT(*) AS totalBookings
       FROM bookings b
       WHERE 1=1 ${createdFilter}`,
      rangeParams
    );

    // ── Confirmed revenue within range ─────────────────────────────────
    const [[{ totalRevenue }]] = await db.query(
      `SELECT COALESCE(SUM(s.price), 0) AS totalRevenue
       FROM bookings b
       JOIN services s ON b.service_id = s.id
       WHERE b.status IN ('confirmed', 'completed') ${createdFilter}`,
      rangeParams
    );

    // ── Pending revenue: actual sum of pending booking prices ──────────
    const [[{ pendingRevenue }]] = await db.query(
      `SELECT COALESCE(SUM(s.price), 0) AS pendingRevenue
       FROM bookings b
       JOIN services s ON b.service_id = s.id
       WHERE b.status = 'pending' ${createdFilter}`,
      rangeParams
    );

    // ── Popular services within range ──────────────────────────────────
    const [popularServices] = await db.query(
      `SELECT
         s.name,
         COUNT(b.id) AS booking_count
       FROM services s
       JOIN bookings b ON b.service_id = s.id
       WHERE b.status != 'cancelled' ${createdFilter}
       GROUP BY s.id, s.name
       ORDER BY booking_count DESC
       LIMIT 5`,
      rangeParams
    );

    res.json({
      success: true,
      data: {
        todayBookings,
        pendingBookings,
        confirmedBookings,
        cancelledBookings,
        totalBookings,
        totalRevenue,
        pendingRevenue,
        popularServices,
        dateRange: hasRange ? { start: start_date, end: end_date } : null,
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
    if (status) { query += ' AND b.status = ?'; params.push(status); }
    if (date)   { query += ' AND sl.date = ?';  params.push(date); }
    query += ' ORDER BY sl.date DESC, sl.start_time ASC';

    const [bookings] = await db.query(query, params);
    res.json({ success: true, data: { bookings } });
  } catch (err) {
    console.error('getAllBookings error:', err);
    res.status(500).json({ success: false, message: 'Failed to fetch bookings' });
  }
};