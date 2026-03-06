# SlotWise API

RESTful backend for the SlotWise Appointment Booking Application.  
Built with **Node.js**, **Express**, **MySQL**, and **Firebase Admin SDK** (push notifications).  
Authentication uses **Supabase JWT** verified server-side — swap to Firebase Auth anytime using the swap guide.

---

## Prerequisites

- Node.js v18+
- MySQL 8.0+
- npm
- A Supabase project (or Firebase project — see Swap Guide)
- A Firebase project with push notifications enabled (for FCM)

---

## Setup Instructions

### 1. Install dependencies
```bash
npm install express mysql2 dotenv bcrypt jsonwebtoken crypto firebase-admin @supabase/supabase-js
npm install --save-dev nodemon
```

### 2. Configure environment
Create a `.env` file in the project root:
```
# Server
PORT=3000
NODE_ENV=development

# MySQL Database
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=yourpassword
DB_NAME=slotwise

# JWT (used for session tokens between Flutter and this API)
JWT_SECRET=your-super-secret-jwt-key-at-least-32-characters
JWT_EXPIRES_IN=1h

# OTP (password reset)
OTP_PEPPER=your-separate-otp-pepper-secret

# Supabase (auth token verification)
SUPABASE_URL=https://yourproject.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Firebase Admin SDK (push notifications)
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n"
```

### 3. Create the database and tables
Open MySQL and run:
```bash
mysql -u root -p < config/schema.sql
```
This creates the database, all tables, and seeds lookup data.

**If upgrading an existing database**, run the migration to add new auth fields:
```bash
mysql -u root -p slotwise < migration/add_auth_fields.sql
```
This safely adds `reset_token_hash`, `reset_token_expires`, and `fcm_token` columns.

### 4. Start the server
```bash
# Production
npm start

# Development (auto-restart on file changes)
npm run dev
```

The API will be available at `http://localhost:3000`

---

## Project Structure

```
slotwise_api/
├── server.js                        # Entry point — loads .env, inits Firebase, starts listener
├── app.js                           # Express setup — routes, middleware, error handler
├── package.json
├── .env                             # Environment variables (never commit this)
├── .gitignore                       # Protects .env and service key files
├── config/
│   ├── db.js                        # MySQL connection pool (reused across all controllers)
│   ├── firebase.js                  # Firebase Admin SDK init (push notifications)
│   ├── supabase.js                  # Supabase client init (auth token verification)
│   └── schema.sql                   # Full database schema with seed data
├── migration/
│   └── add_auth_fields.sql          # Adds reset_token_hash, reset_token_expires, fcm_token
├── middleware/
│   ├── authMiddleware.js            # JWT verification — attaches req.user
│   ├── adminMiddleware.js           # Role guard — blocks non-admins with 403
│   └── errorMiddleware.js           # Centralized error handler + 404 handler
├── utils/
│   ├── jwt.js                       # Token signing and verification helpers
│   └── email.js                     # Email utility (OTP + booking confirmations)
├── controllers/
│   ├── authController.js            # register, login, logout, updateFcmToken, forgotPassword, resetPassword
│   ├── bookingController.js         # Booking CRUD + transaction logic + cancel flow
│   ├── serviceController.js         # Service CRUD (admin only for write operations)
│   ├── slotController.js            # Slot management — batch creation, availability
│   └── notificationController.js   # Firebase push notifications — single user + broadcast
└── routes/
    ├── auth.routes.js               # /api/auth  — 6 endpoints
    ├── booking.routes.js            # /api/bookings — 5 endpoints
    ├── service.routes.js            # /api/services — 6 endpoints
    ├── slot.routes.js               # /api/slots — 5 endpoints
    └── notification.routes.js      # /api/notifications — 2 endpoints (admin only)
```

---

## Database Schema

The `users` table includes these auth-related columns:

| Column | Type | Description |
|--------|------|-------------|
| `password_hash` | VARCHAR(255) | bcrypt hash (saltRounds=12). Raw password never stored. |
| `reset_token_hash` | VARCHAR(255) | SHA-256 + pepper hash of the 6-digit reset OTP. NULL when no reset is pending. |
| `reset_token_expires` | DATETIME | OTP expiry timestamp. Checked before accepting a reset request. |
| `fcm_token` | VARCHAR(500) | Firebase device token for push notifications. Set on login, cleared on logout. |
| `is_active` | TINYINT(1) | 1 = active, 0 = deactivated by admin. Checked on every authenticated request. |

---

## API Endpoints

### Auth

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /api/auth/register | None | Register a new staff user |
| POST | /api/auth/login | None | Login and receive JWT |
| POST | /api/auth/logout | JWT | Clear FCM token and end session |
| PUT | /api/auth/fcm-token | JWT | Register/update device push notification token |
| POST | /api/auth/forgot-password | None | Send 6-digit OTP to email |
| POST | /api/auth/reset-password | None | Verify OTP and set new password |

