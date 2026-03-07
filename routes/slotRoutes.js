const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const adminOnly = require('../middleware/adminOnly');
const {
    getAvailableSlots,
    createSlot,
    createBatchSlots,
    updateSlot,
    deleteSlot,
    getSlotsByDateRange
} = require('../controllers/slotController');

// Public route for checking availability
router.get('/available', getAvailableSlots);
router.get('/range', getSlotsByDateRange);

// Admin only routes
router.post('/', auth, adminOnly, createSlot);
router.post('/batch', auth, adminOnly, createBatchSlots);
router.put('/:id', auth, adminOnly, updateSlot);
router.delete('/:id', auth, adminOnly, deleteSlot);

module.exports = router;