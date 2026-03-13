// read-all must come before /:id
const express = require('express');
const router  = express.Router();

const {
    getAll,
    markAllRead,
    markRead,
    sendToUser,         // Send push notification to a specific user
    broadcastToAll,     // Broadcast push notification to ALL users (admin only)
    getPreferences,
    updatePreferences,
} = require('../controllers/notificationController');

const { protect }    = require('../middlewares/authMiddleware');  // renamed for clarity
const { adminOnly }    = require('../middlewares/adminMiddleware');   // Role check: admin only

// ── Notification list ─────────────────────────────────────────────────────────
router.get('/',           protect, getAll);        // GET /api/notifications  (Flutter default)
router.get('/get-all',           protect, getAll); // legacy alias

// ── Mark read ─────────────────────────────────────────────────────────────────
router.put('/read-all',   protect, markAllRead);  // PUT  /api/notifications/read-all
router.put('/:id/read',   protect, markRead);   // PUT  /api/notifications/:id/read

// ── User preferences ──────────────────────────────────────────────────────────
router.get('/preferences', protect, getPreferences);    // GET /api/notifications/preferences
router.put('/preferences', protect, updatePreferences); // PUT /api/notifications/preferences

// ─── Protected Routes ────────────────────────────────────────────────────────

// POST /api/notifications/send
// Body: { userId, title, body, data? }
// Sends a push notification to a specific user by their userId
// Requires: valid JWT (any role)
router.post('/send', protect, sendToUser);

// POST /api/notifications/broadcast
// Body: { title, body, data? }
// Sends a push notification to ALL users who have an fcm_token stored
// Requires: valid JWT + admin role
router.post('/broadcast', protect, adminOnly, broadcastToAll);

module.exports = router;