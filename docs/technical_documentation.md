# SlotWise — Technical Documentation

**Version:** 1.0.0
**Developers:** Javaughn Douglas, Daniel Moncrieffe, Raphiel Collins
**Date:** March 2026

---

## 1. Architecture Overview

SlotWise follows a three-tier client-server architecture.

```
┌─────────────────────────────────┐
│        Flutter Mobile App       │
│  (Android — Customer & Admin)   │
└────────────────┬────────────────┘
                 │ HTTPS (Dio + JWT)
┌────────────────▼────────────────┐
│       Node.js / Express API     │
│         (Railway Cloud)         │
└──────┬──────────────────┬───────┘
       │                  │
┌──────▼──────┐   ┌───────▼───────┐
│    MySQL    │   │   Firebase    │
│  Database   │   │ Auth + FCM +  │
│  (Railway)  │   │   Storage     │
└─────────────┘   └───────────────┘
```

### Authentication Flow

1. User registers or logs in via **Firebase Auth** on the Flutter client
2. Flutter receives a Firebase ID token
3. Token is sent to the Node backend (`POST /api/auth/login`)
4. Backend verifies the token using the **Firebase Admin SDK**
5. Backend issues a custom **JWT** for all subsequent API calls
6. JWT is stored securely in `flutter_secure_storage` and injected into every request via a Dio interceptor
7. On app launch, `SplashScreen` checks auth state and routes to the appropriate dashboard based on `user.role`

### Role-Based Access

| Role | Access |
|---|---|
| `user` | Customer dashboard, booking flow, notifications, profile |
| `admin` | Admin panel, manage services/slots/bookings, analytics |

- Backend enforces roles via `adminOnly` middleware on all `/api/admin/*` routes
- Flutter enforces roles via `AuthProvider.isAdmin` getter

---

## 2. Project Structure

### Flutter (Frontend)
```
lib/
├── core/
│   ├── constants/       api_constants.dart, app_colors.dart
│   ├── theme/           app_theme.dart
│   └── utils/           snackbar_utils.dart, validators.dart
├── data/
│   ├── models/          booking_model, service_model,
│   │                    slot_model, user_model
│   └── services/        api_service, auth_service,
│                        fcm_service, storage_service
├── features/
│   ├── admin/           admin_dashboard, manage_bookings,
│   │                    manage_services, manage_slots,
│   │                    analytics, analytics_export,
│   │                    bulk_slots
│   ├── auth/            login, register
│   ├── bookings/        confirmation, detail,
│   │                    my_bookings, slot_picker
│   ├── dashboard/       user_dashboard
│   ├── notifications/   notifications
│   ├── profile/         profile
│   ├── services/        service_detail, services_list
│   ├── settings/        settings
│   └── splash/          splash
├── providers/           admin, auth, booking,
│                        notification, service, theme
├── widgets/             admin_theme_wrapper,
│                        custom_button, custom_text_field
└── main.dart
```

### Node.js (Backend)
```
config/         db.js, firebase.js
controllers/    admin, auth, booking, notification,
                service, slot, user
middleware/     auth.js
routes/         admin, auth, booking, notification,
                service, slot, user
utils/          fcm.js, jwt.js
server.js
```

---

## 3. Database Schema

### users
| Column | Type | Notes |
|---|---|---|
| id | INT PK AUTO_INCREMENT | |
| name | VARCHAR(255) | |
| email | VARCHAR(255) UNIQUE | |
| password_hash | VARCHAR(255) | `'firebase_auth'` placeholder |
| role | ENUM('user','admin') | Default: `'user'` |
| avatar_url | VARCHAR(500) | Nullable |
| phone | VARCHAR(50) | Nullable |
| created_at | TIMESTAMP | Default: CURRENT_TIMESTAMP |

### services
| Column | Type | Notes |
|---|---|---|
| id | INT PK AUTO_INCREMENT | |
| name | VARCHAR(255) | |
| description | TEXT | Nullable |
| duration_minutes | INT | |
| price | DECIMAL(10,2) | |
| image_url | VARCHAR(500) | Nullable |
| is_active | BOOLEAN | Default: TRUE — soft delete |
| created_at | TIMESTAMP | |

### time_slots
| Column | Type | Notes |
|---|---|---|
| id | INT PK AUTO_INCREMENT | |
| service_id | INT FK → services.id | |
| date | DATE | |
| start_time | TIME | |
| end_time | TIME | |
| is_available | BOOLEAN | Default: TRUE |
| created_by | INT FK → users.id | Admin who created it |

### bookings
| Column | Type | Notes |
|---|---|---|
| id | INT PK AUTO_INCREMENT | |
| user_id | INT FK → users.id | |
| service_id | INT FK → services.id | |
| slot_id | INT FK → time_slots.id | |
| status | ENUM('pending','confirmed','completed','cancelled') | |
| notes | TEXT | Nullable |
| cancelled_at | TIMESTAMP | Nullable |
| created_at | TIMESTAMP | |

