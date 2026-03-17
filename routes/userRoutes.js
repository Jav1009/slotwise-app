// routes/userRoutes.js
const express    = require('express');
const router     = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { updateProfile, saveFcmToken } = require('../controllers/userController');

router.put('/profile',   authMiddleware, updateProfile);
router.post('/fcm-token', authMiddleware, saveFcmToken);

module.exports = router;