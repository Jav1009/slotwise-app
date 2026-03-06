// config/firebase.js
// Initializes the Firebase Admin SDK using environment variables from .env
// This single instance is shared across the entire backend via module caching.
// Used by: notificationController.js for sending push notifications

const admin = require('firebase-admin');

// ─────────────────────────────────────────────────────────────
// WHY environment variables instead of a JSON key file?
// — The serviceAccountKey.json contains sensitive credentials
// — It must NEVER be committed to Git (add to .gitignore)
// — Storing each field as a separate .env variable is safer for deployment
//   (works with Railway, Render, Heroku, Vercel without uploading a file)
// ─────────────────────────────────────────────────────────────

// Build the service account credential object from .env variables
// These values come from the Firebase Console:
//   Project Settings → Service accounts → Generate new private key → download JSON
// Then copy projectId, privateKey, clientEmail from that JSON into your .env
const serviceAccount = {
    type: 'service_account',
    project_id: process.env.FIREBASE_PROJECT_ID,

    // CRITICAL: The private key in .env has literal \n instead of real newlines
    // .replace(/\\n/g, '\n') converts them back to actual line breaks
    // Without this fix, firebase-admin throws "Invalid PEM formatted message"
    private_key: process.env.FIREBASE_PRIVATE_KEY
        // ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
        ? process.env.FIREBASE_PRIVATE_KEY.trim().replace(/\\n/g, '\n')
        : undefined,

    client_email: process.env.FIREBASE_CLIENT_EMAIL,
};

// ─────────────────────────────────────────────────────────────
// Initialize Firebase Admin SDK
// admin.apps.length check prevents "app already initialized" error
// if this module is imported multiple times (e.g., in tests)
// ─────────────────────────────────────────────────────────────
if (!admin.apps.length) {
    // Validate that all required env vars are present before initializing
    if (!serviceAccount.project_id || !serviceAccount.private_key || !serviceAccount.client_email) {
        console.error(
            '❌  Firebase Admin SDK: Missing required environment variables.\n' +
            '   Ensure FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, and FIREBASE_CLIENT_EMAIL\n' +
            '   are set in your .env file.'
        );
        // Don't throw — allow the server to start but notifications will fail gracefully
    } else {
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log('✅  Firebase Admin SDK initialized successfully.');
    }
}

// Export the admin instance
// Usage in other files: const admin = require('../config/firebase');
// Then: admin.messaging().send(message);
module.exports = admin;