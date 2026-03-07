// routes/adminRoutes.js
const express = require('express');
const router  = express.Router();
const { authMiddleware, adminOnly } = require('../middleware/auth');
// ✅ FIXED: 'authenticate' does not exist — correct export name is 'authMiddleware'

const {
  getStats,
  getAllBookings,
  updateBookingStatus,
} = require('../controllers/adminController');

// Apply auth guard to every route in this file
router.use(authMiddleware, adminOnly);

router.get('/stats',                getStats);
router.get('/bookings',             getAllBookings);
router.put('/bookings/:id/status',  updateBookingStatus);

module.exports = router;