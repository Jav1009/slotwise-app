const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const NotificationController = require('../controllers/notificationController');

// All routes require authentication
router.use(auth);

// Register FCM token
router.post('/register-token', NotificationController.registerToken);

// Remove FCM token
router.post('/remove-token', NotificationController.removeToken);

// Get user's devices
router.get('/devices', NotificationController.getUserDevices);

module.exports = router;
