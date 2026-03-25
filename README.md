# SlotWise 📅

A full-stack mobile appointment booking application built with Flutter and Node.js. SlotWise allows customers to browse services, book time slots, and receive real-time booking updates — while giving administrators full control over services, scheduling, bookings, and analytics.

---

## Screenshots

| Admin | Customer |
|---|---|
| ![Admin](assets/admin_screenshot.png) | ![Customer](assets/user_screenshot.png) |
---

## Features

### Customer
- Register and log in via Firebase Authentication
- Browse and search services with price/duration filtering
- Book available time slots
- View upcoming and past bookings
- Cancel bookings
- Receive push notifications on booking status changes
- In-app notification centre
- Profile management with avatar upload
- Dark mode support

### Admin
- Dedicated admin panel with live dashboard stats
- Full service management — create, edit, soft-delete
- Slot management — single slot, bulk generate for one day, or bulk generate across a date range
- Booking management — filter by status, update booking status
- Push notifications when new bookings are made — tap to jump directly to that booking
- Analytics dashboard with date range filtering — booking counts, revenue, top services
- CSV export of analytics data

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile Frontend | Flutter (Dart) |
| State Management | Provider |
| Backend API | Node.js + Express |
| Database | MySQL |
| Authentication | Firebase Auth + Custom JWT |
| Push Notifications | Firebase Cloud Messaging |
| File Storage | Firebase Storage |
| Hosting | Railway |

---

## Project Structure

```
slotwise/
├── slotwise-app/          # Flutter frontend
│   └── lib/
│       ├── core/          # Constants, theme, utilities
│       ├── data/          # Models and services
│       ├── features/      # Screens by feature
│       ├── providers/     # State management
│       └── widgets/       # Shared widgets
│
└── slotwise-backend/      # Node.js backend
    ├── config/            # Database and Firebase config
    ├── controllers/       # Route logic
    ├── middleware/        # Auth middleware
    ├── routes/            # API route definitions
    └── utils/             # JWT and FCM helpers
```

---

## Getting Started

### Prerequisites

- Flutter SDK (3.x+)
- Node.js (18.x+)
- MySQL (local) or Railway account
- Firebase project with Auth, FCM, and Storage enabled

---

### Backend Setup

**1. Clone the repository and navigate to the backend:**
```bash
git clone https://github.com/YOUR_USERNAME/slotwise-backend.git
cd slotwise-backend
npm install
```

**2. Create a `.env` file in the root:**
```env
PORT=4000
NODE_ENV=development
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=slotwise
JWT_SECRET=your_jwt_secret
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=your_client_email
```

**3. Import the database schema:**
```bash
mysql -u root -p slotwise < slotwise_schema.sql
```

**4. Start the server:**
```bash
npm run dev
```

The API will be available at `http://localhost:4000`. Test it at `http://localhost:4000/health`.

---

### Flutter Setup

**1. Clone the repository:**
```bash
git clone https://github.com/YOUR_USERNAME/slotwise-app.git
cd slotwise-app
flutter pub get
```

**2. Configure Firebase:**
- Add your `google-services.json` to `android/app/`
- The `firebase_options.dart` file is already configured for this project

**3. Update the API base URL:**

In `lib/core/constants/api_constants.dart`:
```dart
// For local development:
static const String baseUrl = 'http://YOUR_LOCAL_IP:4000/api';

// For production (Railway):
static const String baseUrl = 'https://your-app.railway.app/api';
```

**4. Run the app:**
```bash
flutter run
```

---

### Building the APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/SlotWise.apk`

---

## Deployment (Railway)

The backend and MySQL database are hosted on [Railway](https://railway.app).

1. Push the backend to GitHub
2. Create a new Railway project — deploy from GitHub
3. Add a MySQL database service
4. Set environment variables on the backend service, linking DB vars to the MySQL service:
   ```
   DB_HOST     → ${{MySQL.MYSQLHOST}}
   DB_USER     → ${{MySQL.MYSQLUSER}}
   DB_PASSWORD → ${{MySQL.MYSQLPASSWORD}}
   DB_NAME     → ${{MySQL.MYSQLDATABASE}}
   DB_PORT     → ${{MySQL.MYSQLPORT}}
   ```
5. Import `slotwise_schema.sql` into Railway's MySQL
6. Generate a public domain under Settings → Networking
7. Update `api_constants.dart` with the Railway URL and rebuild the APK

---

## API Overview

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/register` | Public | Register new user |
| POST | `/api/auth/login` | Public | Login → JWT |
| GET | `/api/services` | Public | List services |
| POST | `/api/bookings` | JWT | Create booking |
| GET | `/api/bookings/me` | JWT | User's bookings |
| PUT | `/api/bookings/:id/cancel` | JWT | Cancel booking |
| GET | `/api/admin/stats` | Admin | Dashboard stats |
| GET | `/api/admin/bookings` | Admin | All bookings |
| PUT | `/api/admin/bookings/:id/status` | Admin | Update status |
| POST | `/api/slots/bulk` | Admin | Bulk create slots |

Full API documentation is available in the [Technical Documentation](./docs/technical_documentation.md).

---

## Environment Variables Reference

| Variable | Description |
|---|---|
| `PORT` | Server port (default: 4000) |
| `DB_HOST` | MySQL host |
| `DB_PORT` | MySQL port |
| `DB_USER` | MySQL username |
| `DB_PASSWORD` | MySQL password |
| `DB_NAME` | MySQL database name |
| `JWT_SECRET` | Secret key for JWT signing |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `FIREBASE_PRIVATE_KEY` | Firebase Admin SDK private key |
| `FIREBASE_CLIENT_EMAIL` | Firebase Admin SDK client email |

---

## License

This project was developed as a capstone submission for CSC1002 — Mobile Application Development, Amber Academy, Cohort 4, 2026.

---

## Developers

**Javaughn Douglas**

**Raphiel Collins**

**Daniel Moncrieffe**

Amber Academy — Cohort 4, 2026