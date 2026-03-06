// IMPORTANT: /my must be defined BEFORE /:id routes
// otherwise Express treats 'my' as an :id parameter value
const express   = require('express');
const router    = express.Router();
const { protect }      = require('../middlewares/authMiddleware');
const { adminOnly } = require('../middlewares/adminMiddleware');
const ctrl      = require('../controllers/bookingController');

router.get('/my',         protect, ctrl.getMyBookings);
router.get('/',           protect, adminOnly, ctrl.getAllBookings);
router.post('/',          protect, ctrl.createBooking);
router.put('/:id/cancel', protect, ctrl.cancelBooking);
router.put('/:id/status', protect, adminOnly, ctrl.updateStatus);

module.exports = router;