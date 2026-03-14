// middleware/optionalAuth.js
//
// Like `protect`, but does NOT reject requests without a token.
// If a valid token is present → attaches req.user (id, email, role).
// If no token (public/customer request) → req.user stays undefined, continues.
//
// Used on routes that are public by default but need role-scoping when
// a staff/admin user calls them (e.g. GET /api/services).

const jwt  = require('jsonwebtoken');
const pool = require('../config/db');

exports.optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      // No token — treat as anonymous/public request
      return next();
    }

    const token = authHeader.split(' ')[1];
    if (!token) return next();

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (_) {
      // Invalid/expired token on a public route — just skip, don't reject
      return next();
    }

    const [rows] = await pool.query(
      'SELECT id, email, role, is_active FROM users WHERE id = ? LIMIT 1',
      [decoded.user_id]
    );

    if (rows.length > 0 && rows[0].is_active === 1) {
      req.user = { id: rows[0].id, email: rows[0].email, role: rows[0].role };
    }

    next();
  } catch (_) {
    // Never block the request on optional auth errors
    next();
  }
};