// routes/authRoutes.js
// Authentication route definitions
// Routes define the endpoints, controllers contain the logic

const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authMiddleware } = require('../middleware/auth');

// Firebase-based authentication (PRIMARY)
router.post('/register', authController.register);
router.post('/login', authController.login);

// Legacy password-based authentication (for testing/backwards compatibility)
router.post('/login-password', authController.loginWithPassword);

// Protected routes (authentication required)
router.get('/me', authMiddleware, authController.getCurrentUser);

module.exports = router;