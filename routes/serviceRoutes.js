const express = require('express');
const router = express.Router();
const { serviceValidation } = require('../middleware/validate');
const auth = require('../middleware/auth');
const adminOnly = require('../middleware/adminOnly');
const {
    getAllServices,
    getServiceById,
    createService,
    updateService,
    deleteService,
    getServiceStats,
    getServiceSlots
} = require('../controllers/serviceController');

// Public routes (no auth required for browsing)
router.get('/', getAllServices);
router.get('/stats', getServiceStats);
router.get('/:id', getServiceById);
router.get('/:id/slots', getServiceSlots);

// Admin only routes
router.post('/', auth, adminOnly, serviceValidation.create, createService);
router.put('/:id', auth, adminOnly, updateService);
router.delete('/:id', auth, adminOnly, deleteService);

module.exports = router;