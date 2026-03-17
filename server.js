// server.js - SlotWise Backend
// This is your Express application entry point
// It sets up middleware, routes, and starts the server

const express = require('express');
const cors = require('cors');
require('dotenv').config();

const db = require('./config/db');
require('./config/firebase');

const authRoutes = require('./routes/authRoutes');
const serviceRoutes = require('./routes/serviceRoutes');
const slotRoutes = require('./routes/slotRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const adminRoutes = require('./routes/adminRoutes');
const userRoutes = require('./routes/userRoutes');



const app = express();

// ============ MIDDLEWARE ============
// Parse JSON bodies (important for POST/PUT requests)
app.use(express.json());

// Enable CORS - allows Flutter app to make requests
app.use(cors({
  origin: '*', // In production, specify your Flutter app domain
  credentials: true
}));

// Request logging (helpful for debugging)
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// ============ ROUTES ============
// All routes are prefixed with /api
app.use('/api/auth', authRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/slots', slotRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/users', userRoutes);


// Health check endpoint (test if server is running)
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// ============ ERROR HANDLING ============
// Catch-all for 404 errors
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.path} not found`
  });
});

// Global error handler
// This catches any errors thrown in your routes/controllers
app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// ============ START SERVER ============
const PORT = process.env.PORT || 4000;

app.listen(PORT, () => {
  console.log(`✅ SlotWise Backend running on port ${PORT}`);
  console.log(`📍 Health check: http://localhost:${PORT}/health`);
});

module.exports = app;