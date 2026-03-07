const express = require('express');
const router = express.Router();
const { bookingValidation } = require('../middleware/validate');
const auth = require('../middleware/auth');
const {
    createBooking,
    getMyBookings,
    getBookingById,
    cancelBooking,
    getUpcomingBookings,
    getMyStats
} = require('../controllers/bookingController');

// All booking routes require authentication
router.use(auth);

router.get('/my', getMyBookings);
router.get('/upcoming', getUpcomingBookings);
router.get('/stats', getMyStats);
router.get('/:id', getBookingById);
router.post('/', bookingValidation.create, createBooking);
router.put('/:id/cancel', cancelBooking);

module.exports = router;