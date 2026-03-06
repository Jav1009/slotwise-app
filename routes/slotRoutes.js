const express   = require('express');
const router    = express.Router();
const { protect }      = require('../middlewares/authMiddleware');
const { adminOnly } = require('../middlewares/adminMiddleware');
const ctrl      = require('../controllers/slotController');

router.get('/',       protect, ctrl.getSlots);
router.post('/',      protect, adminOnly, ctrl.createSlots);
router.put('/:id',    protect, adminOnly, ctrl.update);
router.delete('/:id', protect, adminOnly, ctrl.deleteSlot);

module.exports = router;