const jwt = require('jsonwebtoken');
require('dotenv').config();

/**
 * JWT utility functions for token generation and verification
 */

/**
 * Generate JWT token for authenticated user
 * @param {Object} user - User object containing id, email, and role
 * @returns {string} JWT token
 */
const generateToken = (user) => {
    return jwt.sign(
        { 
            id: user.id, 
            email: user.email, 
            role: user.role 
        }, 
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );
};

/**
 * Verify JWT token and return decoded payload
 * @param {string} token - JWT token to verify
 * @returns {Object} Decoded token payload
 * @throws {Error} If token is invalid or expired
 */
const verifyToken = (token) => {
    try {
        return jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            throw new Error('Token expired');
        } else if (error.name === 'JsonWebTokenError') {
            throw new Error('Invalid token');
        } else {
            throw new Error('Token verification failed');
        }
    }
};

/**
 * Decode JWT token without verification (for debugging)
 * @param {string} token - JWT token to decode
 * @returns {Object|null} Decoded payload or null if invalid
 */
const decodeToken = (token) => {
    try {
        return jwt.decode(token);
    } catch (error) {
        return null;
    }
};

/**
 * Extract token from authorization header
 * @param {string} authHeader - Authorization header value
 * @returns {string|null} Extracted token or null
 */
const extractTokenFromHeader = (authHeader) => {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return null;
    }
    return authHeader.split(' ')[1];
};

/**
 * Check if token is about to expire (within next 24 hours)
 * @param {string} token - JWT token to check
 * @returns {boolean} True if token is about to expire
 */
const isTokenExpiringSoon = (token) => {
    try {
        const decoded = jwt.decode(token);
        if (!decoded || !decoded.exp) return true;
        
        const expirationTime = decoded.exp * 1000; // Convert to milliseconds
        const currentTime = Date.now();
        const twentyFourHours = 24 * 60 * 60 * 1000;
        
        return (expirationTime - currentTime) < twentyFourHours;
    } catch (error) {
        return true;
    }
};

/**
 * Get token expiration time as Date object
 * @param {string} token - JWT token
 * @returns {Date|null} Expiration date or null
 */
const getTokenExpiration = (token) => {
    try {
        const decoded = jwt.decode(token);
        if (!decoded || !decoded.exp) return null;
        return new Date(decoded.exp * 1000);
    } catch (error) {
        return null;
    }
};

/**
 * Generate refresh token (longer expiration)
 * @param {Object} user - User object
 * @returns {string} Refresh token
 */
const generateRefreshToken = (user) => {
    return jwt.sign(
        { 
            id: user.id, 
            email: user.email,
            type: 'refresh'
        }, 
        process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET,
        { expiresIn: '30d' }
    );
};

/**
 * Verify refresh token
 * @param {string} token - Refresh token
 * @returns {Object} Decoded payload
 */
const verifyRefreshToken = (token) => {
    try {
        return jwt.verify(token, process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET);
    } catch (error) {
        throw new Error('Invalid refresh token');
    }
};

module.exports = {
    generateToken,
    verifyToken,
    decodeToken,
    extractTokenFromHeader,
    isTokenExpiringSoon,
    getTokenExpiration,
    generateRefreshToken,
    verifyRefreshToken
};