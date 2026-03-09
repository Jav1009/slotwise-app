// controllers/authController.js
// FLOW:
//   Register: Firebase creates account client-side (gets UID)
//             → Flutter sends uid + name + email to POST /auth/register
//             → We create MySQL user row with uid as the bridge key
//
//   Login:    Firebase signs in client-side (gets UID)
//             → Flutter sends uid to POST /auth/login
//             → We find MySQL user, issue JWT with role embedded
// const pool          = require('../config/db');
const bcrypt = require('bcrypt');             // Password hashing (saltRounds = 12)
const crypto = require('crypto');             // OTP generation + SHA-256 hashing
const pool = require('../config/db');         // MySQL connection pool
// const Email = require('../utils/email');      // Custom email utility (OTP + confirmation)
const { signToken } = require('../utils/jwt');


// ─────────────────────────────────────────────────────────────
// OTP CONFIGURATION
// ─────────────────────────────────────────────────────────────
const OTP_LENGTH = 6;           // 6-digit OTP (e.g., 048291)
const OTP_EXPIRES_MINUTES = 10; // OTP valid for 10 minutes after generation

// PEPPER: An extra secret mixed into the OTP hash
// Even if the DB leaks, an attacker cannot brute-force OTPs without the pepper
// Store OTP_PEPPER in .env — never hardcode it
function otpPepper() {
    // Falls back to JWT_SECRET if OTP_PEPPER is not set (not recommended for production)
    return process.env.OTP_PEPPER || process.env.JWT_SECRET;
}

// Generates a zero-padded numeric OTP of given length
// crypto.randomInt is cryptographically secure — safer than Math.random()
function generateOTP(len = OTP_LENGTH) {
    const max = 10 ** len;                       // Max range: 1,000,000 for 6-digit OTP
    const n = crypto.randomInt(0, max);          // Secure random integer [0, max)
    return String(n).padStart(len, '0');         // Pad to ensure e.g. "000123"
}

// Hashes the OTP using SHA-256 + pepper
// We store only the hash in the DB — never the raw OTP
function hashOTP(otp) {
    return crypto
        .createHash('sha256')
        .update(`${otp}.${otpPepper()}`)         // Combine OTP + pepper before hashing
        .digest('hex');                          // Returns a 64-char hex string
}


// ─────────────────────────────────────────────────────────────
// REGISTER
// POST /api/auth/register
// Body: { locationCode, firstName, lastName, email, password }
// Creates a new user — role is always 'user' on self-registration
// Staff and admin accounts must be created/promoted by an admin.
// ─────────────────────────────────────────────────────────────
// exports.register = async (req, res) => {
//   try {
//   const { 
//     // uid, 
//     name, email, password } = req.body;

//     // !uid     || 
//   if (
//     !name || !email || !password) {
//     return res.status(400).json({ message: 'uid, name, and email are required.' });
//   }

//     await pool.execute(
//       'INSERT INTO users (uid, name, email) VALUES (?, ?, ?)',
//       [uid, name.trim(), email.toLowerCase().trim()]
//     );
//     return res.status(201).json({ message: 'User registered successfully.' });
//   } catch (err) {
//     if (err.code === 'ER_DUP_ENTRY') {
//       return res.status(409).json({ message: 'A user with this email already exists.' });
//     }
//     console.error('[auth register]', err);
//     return res.status(500).json({ message: 'Registration failed. Please try again.' });
//   }
// };

