// middleware/auth.js
// JWT verification middleware.
//
// middleware/authMiddleware.js
// Protects routes by verifying JWT tokens and confirming the user exists and is active.
// Attaches req.user = { id, email, role } for use in downstream controllers.
//
// HOW IT WORKS:
//   1. Reads the Authorization header, expects "Bearer <token>"
//   2. Extracts and verifies the token using JWT_SECRET
//   3. On success, attaches decoded payload to req.user
//   4. On failure, returns 401 — request goes no further


const jwt = require('jsonwebtoken');
const pool = require('../config/db');

// ─────────────────────────────────────────────────────────────
// AUTH MIDDLEWARE
// Usage: router.get('/protected', authMiddleware, controller)
//
// What it checks (in order):
//   1. Authorization header exists and starts with 'Bearer '
//   2. Token string is present after 'Bearer '
//   3. JWT signature is valid and token is not expired
//   4. user_id from the JWT payload maps to a real user in the DB
//   5. That user's is_active = 1 (not deactivated)
//
// On success: attaches req.user = { id, email, role } and calls next()
// On failure: sets appropriate HTTP status and passes error to errorHandler
// ─────────────────────────────────────────────────────────────
// we export the middleware under two names for backwards compatibility
// `authMiddleware` (used internally) and `protect` (more semantic when used in routes)
exports.authMiddleware = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        // Step 1: Header must exist and follow "Bearer <token>" format
        // Any other format (e.g., missing "Bearer ", just the token string) is rejected
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            res.status(401);
            throw new Error('No token provided. Authorization denied.');
        }

        // Step 2: Extract the token string from "Bearer <token>"
        // split(' ')[1] gives everything after the space
        const token = authHeader.split(' ')[1];

        if (!token) {
            res.status(401);
            throw new Error('Token missing. Authorization denied.');
        }

        // Step 3: Verify the JWT signature and expiry against JWT_SECRET from .env
        // jwt.verify throws JsonWebTokenError (invalid sig) or TokenExpiredError (expired)
        // We wrap this in its own try-catch to give a consistent error message
        let decoded;
        try {
            decoded = jwt.verify(token, process.env.JWT_SECRET);
            // decoded = { user_id: <int>, iat: <timestamp>, exp: <timestamp> }
        } catch (jwtError) {
            res.status(401);
            // Single message for both expired and invalid tokens — don't hint which one
            throw new Error('Invalid or expired token. Please log in again.');
        }

        const userId = decoded.user_id;

        // Step 4: Confirm the user still exists in the DB
        // Also fetch role — needed by adminMiddleware and can be attached to req.user
        // Also fetch fcm_token — not used here but available to controllers if needed
        const [userRows] = await pool.query(
            `SELECT id, email, role, is_active
             FROM users
             WHERE id = ?
             LIMIT 1`,
            [userId]
        );

        if (userRows.length === 0) {
            // User was deleted after the token was issued
            res.status(401);
            throw new Error('Account no longer exists.');
        }

        const user = userRows[0];

        // Step 5: Confirm account is still active
        // is_active = 0 means the account was deactivated by an admin
        if (user.is_active !== 1) {
            res.status(403);
            throw new Error('Account is deactivated. Please contact support.');
        }

        // Step 6: Attach user to the request object for downstream use
        // Controllers can access req.user.id, req.user.email, req.user.role
        req.user = {
            id: user.id,
            email: user.email,
            role: user.role   // Used by adminMiddleware for role-based access control
        };

        next(); // Token is valid, user exists and is active — proceed to the controller
    } catch (error) {
        next(error); // All errors flow to errorMiddleware.js → errorHandler
    }
};

// alias for use in route files
exports.protect = exports.authMiddleware;  // named "protect" for clarity in routes
