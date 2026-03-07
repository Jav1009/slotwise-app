const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const {
    getMyNotifications,
    markAsRead,
    markAllAsRead,
    getUnreadCount
} = require('../controllers/notificationController');

// All notification routes require authentication
router.use(auth);

router.get('/', getMyNotifications);
router.get('/unread-count', getUnreadCount);
router.put('/:id/read', markAsRead);
router.put('/read-all', markAllAsRead);

module.exports = router;