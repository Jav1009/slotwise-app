// server.js
// Entry point — loads environment variables then starts the Express app
require('dotenv').config();

// Initialise Supabase Admin client
require('./config/supabase');

// Initialise Firebase Admin client
require('./config/firebase');

const app  = require('./app');

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

app.listen(PORT, HOST, () => {
  console.log(`SlotWise API running on http://localhost:${PORT}`);
  console.log(`SlotWise APP running on http://192.168.50.147:${PORT}`);
});