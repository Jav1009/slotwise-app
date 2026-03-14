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
const { optionalAuth }  = require('../middlewares/optionalAuth');
const ctrl       = require('../controllers/serviceController');

// Public routes — optionalAuth attaches req.user when a token IS present
// (so staff GET /services only sees their own, customers see all active)
router.get('/categories', optionalAuth, ctrl.getCategories);  // Must be before /:id
router.get('/', optionalAuth,   ctrl.getAll);
router.get('/:id', optionalAuth, ctrl.getOne);

// Admin or Staff routes
// protect ensures user is authenticated; adminOnly checks role
router.post('/',      protect, staffOrAdmin, ctrl.create);
router.put('/:id',    protect, staffOrAdmin, ctrl.update);

// Admin-only
router.delete('/:id', protect, adminOnly, ctrl.softDelete);

module.exports = router;