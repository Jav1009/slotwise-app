// controllers/authController.js
// Hybrid authentication: Firebase Auth + MySQL + JWT
// Using exports.functionName pattern

const bcrypt = require('bcryptjs');
const db = require('../config/db');
const { generateToken } = require('../utils/jwt');
const { verifyFirebaseToken } = require('../config/firebase');

/**
 * Register a new user
 * POST /api/auth/register
 * 
 * FLOW:
 * 1. Flutter creates user in Firebase Auth
 * 2. Flutter gets Firebase ID token
 * 3. Flutter sends token + user details to this endpoint
 * 4. Backend verifies token, stores user in MySQL, returns JWT
 */
exports.register = async (req, res) => {
  try {
    const { firebase_token, name, email } = req.body;

    // Validation
    if (!firebase_token || !name || !email) {
      return res.status(400).json({
        success: false,
        message: 'Firebase token, name, and email are required'
      });
    }

    // STEP 1: Verify Firebase token
    let firebaseUser;
    try {
      firebaseUser = await verifyFirebaseToken(firebase_token);
    } catch (error) {
      return res.status(401).json({
        success: false,
        message: 'Invalid Firebase token'
      });
    }

    // STEP 2: Check if Firebase email matches provided email
    if (firebaseUser.email !== email) {
      return res.status(400).json({
        success: false,
        message: 'Email mismatch'
      });
    }

    // STEP 3: Check if user already exists in MySQL
    const [existingUsers] = await db.query(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );

    if (existingUsers.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Email already registered'
      });
    }

    // STEP 4: Store user in MySQL
    // No password needed - Firebase handles authentication
    const [result] = await db.query(
      'INSERT INTO users (name, email, password_hash, role) VALUES (?, ?, ?, ?)',
      [name, email, 'firebase_auth', 'user'] // password_hash is placeholder
    );

    // STEP 5: Generate JWT for API access
    const user = {
      id: result.insertId,
      name,
      email,
      role: 'user',
      firebase_uid: firebaseUser.uid
    };

    const token = generateToken(user);

    // Return user info and JWT
    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role
        }
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      message: 'Registration failed'
    });
  }
};

/**
 * Login existing user
 * POST /api/auth/login
 * 
 * FLOW:
 * 1. Flutter authenticates with Firebase (gets ID token)
 * 2. Flutter sends token to this endpoint
 * 3. Backend verifies token, fetches user from MySQL, returns JWT
 */
exports.login = async (req, res) => {
  try {
    const { firebase_token } = req.body;

    // Validation
    if (!firebase_token) {
      return res.status(400).json({
        success: false,
        message: 'Firebase token is required'
      });
    }

    // STEP 1: Verify Firebase token
    let firebaseUser;
    try {
      firebaseUser = await verifyFirebaseToken(firebase_token);
    } catch (error) {
      return res.status(401).json({
        success: false,
        message: 'Invalid Firebase token'
      });
    }

    // STEP 2: Find user in MySQL by email
    const [users] = await db.query(
      'SELECT * FROM users WHERE email = ?',
      [firebaseUser.email]
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found. Please register first.'
      });
    }

    const user = users[0];

    // STEP 3: Generate JWT for API access
    const token = generateToken({
      id: user.id,
      email: user.email,
      role: user.role,
      firebase_uid: firebaseUser.uid
    });

    // Return user info and JWT
    res.json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          avatar_url: user.avatar_url,
          phone: user.phone
        }
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed'
    });
  }
};

/**
 * LEGACY: Email/Password Login (Optional - keep for testing)
 * This bypasses Firebase and uses traditional email/password
 */
exports.loginWithPassword = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    const [users] = await db.query(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    const user = users[0];

    // Only works if password was set (not firebase_auth placeholder)
    if (user.password_hash === 'firebase_auth') {
      return res.status(400).json({
        success: false,
        message: 'Please use Firebase login'
      });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password_hash);

    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    const token = generateToken(user);

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          avatar_url: user.avatar_url,
          phone: user.phone
        }
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed'
    });
  }
};

/**
 * Get current authenticated user
 * GET /api/auth/me
 */
exports.getCurrentUser = async (req, res) => {
  try {
    // req.user is set by authMiddleware
    const [users] = await db.query(
      'SELECT id, name, email, role, avatar_url, phone, created_at FROM users WHERE id = ?',
      [req.user.id]
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: { user: users[0] }
    });
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user data'
    });
  }
};