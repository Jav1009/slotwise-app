const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

// Import database connection
const db = require('./config/database');

// Import routes
const authRoutes = require('./routes/authRoutes');
const serviceRoutes = require('./routes/serviceRoutes');
const slotRoutes = require('./routes/slotRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const adminRoutes = require('./routes/adminRoutes');

// Initialize express app
const app = express();

// ==================== MIDDLEWARE ====================

// Enable CORS for all routes
app.use(cors({
    origin: process.env.CLIENT_URL || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With'],
    credentials: true,
    optionsSuccessStatus: 200
}));

// Parse JSON bodies with increased limit for images
app.use(express.json({ limit: '50mb' }));

// Parse URL-encoded bodies
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Serve static files (for uploaded images, etc.)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Create uploads directory if it doesn't exist
const fs = require('fs');
if (!fs.existsSync(path.join(__dirname, 'uploads'))) {
    fs.mkdirSync(path.join(__dirname, 'uploads'));
}

// Request logging middleware
app.use((req, res, next) => {
    const timestamp = new Date().toISOString();
    const method = req.method;
    const url = req.url;
    const ip = req.ip || req.connection.remoteAddress;
    
    console.log(`[${timestamp}] ${method} ${url} - IP: ${ip}`);
    
    // Log request body for POST/PUT requests (exclude passwords)
    if ((method === 'POST' || method === 'PUT') && req.body) {
        const logBody = { ...req.body };
        if (logBody.password) logBody.password = '[REDACTED]';
        if (logBody.password_hash) logBody.password_hash = '[REDACTED]';
        console.log('   Body:', JSON.stringify(logBody).substring(0, 200));
    }
    
    next();
});

// ==================== ROUTES ====================

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        success: true,
        status: 'OK',
        message: 'SlotWise API is running',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development',
        version: '1.0.0',
        database: db ? 'connected' : 'disconnected'
    });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/slots', slotRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', adminRoutes);

// ==================== ERROR HANDLING ====================

// 404 handler for undefined routes
app.use('*', (req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route not found',
        path: req.originalUrl,
        method: req.method,
        timestamp: new Date().toISOString()
    });
});

// Global error handling middleware
app.use((err, req, res, next) => {
    console.error('\n❌ ERROR HANDLER CAUGHT:');
    console.error('   Time:', new Date().toISOString());
    console.error('   Path:', req.path);
    console.error('   Method:', req.method);
    console.error('   Error:', err);
    
    // Default error
    let statusCode = err.statusCode || 500;
    let message = err.message || 'Internal server error';
    let errorCode = err.code || 'INTERNAL_ERROR';
    
    // Handle specific error types
    if (err.name === 'ValidationError') {
        statusCode = 400;
        message = 'Validation error';
        errorCode = 'VALIDATION_ERROR';
    } else if (err.name === 'UnauthorizedError' || err.code === 'UNAUTHORIZED') {
        statusCode = 401;
        message = 'Unauthorized access';
        errorCode = 'UNAUTHORIZED';
    } else if (err.name === 'ForbiddenError') {
        statusCode = 403;
        message = 'Forbidden access';
        errorCode = 'FORBIDDEN';
    } else if (err.code === 'ER_DUP_ENTRY') {
        statusCode = 409;
        message = 'Duplicate entry - record already exists';
        errorCode = 'DUPLICATE_ENTRY';
    } else if (err.code === 'ER_NO_REFERENCED_ROW') {
        statusCode = 400;
        message = 'Referenced record does not exist';
        errorCode = 'INVALID_REFERENCE';
    } else if (err.code === 'ER_ROW_IS_REFERENCED') {
        statusCode = 400;
        message = 'Cannot delete - record is in use';
        errorCode = 'RECORD_IN_USE';
    } else if (err.code === 'ECONNREFUSED') {
        statusCode = 503;
        message = 'Database connection failed';
        errorCode = 'DB_CONNECTION_ERROR';
    }
    
    // Send error response
    res.status(statusCode).json({
        success: false,
        message: message,
        code: errorCode,
        timestamp: new Date().toISOString(),
        path: req.path,
        ...(process.env.NODE_ENV === 'development' && {
            error: {
                name: err.name,
                stack: err.stack,
                details: err
            }
        })
    });
});

// ==================== DATABASE CONNECTION CHECK ====================

// Test database connection on startup
(async () => {
    try {
        const connection = await db.getConnection();
        console.log('✅ Database connection successful');
        connection.release();
    } catch (error) {
        console.error('❌ Database connection failed:', error.message);
        console.log('⚠️ Server will start but database operations may fail');
    }
})();

// ==================== SERVER START ====================

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

