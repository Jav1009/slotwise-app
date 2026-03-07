const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const adminOnly = require('../middleware/adminOnly');
const {
    getAllBookings,
    updateBookingStatus,
    getDashboardStats,
    getBookingAnalytics
} = require('../controllers/adminController');

// All admin routes require authentication and admin role
router.use(auth, adminOnly);

router.get('/bookings', getAllBookings);
router.get('/dashboard', getDashboardStats);
router.get('/analytics', getBookingAnalytics);
router.put('/bookings/:id/status', updateBookingStatus);

module.exports = router;