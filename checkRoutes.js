// checkRoutes.js - Diagnostic script to find the problematic route
// Run this: node checkRoutes.js

console.log('🔍 Checking all route files...\n');

const routes = [
  { name: 'authRoutes', path: './routes/authRoutes' },
  { name: 'serviceRoutes', path: './routes/serviceRoutes' },
  { name: 'slotRoutes', path: './routes/slotRoutes' },
  { name: 'bookingRoutes', path: './routes/bookingRoutes' },
  { name: 'notificationRoutes', path: './routes/notificationRoutes' }
];

routes.forEach(route => {
  try {
    const imported = require(route.path);
    if (typeof imported === 'function') {
      console.log(`✅ ${route.name}: OK (exports a router)`);
    } else {
      console.log(`❌ ${route.name}: PROBLEM - exports ${typeof imported} instead of function`);
      console.log(`   Value:`, imported);
    }
  } catch (error) {
    console.log(`❌ ${route.name}: ERROR - ${error.message}`);
  }
});

console.log('\n📋 If any routes show ❌, they need to be fixed.');