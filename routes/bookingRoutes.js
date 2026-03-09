// routes/bookingRoutes.js
//
// Changes from previous version:
//   • GET /    (all bookings): changed adminOnly → staffOrAdmin
//   • PUT /:id/status: changed adminOnly → staffOrAdmin
//   • Added: PUT /:id/reschedule — customer can reschedule their own booking
//   • Added: GET /:id — get single booking detail (customer sees own, staff/admin sees all)
//
// IMPORTANT: /my must be defined BEFORE /:id routes
// otherwise Express treats 'my' as an :id parameter value

const express   = require('express');
const router    = express.Router();
const { protect }      = require('../middlewares/authMiddleware');
const { staffOrAdmin } = require('../middlewares/adminMiddleware');
const ctrl      = require('../controllers/bookingController');

// customer
router.get('/my',         protect, ctrl.getMyBookings);
router.post('/',          protect, ctrl.createBooking);
router.put('/:id/cancel', protect, ctrl.cancelBooking);
router.put('/:id/reschedule',  protect, ctrl.rescheduleBooking);  // NEW

// ── Single booking detail — customers see own, staff/admin see all ────────────
router.get('/:id',             protect, ctrl.getBookingById);     // NEW

// ── Staff or Admin routes ────────────────────────────────────────────────────
router.get('/',           protect, staffOrAdmin, ctrl.getAllBookings);
router.put('/:id/status', protect, staffOrAdmin, ctrl.updateStatus);

module.exports = router;