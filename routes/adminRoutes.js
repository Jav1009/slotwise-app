// routes/adminRoutes.js
const express  = require('express');
const router   = express.Router();
const { authMiddleware, adminOnly } = require('../middleware/auth');

// getStats and getAllBookings come from adminController
const { getStats, getAllBookings } = require('../controllers/adminController');

// updateBookingStatus comes from bookingController — it sends push notifications
const { updateBookingStatus } = require('../controllers/bookingController');

router.use(authMiddleware, adminOnly);

router.get('/stats',               getStats);
router.get('/bookings',            getAllBookings);
router.put('/bookings/:id/status', updateBookingStatus);

module.exports = router;