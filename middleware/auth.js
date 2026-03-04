// middleware/auth.js
// Middleware to protect routes that require authentication
// This runs BEFORE your controller logic

const { verifyToken } = require('../utils/jwt');

/**
 * Middleware: Verify JWT token from Authorization header
 * Attaches decoded user info to req.user for use in controllers
 */
const authMiddleware = (req, res, next) => {
    try {
        // Get token from Authorization header
        // Expected format: "Bearer <token>"
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                success: false,
                message: 'No token provided. Access denied.'
            });
        }

        // Extract token (remove "Bearer " prefix)
        const token = authHeader.split(' ')[1];

        // Verify and decode token
        const decoded = verifyToken(token);

        // Attach user info to request object
        // Now controllers can access req.user.id, req.user.role, etc.
        req.user = decoded;

        // Proceed to next middleware or controller
        next();
    } catch (error) {
        return res.status(401).json({
            success: false,
            message: 'Invalid token. Please login again.'
        });
    }
};

/**
 * Middleware: Ensure user has admin role
 * Use this AFTER authMiddleware
 */
const adminOnly = (req, res, next) => {
    // authMiddleware must run first to set req.user
    if (!req.user) {
        return res.status(401).json({
            success: false,
            message: 'Authentication required'
        });
    }

    if (req.user.role !== 'admin') {
        return res.status(403).json({
            success: false,
            message: 'Access denied. Admin privileges required.'
        });
    }

    next();
};

module.exports = {
    authMiddleware,
    adminOnly
};