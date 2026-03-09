// routes/slotRoutes.js
//
// Changes from previous version:
//   • create, update, delete: changed from adminOnly → staffOrAdmin
//     (staff can now manage their own service slots)

const express   = require('express');
const router    = express.Router();
const { protect }      = require('../middlewares/authMiddleware');
const { staffOrAdmin } = require('../middlewares/adminMiddleware');
const ctrl      = require('../controllers/slotController');

router.get('/',       protect, ctrl.getSlots);
router.post('/',      protect, staffOrAdmin, ctrl.createSlots);
router.put('/:id',    protect, staffOrAdmin, ctrl.update);
router.delete('/:id', protect, staffOrAdmin, ctrl.deleteSlot);

module.exports = router;