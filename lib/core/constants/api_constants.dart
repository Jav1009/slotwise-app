// core/constants/api_constants.dart
//
// Changes:
//   • Added: profileUpdate — PUT /auth/me  (edit profile)
//   • Added: fcmToken     — PUT /auth/fcm-token
//   • Added: serviceCategories — GET /services/categories
//   • Notifications routes already present, unchanged
class ApiConstants {
  // Android emulator: 10.0.2.2 maps to your machine's localhost
  // Physical device: replace with your machine's local IP e.g. 192.168.1.5
  // Production: replace with your deployed server URL
  static const String baseUrl = 'http://192.168.50.147:3000/api';

  // Auth
  static const String register       = '/auth/register';
  static const String login          = '/auth/login';
  static const String me             = '/auth/me'; // GET (fetch) + PUT (update)
  static const String fcmToken       = '/auth/fcm-token';  // PUT
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword  = '/auth/reset-password';
  static const String logout         = '/auth/logout';

  // Services
  static const String services     = '/services';
  static const String serviceCategories  = '/services/categories';

  // Slots
  static const String slots        = '/slots';
  // Individual slot: '/slots/:id'  — built dynamically in screens

  // Bookings
  static const String bookings     = '/bookings';
  static const String myBookings   = '/bookings/my';
  // Single booking:    '/bookings/:id'
  // Cancel:            '/bookings/:id/cancel'
  // Reschedule:        '/bookings/:id/reschedule'
  // Status update:     '/bookings/:id/status'

  // Notifications
  static const String notifications    = '/notifications';
  static const String notificationsAll = '/notifications/read-all';
  // Mark one read:     '/notifications/:id/read'
}