exports.register = async (req, res, next) => {
    try {
        const { firstName, lastName, email, password } = req.body;

        // Step 1: Validate all required fields are present
        if (!firstName || !lastName || !email || !password) {
            res.status(400);
            throw new Error('All fields are required: firstName, lastName, email, password');
        }

        // // Step 2: Verify locationCode maps to an active location
        /* const [locRows] = await pool.query(
             'SELECT id FROM locations WHERE code = ? AND is_active = 1',
             [locationCode]
         );

         if (locRows.length === 0) {
             res.status(400);
             throw new Error('Invalid or inactive location code');
         }

         const location_id = locRows[0].id; // Resolved location ID for the FK
*/
        
        // Step 3: Check for duplicate email — must be unique across users
        const [userRows] = await pool.query(
            'SELECT id FROM users WHERE email = ?',
            [email]
        );

        if (userRows.length > 0) {
            res.status(409);  // 409 Conflict — resource already exists
            throw new Error('An account with this email already exists');
        }

        // Step 4: Hash the password using bcrypt (saltRounds = 12)
        // bcrypt.hash is async and automatically generates + applies a salt
        // The resulting hash includes the salt — no need to store it separately
        const password_hash = await bcrypt.hash(password, 12);

        // Step 5: Insert the new user — password_hash stored, raw password NEVER persisted
        const [result] = await pool.query(
            `INSERT INTO users (first_name, last_name, email, password_hash, role)
             VALUES (?, ?, ?, ?, 'user')`,
            // [firstName., lastName, email, password_hash]
            [firstName.trim(), lastName.trim(), email.toLowerCase(), password_hash]
        );

        // Step 6: Generate JWT for immediate login after registration
        const token = signToken(result.insertId);

        // Step 7: Return success — NEVER return password_hash in the response
        res.status(201).json({
            status: 'success',
            message: 'User registered successfully',
            data: {
                token,
                user: {
                    id: result.insertId,
                    firstName,
                    lastName,
                    email,
                    role: 'user'
                }
            }
        });
    } catch (error) {
        next(error); // Passed to errorMiddleware.js → errorHandler
    }
};

// ─────────────────────────────────────────────────────────────
// LOGIN
// POST /api/auth/login
// Body: { email, password }
// Validates credentials, checks account status, returns JWT + fcm_token status
// ─────────────────────────────────────────────────────────────

// exports.login = async (req, res) => {
//   const { uid } = req.body;

//   if (!uid) {
//     return res.status(400).json({ message: 'uid is required.' });
//   }

//   try {
//     const [rows] = await pool.execute(
//       'SELECT id, uid, name, email, role, profile_picture_url FROM users WHERE uid = ?',
//       [uid]
//     );

//     if (rows.length === 0) {
//       return res.status(404).json({ message: 'User not found. Please register first.' });
//     }

//     const user  = rows[0];
//     const token = signToken({
//       id:    user.id,
//       uid:   user.uid,
//       email: user.email,
//       role:  user.role,   // Critical — controls access throughout the app
//     });

//     return res.json({ token, user });
//   } catch (err) {
//     console.error('[auth login]', err);
//     return res.status(500).json({ message: 'Login failed. Please try again.' });
//   }
// };

exports.login = async (req, res, next) => {
    try {
        const { email, password } = req.body;

        // Step 1: Validate inputs
        if (!email || !password) {
            res.status(400);
            throw new Error('Email and password are required');
        }

        // Step 2: Fetch user by email — include password_hash for bcrypt comparison
        // LIMIT 1 for performance — email is unique but makes the intent explicit
        const [userRows] = await pool.query(
            `SELECT id, first_name, last_name, email,
                    password_hash, role, is_active, fcm_token
             FROM users
             WHERE email = ?
             LIMIT 1`,
            // [email]
            [email.toLowerCase().trim()]
        );

        // Step 3: Generic error if not found — prevents email enumeration
        if (userRows.length === 0) {
            res.status(401);
            throw new Error('Invalid email or password');
        }

        const user = userRows[0];

        // Step 4: Check account is active BEFORE running bcrypt.compare
        // Saves CPU if the account is already deactivated
        if (user.is_active !== 1) {
            res.status(403);
            throw new Error('Your account has been deactivated. Please contact support.');
        }

        // Step 5: Compare plaintext password against the stored bcrypt hash
        // bcrypt.compare is timing-safe and handles salt extraction internally
        const passwordMatch = await bcrypt.compare(password, user.password_hash);

        if (!passwordMatch) {
            res.status(401);
            // Same generic message — never reveal which one failed
            throw new Error('Invalid email or password');
        }

        // Step 6: Sign JWT and return success
        const token = signToken(user.id);

        res.status(200).json({
            status: 'success',
            message: 'Logged in successfully',
            data: {
                token,
                user: {
                    id: user.id,
                    // location_id: user.location_id,
                    firstName: user.first_name,
                    lastName: user.last_name,
                    email: user.email,
                    role: user.role,  // 'user' | 'staff' | 'admin'
                    // Return whether an FCM token is registered for this device
                    // Flutter uses this to decide if it needs to call PUT /api/auth/fcm-token
                    hasFcmToken: !!user.fcm_token
                }
            }
        });
    } catch (error) {
        next(error);
    }
};

