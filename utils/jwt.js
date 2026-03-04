// utils/jwt.js
// JSON Web Token utilities for authentication
// JWTs are stateless - the token itself contains user info

const jwt = require('jsonwebtoken');

// Secret key from environment variable
// NEVER hardcode this - always use .env
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

/**
 * Generate JWT token for a user
 * @param {Object} user - User object from database
 * @returns {String} - Signed JWT token
 */
const generateToken = (user) => {
  // Payload: data stored inside the token
  const payload = {
    id: user.id,
    email: user.email,
    role: user.role
  };

  // Sign the token with expiry
  return jwt.sign(payload, JWT_SECRET, {
    expiresIn: '7d' // Token valid for 7 days
  });
};

/**
 * Verify and decode JWT token
 * @param {String} token - JWT token from request header
 * @returns {Object} - Decoded payload
 * @throws {Error} - If token is invalid or expired
 */
const verifyToken = (token) => {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    throw new Error('Invalid or expired token');
  }
};

module.exports = {
  generateToken,
  verifyToken
};