// app.js
// Express application configuration.
// Registers middleware and mounts all route groups.
const express = require('express');
const cors    = require('cors');
const app     = express();

// ── Middleware ────────────────────────────────────────────────
const {notFound, errorHandler }  = require('./middlewares/errorMiddleware');  // Global error handler

// ─── Routes ──────────────────────────────────────────────────────────────────
// Add your other existing routes below:
const authRoutes          = require('./routes/authRoutes');
const notificationRoutes  = require('./routes/notificationRoutes'); // NEW: push notifications
const bookingRoutes       = require('./routes/bookingRoutes');
const serviceRoutes       = require('./routes/serviceRoutes');
const slotRoutes          = require('./routes/slotRoutes');
// const locationRoutes   = require('./routes/locationRoutes');
// 
app.use(express.json());

// Allow cross-origin requests from the Flutter app.
// In production, restrict origin to your deployed Flutter app domain.
app.use(cors());

// ── Routes ───────────────────────────────────────────────────
app.use('/api/auth',          authRoutes);
app.use('/api/services',      serviceRoutes);
app.use('/api/slots',         slotRoutes);
app.use('/api/bookings',      bookingRoutes);
app.use('/api/notifications', notificationRoutes);

// ── Health check ─────────────────────────────────────────────
app.get('/health', (req, res) => res.json({ status: 'ok', app: 'SlotWise API' }));

// ─── 404 Handler ─────────────────────────────────────────────────────────────
// app.use((req, res) => {
//     res.status(404).json({
//         status: 'error',
//         message: `Route ${req.originalUrl} not found`
//     });
// });
app.use(notFound);

// ── Global error handler ─────────────────────────────────────
// Catches any error passed via next(err) from controllers
// eslint-disable-next-line no-unused-vars
// app.use((err, req, res, next) => {
//   console.error('[SlotWise Error]', err.stack);
//   res.status(500).json({ message: 'Internal server error' });
// });
app.use(errorHandler);

module.exports = app;