### notifications
| Column | Type | Notes |
|---|---|---|
| id | INT PK AUTO_INCREMENT | |
| user_id | INT FK → users.id | |
| booking_id | INT FK → bookings.id | Nullable |
| message | TEXT | |
| type | VARCHAR(50) | e.g. `booking_created`, `status_update` |
| is_read | BOOLEAN | Default: FALSE |
| created_at | TIMESTAMP | |

### fcm_tokens
| Column | Type | Notes |
|---|---|---|
| id | INT PK AUTO_INCREMENT | |
| user_id | INT UNIQUE FK → users.id | One token per user |
| token | VARCHAR(512) | |
| updated_at | TIMESTAMP | |

---

## 4. API Endpoints

**Base URL:** `https://your-app.railway.app/api`

### Authentication
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/auth/register` | Public | Register with Firebase token |
| POST | `/auth/login` | Public | Login with Firebase token → JWT |
| GET | `/auth/me` | JWT | Get current user |

### Services
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/services` | Public | List all active services |
| GET | `/services/:id` | Public | Get single service |
| POST | `/services` | Admin | Create service |
| PUT | `/services/:id` | Admin | Update service |
| DELETE | `/services/:id` | Admin | Soft-delete service |

### Time Slots
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/slots` | Admin | All slots (filter by `?date=`) |
| GET | `/slots/available/:serviceId` | JWT | Available slots for a service |
| POST | `/slots` | Admin | Create single slot |
| POST | `/slots/bulk` | Admin | Bulk create slots (max 500) |
| PUT | `/slots/:id` | Admin | Update slot availability |
| DELETE | `/slots/:id` | Admin | Delete unbooked slot |

### Bookings
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/bookings/me` | JWT | Current user's bookings |
| POST | `/bookings` | JWT | Create booking |
| PUT | `/bookings/:id/cancel` | JWT | Cancel booking |

### Admin
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/admin/bookings` | Admin | All bookings (filter by `?status=`, `?date=`) |
| PUT | `/admin/bookings/:id/status` | Admin | Update booking status + push notification |
| GET | `/admin/stats` | Admin | Dashboard stats (filter by `?start_date=`, `?end_date=`) |

### Notifications
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/notifications` | JWT | User's notifications |
| PUT | `/notifications/:id/read` | JWT | Mark one as read |
| PUT | `/notifications/read-all` | JWT | Mark all as read |

### Users
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| PUT | `/users/profile` | JWT | Update name, phone, avatar |
| POST | `/users/fcm-token` | JWT | Save FCM device token |

---

## 5. Packages & Services Used

### Flutter Packages
| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.x | State management |
| `dio` | ^5.x | HTTP client with interceptors |
| `firebase_core` | ^3.x | Firebase initialisation |
| `firebase_auth` | ^5.x | User authentication |
| `firebase_messaging` | ^15.x | Push notifications (FCM) |
| `firebase_storage` | ^12.x | Avatar image uploads |
| `flutter_local_notifications` | ^18.x | Foreground push notification display |
| `flutter_secure_storage` | ^9.x | Secure JWT storage |
| `shared_preferences` | ^2.x | Theme preference persistence |
| `table_calendar` | ^3.x | Calendar UI for slot management |
| `fl_chart` | ^0.68.x | Analytics charts |
| `intl` | ^0.19.x | Date/time formatting |
| `image_picker` | ^1.x | Avatar photo selection |
| `path_provider` | ^2.x | File system access for CSV export |
| `share_plus` | ^9.x | System share sheet for CSV export |
| `permission_handler` | ^11.x | Notification permission management |
| `app_settings` | ^5.x | Open device app settings |

### Backend (npm)
| Package | Purpose |
|---|---|
| `express` | HTTP server framework |
| `mysql2` | MySQL connection pool |
| `firebase-admin` | Firebase token verification + FCM push |
| `jsonwebtoken` | JWT generation and verification |
| `bcryptjs` | Password hashing (legacy support) |
| `dotenv` | Environment variable management |
| `cors` | Cross-origin request handling |
| `nodemon` (dev) | Auto-restart during development |

### External Services
| Service | Purpose |
|---|---|
| Firebase Authentication | User identity and login |
| Firebase Cloud Messaging | Push notifications |
| Firebase Storage | User avatar image hosting |
| Railway | Backend API and MySQL database hosting |

---

## 6. Security Considerations

- All API routes are protected by JWT middleware except public auth and service listing endpoints
- Admin routes have an additional `adminOnly` middleware layer
- Firebase ID tokens are verified server-side using the Firebase Admin SDK before any JWT is issued
- JWT tokens expire after 7 days
- Booking creation uses MySQL transactions with `FOR UPDATE` row locking to prevent double-booking race conditions
- Passwords are not stored — Firebase handles all credential management; `password_hash` contains a placeholder value for Firebase-authenticated users
- Environment variables (database credentials, Firebase keys, JWT secret) are never committed to source control

---

## 7. Deployment

| Component | Platform | Notes |
|---|---|---|
| Backend API | Railway | Auto-deploys on GitHub push |
| MySQL Database | Railway | Managed instance, linked via env vars |
| Flutter App | APK | Built with `flutter build apk --release` |
| Firebase | Google Cloud | Auth, FCM, Storage configured via Firebase Console |