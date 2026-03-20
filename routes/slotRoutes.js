// routes/slotRoutes.js  — full replacement
const express = require('express');
const router = express.Router();
const slotController = require('../controllers/slotController');
const { authMiddleware, adminOnly } = require('../middleware/auth');

// Public/authenticated routes
router.get('/available/:serviceId', authMiddleware, slotController.getAvailableSlots);

// Admin routes
router.get('/',         authMiddleware, adminOnly, slotController.getAllSlots);
router.post('/',        authMiddleware, adminOnly, slotController.createSlot);
router.post('/bulk',    authMiddleware, adminOnly, slotController.bulkCreateSlots); // ← NEW
router.put('/:id',      authMiddleware, adminOnly, slotController.updateSlot);
router.delete('/:id',   authMiddleware, adminOnly, slotController.deleteSlot);

module.exports = router;