# SlotWise API

RESTful backend for the SlotWise Appointment Booking Application.  
Built with **Node.js**, **Express**, **MySQL**, and **Firebase Admin SDK** (push notifications).  
Authentication uses **bcrypt + JWT** — no Supabase dependency.

---

## Prerequisites

- Node.js v18+
- MySQL 8.0+
- npm
- A Firebase project with FCM enabled (push notifications)

---

## Setup

### 1. Install dependencies
```bash
npm install
```

Fresh install:
```bash
npm install express mysql2 dotenv bcrypt jsonwebtoken crypto nodemailer firebase-admin node-cron
npm install --save-dev nodemon
```

### 2. Configure environment
Create `.env` in the project root:
```
# Server
PORT=3000
NODE_ENV=development

# MySQL
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=yourpassword
DB_NAME=slotwise

# JWT
JWT_SECRET=your-super-secret-jwt-key-at-least-32-characters
JWT_EXPIRES_IN=7d

# OTP pepper (password reset)
OTP_PEPPER=your-separate-otp-pepper-secret

# Email (password reset OTPs via nodemailer)
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password

# Firebase Admin SDK (FCM push notifications)
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n"
```

### 3. Create the database tables
Run each SQL file in order:
```bash
mysql -u root -p slotwise < users_table.sql
mysql -u root -p slotwise < services_table.sql
mysql -u root -p slotwise < time_slot_table.sql
mysql -u root -p slotwise < bookings_table.sql
mysql -u root -p slotwise < notifications_table.sql
mysql -u root -p slotwise < reminder_log_table.sql
```

**Upgrading an existing database** — run these migrations:
```sql
-- Notification preferences on users table
ALTER TABLE users
  ADD COLUMN notifications_enabled TINYINT(1) NOT NULL DEFAULT 1,
  ADD COLUMN reminders_enabled     TINYINT(1) NOT NULL DEFAULT 1;

-- Add 'missed' status to bookings
ALTER TABLE bookings
  MODIFY COLUMN status ENUM('pending','confirmed','cancelled','completed','missed')
  NOT NULL DEFAULT 'pending';

-- Back-fill overdue rows
UPDATE bookings b
JOIN time_slots t ON b.slot_id = t.id
SET b.status = 'missed'
WHERE b.status IN ('pending','confirmed')
  AND CONCAT(t.slot_date, ' ', t.end_time) < NOW();
```

### 4. Start the server
```bash
npm run dev    # development (nodemon auto-restart)
npm start      # production
```

API available at `http://localhost:3000`

---

## Project Structure

```
slot_wise_api/
├── server.js                      # Entry point — loads .env, starts Express + scheduler
├── app.js                         # Express setup — routes, CORS, error handler
├── scheduler.js                   # node-cron: markMissedBookings (15min), sendReminders (1hr)
├── package.json
├── .env                           # Never commit this
├── config/
│   ├── db.js                      # MySQL connection pool
│   └── firebase.js                # Firebase Admin SDK init
├── controllers/
│   ├── authController.js          # register, login, logout, getMe, updateProfile,
│   │                              #   updateFcmToken, forgotPassword, resetPassword
│   ├── bookingController.js       # createBooking, getMyBookings, getBookingById,
│   │                              #   cancelBooking, rescheduleBooking,
│   │                              #   getAllBookings, updateStatus
│   ├── serviceController.js       # getAll, getOne, create, update, softDelete, getCategories
│   ├── slotController.js          # getSlots, createSlots (batch), deleteSlot
│   └── notificationController.js  # getAll, markRead, markAllRead,
│                                  #   getPreferences, updatePreferences,
│                                  #   sendToUser, broadcastToAll,
│                                  #   notifyBookingConfirmed, notifyBookingCancelled,
│                                  #   notifyStatusUpdate, notifyStaffNewBooking,
│                                  #   notifyBookingMissed, notifyBookingReminder
├── middlewares/
│   ├── authMiddleware.js          # JWT verify — attaches req.user {id, role}
│   ├── adminMiddleware.js         # staffOnly / adminOnly role guards
│   ├── optionalAuth.js            # Attaches req.user if token present; doesn't block unauthenticated
│   └── errorMiddleware.js         # Centralised error + 404 handler
├── routes/
│   ├── authRoutes.js
│   ├── bookingRoutes.js
│   ├── serviceRoutes.js
│   ├── slotRoutes.js
│   └── notificationRoutes.js
└── utils/
    ├── jwt.js                     # signToken, verifyToken
    ├── email.js                   # sendOtpEmail via nodemailer
    └── fcmHelper.js               # Firebase sendToToken wrapper
```

---

## Database Schema

### users
| Column | Type | Notes |
|--------|------|-------|
| id | INT PK | |
| first_name | VARCHAR(100) | |
| last_name | VARCHAR(100) | |
| email | VARCHAR(255) UNIQUE | |
| password_hash | VARCHAR(255) | bcrypt saltRounds=12 |
| role | ENUM('user','staff','admin') | default 'user' |
| is_active | TINYINT(1) | 0 = deactivated by admin |
| fcm_token | VARCHAR(500) | set on login, cleared on logout |
| reset_token_hash | VARCHAR(255) | SHA-256+pepper OTP hash |
| reset_token_expires | DATETIME | 10-minute window |
| notifications_enabled | TINYINT(1) | FCM push toggle, default 1 |
| reminders_enabled | TINYINT(1) | reminder push toggle, default 1 |

