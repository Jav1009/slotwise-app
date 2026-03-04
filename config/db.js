// config/db.js
// MySQL connection pool configuration
// Using pool instead of single connection = better performance

const mysql = require('mysql2/promise');

// Connection pool - reuses connections instead of creating new ones
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'slotwise',
  waitForConnections: true,
  connectionLimit: 10, // Max 10 simultaneous connections
  queueLimit: 0
});

// Test the connection
pool.getConnection()
  .then(connection => {
    console.log('✅ Database connected successfully');
    connection.release();
  })
  .catch(err => {
    console.error('❌ Database connection failed:', err.message);
    process.exit(1); // Exit if database is unreachable
  });

module.exports = pool;