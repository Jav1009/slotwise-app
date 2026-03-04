// routes/bookingRoutes.js
const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const { authMiddleware, adminOnly } = require('../middleware/auth');

// User routes (authenticated users only)
router.get('/me', authMiddleware, bookingController.getMyBookings);
router.post('/', authMiddleware, bookingController.createBooking);
router.put('/:id/cancel', authMiddleware, bookingController.cancelBooking);

// Admin routes
router.get('/admin/all', authMiddleware, adminOnly, bookingController.getAllBookings);
router.put('/admin/:id/status', authMiddleware, adminOnly, bookingController.updateBookingStatus);

module.exports = router;