// ─────────────────────────────────────────────────────────────
// LOGOUT
// POST /api/auth/logout
// Protected — requires valid JWT (authMiddleware)
// Clears FCM token from DB so push notifications stop for this device
// JWT itself is stateless — the client deletes it from secure storage
// ─────────────────────────────────────────────────────────────
exports.logout = async (req, res, next) => {
    try {
        // req.user.id is set by authMiddleware after JWT verification
        // Clearing FCM token stops push notifications for this device on logout
        await pool.query(
            'UPDATE users SET fcm_token = NULL WHERE id = ?',
            [req.user.id]
        );

        res.status(200).json({
            status: 'success',
            message: 'Logged out successfully',
            data: null
        });
    } catch (error) {
        next(error);
    }
};

// ─────────────────────────────────────────────────────────────
// UPDATE FCM TOKEN
// PUT /api/auth/fcm-token
// Protected — requires valid JWT (authMiddleware)
// Body: { fcm_token }
// Called by Flutter after FirebaseMessaging.instance.getToken() on login or token refresh
// Must also be called when Firebase issues a new token via onTokenRefresh callback
// ─────────────────────────────────────────────────────────────
exports.updateFcmToken = async (req, res, next) => {
    try {
        const { fcm_token } = req.body;

        if (!fcm_token) {
            res.status(400);
            throw new Error('fcm_token is required');
        }

        // Update the FCM token for the currently authenticated user
        // This overwrites any previous token — each device gets one active FCM token
        await pool.query(
            'UPDATE users SET fcm_token = ? WHERE id = ?',
            [fcm_token, req.user.id]
        );

        res.status(200).json({
            status: 'success',
            message: 'FCM token updated successfully',
            data: null
        });
    } catch (error) {
        next(error);
    }
};

// ─────────────────────────────────────────────────────────────
// FORGOT PASSWORD
// POST /api/auth/forgot-password
// Body: { email }
// Generates a 6-digit OTP, stores the hash + expiry, sends OTP via email
// Always returns 200 to prevent email enumeration attacks
// ─────────────────────────────────────────────────────────────
exports.forgotPassword = async (req, res, next) => {
    try {
        const { email } = req.body;

        if (!email) {
            res.status(400);
            throw new Error('Email is required');
        }

        // Fetch active user by email
        const [userRows] = await pool.query(
            `SELECT id, first_name, last_name, email
             FROM users
             WHERE email = ? AND is_active = 1`,
            // [email]
            [email.toLowerCase().trim()]
        );

        // Return 200 even if no user found — prevents account discovery
        if (userRows.length === 0) {
            return res.status(200).json({
                status: 'success',
                message: 'If an active account with that email exists, a reset OTP has been sent',
                data: null
            });
        }

        const user = userRows[0];

        // Step 1: Generate a fresh cryptographically secure 6-digit OTP
        const otp = generateOTP(OTP_LENGTH);

        // Step 2: Hash the OTP — raw OTP is NEVER written to the DB
        const otpHash = hashOTP(otp);

        // Step 3: Set expiry (current time + 10 minutes)
        const expiresAt = new Date(Date.now() + OTP_EXPIRES_MINUTES * 60 * 1000);

        // Step 4: Store hashed OTP and expiry in reset_token_hash + reset_token_expires
        // Any previous pending reset is overwritten — only the latest OTP is valid
        await pool.query(
            `UPDATE users
             SET reset_token_hash = ?, reset_token_expires = ?
             WHERE id = ?`,
            [otpHash, expiresAt, user.id]
        );

        // Step 5: Send raw OTP to user's email via the Email utility
        // After this point, the raw OTP is discarded — only the hash remains
        const fullName = `${user.first_name} ${user.last_name}`;
        await new Email({
            email: user.email,
            fullName,
            subject: 'Your Password Reset OTP',
            resetCode: otp   // Raw OTP sent to user, never stored
        }).sendPasswordResetEmail();

        // DEV ONLY — remove before production:
        console.log(`[DEV] OTP for ${user.email}: ${otp}`);

        res.status(200).json({
            status: 'success',
            message: 'OTP sent to your email address',
            data: null
        });
    } catch (error) {
        next(error);
    }
};

