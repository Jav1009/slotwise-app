// core/constants/api_constants.dart
class ApiConstants {
  // Android emulator: 10.0.2.2 maps to your machine's localhost
  // Physical device: replace with your machine's local IP e.g. 192.168.1.5
  // Production: replace with your deployed server URL
  static const String baseUrl = 'http://192.168.50.147:3000/api';

  // Auth
  static const String register     = '/auth/register';
  static const String login        = '/auth/login';
  static const String me           = '/auth/me';

  // Services
  static const String services     = '/services';

  // Slots
  static const String slots        = '/slots';

  // Bookings
  static const String bookings     = '/bookings';
  static const String myBookings   = '/bookings/my';

  // Notifications
  static const String notifications    = '/notifications';
  static const String notificationsAll = '/notifications/read-all';
}