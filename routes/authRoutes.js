const express = require('express');
const router = express.Router();
const { authValidation } = require('../middleware/validate');
const auth = require('../middleware/auth');
const adminOnly = require('../middleware/adminOnly');
const {
    register,
    login,
    getProfile,
    updateProfile,
    getAllUsers
} = require('../controllers/authController');

// Public routes
router.post('/register', authValidation.register, register);
router.post('/login', authValidation.login, login);

// Protected routes
router.get('/me', auth, getProfile);
router.put('/me', auth, updateProfile);

// Admin only
router.get('/users', auth, adminOnly, getAllUsers);

module.exports = router;