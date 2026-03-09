// const express = require('express');
// const router  = express.Router();
// const auth    = require('../middlewares/auth');
// const ctrl    = require('../controllers/authController');

// router.post('/register', ctrl.register);
// router.post('/login',    ctrl.login);
// router.get('/me',        auth, ctrl.getMe);

// module.exports = router;

// routes/authRoutes.js

const express = require('express');
const router = express.Router();

const {
    register,
    login,
    logout,
    forgotPassword,
    resetPassword,
    updateFcmToken,          // NEW: stores FCM device token after login
    getMe
} = require('../controllers/authController');

const { protect } = require('../middlewares/authMiddleware');  // JWT verification (alias to authMiddleware)
// const { adminOnly }    = require('../middlewares/adminMiddleware');   // Role check: admin only

// ─── Public Routes (no token required) ──────────────────────────────────────

// POST /api/auth/register
// Body: { firstName, lastName, email, password }
router.post('/register', register);

// POST /api/auth/login
// Body: { email, password }
router.post('/login', login);

// POST /api/auth/forgot-password
// Body: { email }
// Sends 6-digit OTP to user's email
router.post('/forgot-password', forgotPassword);

// POST /api/auth/reset-password
// Body: { email, otp, newPassword }
// Verifies OTP and updates password_hash in DB
router.post('/reset-password', resetPassword);

// ─── Protected Routes (valid JWT required) ───────────────────────────────────

router.get('/me', protect, getMe);

// POST /api/auth/logout
// Clears fcm_token in DB for this user
// middleware must run before the handler; protect will set req.user
router.post('/logout', protect, logout);

// PUT /api/auth/fcm-token
// Body: { fcmToken }
// Called by Flutter after login to store FCM device token
// Also called automatically when token refreshes (FirebaseMessaging.onTokenRefresh)
router.put('/fcm-token', protect, updateFcmToken);

module.exports = router;