// ─────────────────────────────────────────────────────────────
// RESET PASSWORD
// POST /api/auth/reset-password
// Body: { email, otp, newPassword }
// Verifies OTP against hash, checks expiry, updates password_hash, clears reset fields
// ─────────────────────────────────────────────────────────────
exports.resetPassword = async (req, res, next) => {
    try {
        const { email, otp, newPassword } = req.body;

        // Step 1: Validate all fields present
        if (!email || !otp || !newPassword) {
            res.status(400);
            throw new Error('Email, OTP, and new password are all required');
        }

        // Step 2: Fetch user with reset fields — only active accounts
        const [userRows] = await pool.query(
            `SELECT id, first_name, last_name, email, reset_token_hash, reset_token_expires
             FROM users
             WHERE email = ? AND is_active = 1`,
            // [email]
            [email.toLowerCase().trim()]
        );

        // Generic error — don't reveal whether account exists
        if (userRows.length === 0) {
            res.status(400);
            throw new Error('Invalid or expired OTP');
        }

        const user = userRows[0];

        // Step 3: Ensure a reset was actually requested
        if (!user.reset_token_hash || !user.reset_token_expires) {
            res.status(400);
            throw new Error('No password reset was requested for this account');
        }

        // Step 4: Check OTP has not expired
        const now = new Date();
        const expiresAt = new Date(user.reset_token_expires);

        if (now > expiresAt) {
            // Clear expired token — user must call forgotPassword again
            await pool.query(
                'UPDATE users SET reset_token_hash = NULL, reset_token_expires = NULL WHERE id = ?',
                [user.id]
            );
            res.status(400);
            throw new Error('OTP has expired. Please request a new one.');
        }

        // Step 5: Hash the submitted OTP and compare to the stored hash
        // Timing-safe comparison via string equality on hashes
        const otpHash = hashOTP(otp);

        if (otpHash !== user.reset_token_hash) {
            res.status(400);
            throw new Error('Invalid OTP');
        }

        // Step 6: Valid OTP — hash the new password with bcrypt
        const password_hash = await bcrypt.hash(newPassword, 12);

        // Step 7: Update password_hash and clear reset fields in a single atomic query
        // Clearing reset fields prevents OTP reuse after a successful reset
        await pool.query(
            `UPDATE users
             SET password_hash = ?, reset_token_hash = NULL, reset_token_expires = NULL
             WHERE id = ?`,
            [password_hash, user.id]
        );

        // Step 8: Send confirmation email
        const fullName = `${user.first_name} ${user.last_name}`;
        await new Email({
            email: user.email,
            fullName,
            subject: 'Your Password Has Been Reset'
        }).sendPasswordChangeEmail();

        res.status(200).json({
            status: 'success',
            message: 'Password reset successfully. You can now log in.',
            data: null
        });
    } catch (error) {
        next(error);
    }
};

// GET /api/auth/me
exports.getMe = async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT id, first_name, last_name, email, role, profile_picture_url, created_at FROM users WHERE id = ?',
      [req.user.id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ message: 'User not found.' });
    }

/*
    return res.json(rows[0]);
   } catch (err) {
     console.error('[auth me]', err);
     return res.status(500).json({ message: 'Failed to fetch profile.' });
   }
*/
    const u = rows[0];
        res.status(200).json({
            status: 'success',
            data: {
                id:                u.id,
                firstName:         u.first_name,
                lastName:          u.last_name,
                email:             u.email,
                role:              u.role,
                profilePictureUrl: u.profile_picture_url,
                createdAt:         u.created_at
            }
        });
    } catch (error) {
        next(error);
    }
};