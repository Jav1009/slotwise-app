const express    = require('express');
const router     = express.Router();
const { protect } = require('../middlewares/authMiddleware');
const { adminOnly }  = require('../middlewares/adminMiddleware');
const ctrl       = require('../controllers/serviceController');

// Public routes — no auth required
router.get('/',    ctrl.getAll);
router.get('/:id', ctrl.getOne);

// Admin-only routes
// protect ensures user is authenticated; adminOnly checks role
router.post('/',      protect, adminOnly, ctrl.create);
router.put('/:id',    protect, adminOnly, ctrl.update);
router.delete('/:id', protect, adminOnly, ctrl.softDelete);

module.exports = router;