const server = app.listen(PORT, HOST, () => {
    console.log('\n' + '='.repeat(60));
    console.log('🚀 SLOTWISE BACKEND SERVER');
    console.log('='.repeat(60));
    console.log(`📍 Host:        ${HOST}`);
    console.log(`📍 Port:        ${PORT}`);
    console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`📍 Started at:  ${new Date().toISOString()}`);
    console.log('='.repeat(60));
    console.log('\n📋 AVAILABLE ENDPOINTS:');
    console.log('─'.repeat(60));
    
    // Health
    console.log('\n🟢 HEALTH:');
    console.log(`   GET  http://localhost:${PORT}/health`);
    
    // Authentication
    console.log('\n🔐 AUTHENTICATION:');
    console.log(`   POST http://localhost:${PORT}/api/auth/register`);
    console.log(`   POST http://localhost:${PORT}/api/auth/login`);
    console.log(`   GET  http://localhost:${PORT}/api/auth/me`);
    console.log(`   PUT  http://localhost:${PORT}/api/auth/me`);
    
    // Services
    console.log('\n💇 SERVICES:');
    console.log(`   GET  http://localhost:${PORT}/api/services`);
    console.log(`   GET  http://localhost:${PORT}/api/services/:id`);
    console.log(`   POST http://localhost:${PORT}/api/services (admin)`);
    console.log(`   PUT  http://localhost:${PORT}/api/services/:id (admin)`);
    console.log(`   DEL  http://localhost:${PORT}/api/services/:id (admin)`);
    console.log(`   GET  http://localhost:${PORT}/api/services/:id/slots`);
    
    // Slots
    console.log('\n⏰ SLOTS:');
    console.log(`   GET  http://localhost:${PORT}/api/slots/available`);
    console.log(`   GET  http://localhost:${PORT}/api/slots/range`);
    console.log(`   POST http://localhost:${PORT}/api/slots (admin)`);
    console.log(`   POST http://localhost:${PORT}/api/slots/batch (admin)`);
    console.log(`   PUT  http://localhost:${PORT}/api/slots/:id (admin)`);
    console.log(`   DEL  http://localhost:${PORT}/api/slots/:id (admin)`);
    
    // Bookings
    console.log('\n📅 BOOKINGS:');
    console.log(`   GET  http://localhost:${PORT}/api/bookings/my`);
    console.log(`   GET  http://localhost:${PORT}/api/bookings/upcoming`);
    console.log(`   GET  http://localhost:${PORT}/api/bookings/stats`);
    console.log(`   GET  http://localhost:${PORT}/api/bookings/:id`);
    console.log(`   POST http://localhost:${PORT}/api/bookings`);
    console.log(`   PUT  http://localhost:${PORT}/api/bookings/:id/cancel`);
    
    // NOTIFICATIONS - NEW!
    console.log('\n🔔 NOTIFICATIONS:');
    console.log(`   POST http://localhost:${PORT}/api/notifications/register-token`);
    console.log(`   POST http://localhost:${PORT}/api/notifications/remove-token`);
    console.log(`   GET  http://localhost:${PORT}/api/notifications/devices`);
    console.log(`   POST http://localhost:${PORT}/api/notifications/test`);
    console.log(`   POST http://localhost:${PORT}/api/notifications/admin/broadcast (admin)`);
    console.log(`   GET  http://localhost:${PORT}/api/notifications/admin/stats (admin)`);
    
    // Admin
    console.log('\n👑 ADMIN:');
    console.log(`   GET  http://localhost:${PORT}/api/admin/dashboard`);
    console.log(`   GET  http://localhost:${PORT}/api/admin/analytics`);
    console.log(`   GET  http://localhost:${PORT}/api/admin/bookings`);
    console.log(`   PUT  http://localhost:${PORT}/api/admin/bookings/:id/status`);
    
    console.log('─'.repeat(60));
    console.log('\n✅ Server is ready to accept connections\n');
});

// ==================== GRACEFUL SHUTDOWN ====================

// Handle SIGTERM (e.g., from Kubernetes)
process.on('SIGTERM', () => {
    console.log('\n🛑 SIGTERM received. Closing server gracefully...');
    server.close(() => {
        console.log('✅ Server closed');
        // Close database connections
        if (db && typeof db.end === 'function') {
            db.end();
        }
        process.exit(0);
    });
});

// Handle SIGINT (e.g., Ctrl+C)
process.on('SIGINT', () => {
    console.log('\n🛑 SIGINT received. Closing server gracefully...');
    server.close(() => {
        console.log('✅ Server closed');
        // Close database connections
        if (db && typeof db.end === 'function') {
            db.end();
        }
        process.exit(0);
    });
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
    console.error('\n❌ UNCAUGHT EXCEPTION:');
    console.error(err);
    server.close(() => {
        process.exit(1);
    });
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
    console.error('\n❌ UNHANDLED REJECTION:');
    console.error(err);
    server.close(() => {
        process.exit(1);
    });
});

module.exports = server;
