// routes/serviceRoutes.js
const express = require('express');
const router = express.Router();
const serviceController = require('../controllers/serviceController');
const { authMiddleware, adminOnly } = require('../middleware/auth');

// Public routes
router.get('/', serviceController.getAllServices);
router.get('/:id', serviceController.getServiceById);

// Admin-only routes
router.post('/', authMiddleware, adminOnly, serviceController.createService);
router.put('/:id', authMiddleware, adminOnly, serviceController.updateService);
router.delete('/:id', authMiddleware, adminOnly, serviceController.deleteService);

module.exports = router;