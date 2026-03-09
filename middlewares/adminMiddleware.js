// middleware/adminOnly.js
// Role guard — must be used AFTER auth middleware.


// WHY separate from auth.js?
//   auth.js checks "are you logged in?"
//   adminOnly.js checks "are you an admin?"
//   Some routes need auth but not admin (e.g. GET /bookings/my).
//   Admin routes need both: router.put('/slots', auth, adminOnly, controller)
// const adminOnly = (req, res, next) => {
//   if (req.user && req.user.role === 'admin') {
//     return next();
//   }
//   return res.status(403).json({ message: 'Admin access required.' });
// };

// module.exports = adminOnly;

// TWO GUARDS — use AFTER the `protect` middleware:
//
//   adminOnly     → role must be 'admin'
//                   Used for: user management, system settings, full override actions
//
//   staffOrAdmin  → role must be 'staff' OR 'admin'
//                   Used for: manage services, slots, bookings, view all bookings
//                   Admin inherits everything staff can do.
//
// Usage in routes:
//   router.get('/', protect, adminOnly,    ctrl.listUsers);
//   router.get('/', protect, staffOrAdmin, ctrl.getAllBookings);


// ─── Admin-Only Guard ─────────────────────────────────────────────────────────
// Must be used AFTER the `protect` middleware, which attaches req.user
// protect   → verifies JWT and fetches user (with role) from DB
// adminOnly → checks that req.user.role === 'admin'

exports.adminOnly = (req, res, next) => {
    if (!req.user) {
        // Should never reach here if protect ran first, but just in case
        res.status(401);
        return next(new Error('Not authenticated'));
    }

    if (req.user.role !== 'admin') {
        res.status(403);
        return next(new Error('Access denied: Admins only'));
    }

    next(); // Role confirmed — proceed to controller
};

// ─── Staff or Admin Guard ─────────────────────────────────────────────────────
// Allows both 'staff' and 'admin' roles through.
// Any route that business-side users (staff) need access to should use this.
exports.staffOrAdmin = (req, res, next) => {
    if (!req.user) {
        res.status(401);
        return next(new Error('Not authenticated'));
    }

    if (req.user.role !== 'staff' && req.user.role !== 'admin') {
        res.status(403);
        return next(new Error('Access denied: Staff or Admin only'));
    }

    next();
};


// alias for use in route files
// exports.adminOnly = exports.authMiddleware;  // named "protect" for clarity in routes
