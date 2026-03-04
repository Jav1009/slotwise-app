// config/firebase.js
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  })
});

// Export Firebase Auth instance
const auth = admin.auth();

/**
 * Verify Firebase ID token
 * @param {string} idToken - Firebase ID token from client
 * @returns {Object} - Decoded token with user info
 */
const verifyFirebaseToken = async (idToken) => {
  try {
    const decodedToken = await auth.verifyIdToken(idToken);
    return decodedToken;
  } catch (error) {
    throw new Error('Invalid Firebase token');
  }
};

/**
 * Get user by email from Firebase
 * @param {string} email 
 * @returns {Object} - Firebase user record
 */
const getUserByEmail = async (email) => {
  try {
    return await auth.getUserByEmail(email);
  } catch (error) {
    throw new Error('User not found in Firebase');
  }
};

/**
 * Delete user from Firebase
 * @param {string} uid - Firebase user ID
 */
const deleteFirebaseUser = async (uid) => {
  try {
    await auth.deleteUser(uid);
  } catch (error) {
    console.error('Error deleting Firebase user:', error);
  }
};

module.exports = {
  auth,
  verifyFirebaseToken,
  getUserByEmail,
  deleteFirebaseUser
};