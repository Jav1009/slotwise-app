// routes/serviceRoutes.js
//
// Changes from previous version:
//   • create + update: changed from adminOnly → staffOrAdmin
//     (staff can now create and edit services)
//   • delete: remains adminOnly (only admins can deactivate services)
//   • Added: GET /categories — returns distinct category list for filter chips

const express    = require('express');
const router     = express.Router();
const { protect } = require('../middlewares/authMiddleware');
const { adminOnly, staffOrAdmin }  = require('../middlewares/adminMiddleware');
const ctrl       = require('../controllers/serviceController');

// Public routes — no auth required
router.get('/categories', ctrl.getCategories);  // Must be before /:id
router.get('/',    ctrl.getAll);
router.get('/:id', ctrl.getOne);

// Admin or Staff routes
// protect ensures user is authenticated; adminOnly checks role
router.post('/',      protect, staffOrAdmin, ctrl.create);
router.put('/:id',    protect, staffOrAdmin, ctrl.update);

// Admin-only
router.delete('/:id', protect, adminOnly, ctrl.softDelete);

module.exports = router;