### services
| Column | Type | Notes |
|--------|------|-------|
| id | INT PK | |
| name | VARCHAR(255) | |
| description | TEXT | nullable |
| duration_minutes | INT | floor(480/duration) slots per day |
| price | DECIMAL(10,2) | |
| image_url | VARCHAR(500) | nullable |
| category | VARCHAR(100) | nullable |
| is_active | TINYINT(1) | soft delete |
| created_by | INT FK → users.id | owning staff/admin — used for scope + notifications |

### time_slots
| Column | Type | Notes |
|--------|------|-------|
| id | INT PK | |
| service_id | INT FK | |
| slot_date | DATE | |
| start_time | TIME | |
| end_time | TIME | |
| is_available | TINYINT(1) | set FALSE when booked, TRUE when cancelled |

### bookings
| Column | Type | Notes |
|--------|------|-------|
| id | INT PK | |
| user_id | INT FK | customer |
| service_id | INT FK | |
| slot_id | INT FK | |
| status | ENUM | pending/confirmed/cancelled/completed/missed |
| notes | TEXT | nullable |
| created_at, updated_at | DATETIME | |

### notifications
| Column | Type | Notes |
|--------|------|-------|
| id | INT PK | |
| user_id | INT FK | recipient |
| booking_id | INT FK | nullable |
| message | TEXT | |
| is_read | TINYINT(1) | default 0 |
| created_at | DATETIME | |

### reminder_log
Dedup table — one row per booking per window. Prevents the scheduler from sending duplicate reminders after server restarts.

---

## API Endpoints

### Auth  `/api/auth`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /register | — | Register (role=user) |
| POST | /login | — | Login → `{ token, user }` |
| POST | /logout | JWT | Clear FCM token |
| GET | /me | JWT | Get own profile |
| PUT | /me | JWT | Update name / profile picture |
| PUT | /fcm-token | JWT | Register / refresh FCM token |
| POST | /forgot-password | — | Send 6-digit OTP to email |
| POST | /reset-password | — | Verify OTP + set new password |

### Services  `/api/services`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | / | optional | All services. Staff scoped to `created_by`. Query: `?include_inactive=true`, `?search=`, `?category=` |
| GET | /:id | optional | One service + available slots |
| GET | /categories | optional | Distinct category list |
| POST | / | staff/admin | Create — auto-generates 30 days of slots |
| PUT | /:id | staff/admin | Update |
| DELETE | /:id | staff/admin | Soft delete (is_active=false) |

### Slots  `/api/slots`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | / | JWT | Query: `?service_id=`, `?date=`, `?all=true` |
| POST | / | staff/admin | Batch-create slots |
| DELETE | /:id | staff/admin | Delete slot |

### Bookings  `/api/bookings`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /my | JWT | Own bookings → `{ status, data: [] }` |
| GET | / | staff/admin | All bookings. Staff scoped. Query: `?status=`, `?date=`, `?service_id=` |
| GET | /:id | JWT | One booking (customer: own only) |
| POST | / | JWT | Create — SELECT FOR UPDATE slot lock, notifies customer + staff |
| PUT | /:id/cancel | JWT | Cancel — frees slot |
| PUT | /:id/reschedule | JWT | Atomic slot swap |
| PUT | /:id/status | staff/admin | Update status (pending/confirmed/completed/cancelled/missed) |

### Notifications  `/api/notifications`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | / | JWT | Own notifications → `{ status, data: [] }` |
| PUT | /:id/read | JWT | Mark one read |
| PUT | /read-all | JWT | Mark all read |
| GET | /preferences | JWT | Get push preferences |
| PUT | /preferences | JWT | Update push preferences |
| POST | /send | JWT | Push to specific user |
| POST | /broadcast | admin | Push to all users with FCM token |

---

## Response Format

**Success**
```json
{ "status": "success", "data": { ... } }
```

**Error**
```json
{ "message": "Human-readable description" }
```

---

## Booking Status Flow

```
pending ──► confirmed ──► completed
   │              │
   └──────────────┴──► cancelled
                  └──► missed  (scheduler or client sweep)
```

The scheduler marks bookings `missed` every 15 minutes when slot end time has passed.  
The Flutter client also sweeps on fetch via `PUT /bookings/:id/status { status: "missed" }`.

---

## Slot Auto-Generation

`POST /api/services` auto-generates slots for 30 days at 09:00–17:00.  
Slots per day = `floor(480 / duration_minutes)` (minimum 1).  
To add slots beyond 30 days: `POST /api/slots` with `service_id`, `date`, and `times[]`.

---

## Push Notifications

Sent automatically on:
- Booking created → customer + service owner (staff/admin)
- Booking cancelled → customer + service owner
- Status updated → customer
- Booking rescheduled → customer + service owner
- Booking missed → customer (scheduler)
- Reminders → customer 24h and 1h before (scheduler, deduped via `reminder_log`)

`notifications_enabled` / `reminders_enabled` user columns gate FCM pushes.  
In-app notifications (`notifications` table) are always inserted.

---

## Security

- Passwords: bcrypt saltRounds=12
- OTPs: SHA-256+pepper hashed, 10-minute expiry, single-use
- JWT: 7-day expiry
- Staff scope: staff only access services/bookings where `created_by = their user_id`
- Never commit `.env` or any Firebase service account JSON file