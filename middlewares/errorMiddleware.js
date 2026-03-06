// middleware/errorMiddleware.js
// Centralized error handling — ALL unhandled errors flow here via next(err)
// Prevents server crashes and ensures every error returns a structured JSON response.
// Must be registered LAST in app.js — after all routes.

// ─────────────────────────────────────────────────────────────
// CUSTOM ERROR CLASS
// Use this in controllers to throw errors with a specific HTTP status code:
//   throw new AppError('Service not found', 404)
// ─────────────────────────────────────────────────────────────
class AppError extends Error {
    constructor(message, statusCode) {
        super(message);
        this.statusCode = statusCode;  // Stored and used by errorHandler below
        this.name = 'AppError';
    }
}

// ─────────────────────────────────────────────────────────────
// 404 NOT FOUND HANDLER
// Catches requests to routes that don't exist.
// Register in app.js AFTER all route definitions.
// ─────────────────────────────────────────────────────────────
const notFound = (req, res, next) => {
    // Create an AppError with 404 status and pass to errorHandler
    const error = new AppError(
        `Route not found: ${req.method} ${req.originalUrl}`,
        404
    );
    next(error); // Passes to the global errorHandler below
};

// ─────────────────────────────────────────────────────────────
// GLOBAL ERROR HANDLER
// Express identifies this as error-handling middleware because it accepts
// FOUR arguments: (err, req, res, next) — this exact signature is required.
// Register in app.js as the very last middleware.
// ─────────────────────────────────────────────────────────────
const errorHandler = (err, req, res, next) => {
    // Step 1: Log the full error to the server console for debugging
    console.error(`\n❌  [ERROR] ${new Date().toISOString()}`);
    console.error(`   Route:   ${req.method} ${req.originalUrl}`);
    console.error(`   Message: ${err.message}`);

    // also append the same information (plus stack) to error_log.txt
    const fs = require('fs');
    const path = require('path');
    try {
        const logPath = path.join(__dirname, '..', 'error_log.txt');
        const entry = `\n[${new Date().toISOString()}] ${req.method} ${req.originalUrl} --> ${err.message}` +
                      (err.stack ? `\n   Stack: ${err.stack}` : '') + '\n';
        fs.appendFileSync(logPath, entry);
    } catch (fileErr) {
        // if logging fails we don't want to crash the server
        console.error('Failed to write to error_log.txt:', fileErr.message);
    }

    // Only log the full stack trace in development — never expose it in production
    if (process.env.NODE_ENV === 'development') {
        console.error(`   Stack:   ${err.stack}`);
    }

    // Step 2: Determine HTTP status code
    // Controllers set res.status() before throwing, so err.statusCode may be set
    // Falls back to 500 (Internal Server Error) if nothing was set
    const statusCode = res.statusCode && res.statusCode !== 200
        ? res.statusCode
        : err.statusCode || 500;

    let message = err.message || 'Internal Server Error';

    // ─────────────────────────────────────────────────────────
    // Step 3: Handle MySQL-specific error codes with readable messages
    // These are thrown by the mysql2 driver and have an err.code property
    // ─────────────────────────────────────────────────────────

    // ER_DUP_ENTRY: UNIQUE constraint violated
    // Triggered when inserting a duplicate email, or any UNIQUE column
    if (err.code === 'ER_DUP_ENTRY') {
        message = 'A record with this value already exists.';
        return res.status(409).json({ success: false, error: message });
    }

    // ER_NO_REFERENCED_ROW_2: FK violation — the referenced ID does not exist
    // Triggered when inserting a booking with a non-existent service_id or user_id
    if (err.code === 'ER_NO_REFERENCED_ROW_2') {
        message = 'Referenced record does not exist. Check your IDs.';
        return res.status(400).json({ success: false, error: message });
    }

    // ER_ROW_IS_REFERENCED_2: Cannot delete a record that other rows depend on
    // Triggered when deleting a service that still has bookings referencing it
    if (err.code === 'ER_ROW_IS_REFERENCED_2') {
        message = 'Cannot delete — this record is still referenced by existing data.';
        return res.status(409).json({ success: false, error: message });
    }

    // ER_BAD_FIELD_ERROR: Column does not exist in the queried table
    // Usually a developer error — a typo in a column name in a SQL query
    if (err.code === 'ER_BAD_FIELD_ERROR') {
        message = 'Database query references an unknown column. Contact support.';
        return res.status(500).json({ success: false, error: message });
    }

    // ER_ACCESS_DENIED_ERROR: MySQL credentials in .env are wrong
    // Triggered on startup if DB_USER or DB_PASSWORD don't match
    if (err.code === 'ER_ACCESS_DENIED_ERROR') {
        message = 'Database access denied. Check your DB credentials in .env.';
        return res.status(500).json({ success: false, error: message });
    }

    // ER_NO_SUCH_TABLE: Table doesn't exist — schema.sql may not have been run
    if (err.code === 'ER_NO_SUCH_TABLE') {
        message = 'Database table not found. Ensure schema.sql has been applied.';
        return res.status(500).json({ success: false, error: message });
    }

    // ─────────────────────────────────────────────────────────
    // Step 4: Handle Firebase Admin SDK errors (push notifications)
    // firebase-admin throws errors with a specific errorInfo.code pattern
    // ─────────────────────────────────────────────────────────

    // messaging/registration-token-not-registered:
    // The FCM token stored in the DB is no longer valid (user uninstalled app, etc.)
    // When this happens, clear the stale token from the DB
    if (err.errorInfo && err.errorInfo.code === 'messaging/registration-token-not-registered') {
        // This is handled gracefully in notificationController — logged, not thrown
        // If it does reach here, return a non-fatal 200 so the booking still succeeds
        console.warn('⚠️  Stale FCM token detected. Notification skipped.');
        return res.status(200).json({
            success: true,
            error: 'Notification could not be delivered — stale device token.'
        });
    }

    // messaging/invalid-argument: FCM token format is malformed
    if (err.errorInfo && err.errorInfo.code === 'messaging/invalid-argument') {
        console.warn('⚠️  Invalid FCM token format.');
        return res.status(400).json({ success: false, error: 'Invalid FCM token format.' });
    }

    // ─────────────────────────────────────────────────────────
    // Step 5: Default — return a standardized JSON error response
    // ─────────────────────────────────────────────────────────
    return res.status(statusCode).json({
        success: false,
        error: message,
        // Only include stack trace in development — NEVER expose in production
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
};

module.exports = { errorHandler, notFound, AppError };