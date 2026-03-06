// utils/jwt.js
// Thin wrappers around jsonwebtoken to keep signing config in one place.
const jwt = require('jsonwebtoken');          // JWT generation and verification

// ─────────────────────────────────────────────────────────────
// HELPER: Sign a JWT token for a given user_id
// Expires in 7d — short-lived for security(1 hour) <- set to this
// /**
//  * Signs a new JWT token.
//  * @param {object} payload - Data to embed: { id, uid, email, role }
//  * @returns {string} Signed JWT string
//  */
const signToken = (user_id) => {
  return jwt.sign({user_id}, process.env.JWT_SECRET, { expiresIn: '7d' });
};

// /**
//  * Verifies and decodes a JWT token.
//  * @param {string} token
//  * @returns {object} Decoded payload
//  * @throws Will throw if token is invalid or expired
//  */
const verifyToken = (token) => {
  return jwt.verify(token, process.env.JWT_SECRET);
};

module.exports = { signToken, verifyToken };