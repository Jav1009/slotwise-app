// config/db.js
// Creates a reusable MySQL connection pool using mysql2/promise.
//
// WHY a pool?
//   A single connection can only serve one query at a time.
//   A pool keeps multiple connections open so concurrent API requests
//   don't have to wait. connectionLimit: 10 means up to 10 simultaneous
//   queries can run before others are queued.
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host:             process.env.DB_HOST     || 'localhost',
  user:             process.env.DB_USER     || 'root',
  password:         process.env.DB_PASSWORD || '',
  database:         process.env.DB_NAME     || 'slotwise',
  waitForConnections: true,
  connectionLimit:  10,
  queueLimit:       0,
});

// Quick test on startup — logs success or error to console
pool.getConnection()
  .then(conn => {
    console.log('MySQL connected successfully');
    conn.release();
  })
  .catch(err => console.error('MySQL connection error:', err.message));

module.exports = pool;