### Services

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | /api/services | JWT | Get all services |
| GET | /api/services?available=true | JWT | Get only available services |
| GET | /api/services/:id | JWT | Get a single service by ID |
| POST | /api/services | Admin | Create a new service |
| PUT | /api/services/:id | Admin | Update a service |
| DELETE | /api/services/:id | Admin | Delete a service |

### Slots

| Method | Endpoint   | Auth | Description |
|--------|------------|------|-------------|
| GET    | /api/slots | JWT  | Get all slots |
| GET    | /api/slots?date=YYYY-MM-DD | JWT | Get slots for a specific date |
| GET    | /api/slots/:id | JWT | Get a single slot |
| POST   | /api/slots | Admin | Create time slots (batch supported) |
| DELETE | /api/slots/:id | Admin | Delete a slot |

### Bookings

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | /api/bookings | JWT | Get all bookings for the current user |
| GET | /api/bookings/:id | JWT | Get a single booking |
| POST | /api/bookings | JWT | Create a booking (triggers push notification) |
| PUT | /api/bookings/:id/status | Admin | Update booking status (triggers push notification) |
| PUT | /api/bookings/:id/cancel | JWT | Cancel a scheduled booking |

### Notifications (Admin only)

| Method | Endpoint                | Auth  | Description |
|--------|-------------------------|-------|-------------|
| POST   | /api/notifications/send | Admin | Send push notification to a specific user |
| POST | /api/notifications/broadcast | Admin | Send push notification to all users |

---

## Example Request Bodies

### POST /api/auth/register
```json
{
  "locationCode": "KGN01",
  "firstName": "Javaughn",
  "lastName": "Brown",
  "email": "javaughn@example.com",
  "password": "SecurePassword123"
}
```

### POST /api/auth/login
```json
{
  "email": "javaughn@example.com",
  "password": "SecurePassword123"
}
```

### PUT /api/auth/fcm-token
```json
{
  "fcm_token": "dGhpcyBpcyBhIHNhbXBsZSBGQ00gdG9rZW4..."
}
```

### POST /api/auth/forgot-password
```json
{
  "email": "javaughn@example.com"
}
```

### POST /api/auth/reset-password
```json
{
  "email": "javaughn@example.com",
  "otp": "482910",
  "newPassword": "NewSecurePassword456"
}
```

### POST /api/bookings
```json
{
  "service_id": 2,
  "slot_id": 14,
  "notes": "Please send a reminder 30 minutes before."
}
```

### PUT /api/bookings/:id/status
```json
{
  "status": "Confirmed"
}
```

### POST /api/notifications/send
```json
{
  "userId": 5,
  "title": "Reminder",
  "body": "Your appointment is tomorrow at 10:00 AM.",
  "data": {
    "type": "reminder",
    "booking_id": "14"
  }
}
```

---

## Response Format

All responses follow this structure:

**Success:**
```json
{
  "status": "success",
  "message": "User logged in successfully",
  "data": {
    "token": "eyJhbGci...",
    "user": {
      "id": 1,
      "firstName": "Javaughn",
      "email": "javaughn@example.com",
      "role": "staff",
      "hasFcmToken": true
    }
  }
}
```

**Error:**
```json
{
  "success": false,
  "error": "Invalid email or password"
}
```

---

## HTTP Status Codes Used

| Code | Meaning |
|------|---------|
| 200 | OK — successful request |
| 201 | Created — resource created |
| 400 | Bad Request — validation or OTP error |
| 401 | Unauthorized — missing or invalid JWT |
| 403 | Forbidden — account inactive or insufficient role |
| 404 | Not Found — resource or route missing |
| 409 | Conflict — duplicate record or FK constraint |
| 500 | Internal Server Error |

---

## Push Notifications

Firebase Cloud Messaging (FCM) is used for push notifications. Notifications are sent automatically on:

- **Booking created** — user receives a confirmation notification
- **Status updated** — user is notified when admin changes booking status
- **Booking cancelled** — user is notified of cancellation

FCM tokens are managed as follows:

1. Flutter calls `FirebaseMessaging.instance.getToken()` after login
2. Flutter sends the token to `PUT /api/auth/fcm-token`
3. Backend stores the token in `users.fcm_token`
4. On logout, `POST /api/auth/logout` clears the token

Stale tokens (e.g., after app reinstall) are automatically cleared when Firebase returns `registration-token-not-registered`.

---

## Auth Provider

This project currently uses **Supabase JWT** for token verification.  
To switch to **Firebase Auth** (or back), follow the `firebase_supabase_swap_guide.docx`.  

> **Note:** Firebase push notifications are independent of the auth provider.  
> You can use Supabase Auth and FCM notifications simultaneously.

---

## Security Notes

- `password_hash` uses bcrypt with saltRounds=12 — raw passwords are never stored
- Reset OTPs are hashed with SHA-256 + pepper before storage — never stored raw
- OTPs expire after 10 minutes and are cleared after successful use
- JWT tokens expire after 1 hour
- FCM tokens are cleared on logout to stop notifications for inactive sessions
- `.env` and `serviceAccountKey.json` must never be committed to Git