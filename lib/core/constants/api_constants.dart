// lib/core/constants/api_constants.dart
// Full file — adds updateProfile and saveFcmToken endpoints

class ApiConstants {
  static const String baseUrl = 'http://192.168.100.65:4000/api';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Auth
  static const String register    = '/auth/register';
  static const String login       = '/auth/login';
  static const String currentUser = '/auth/me';

  // User / Profile
  static const String updateProfile = '/users/profile';
  static const String saveFcmToken  = '/users/fcm-token';

  // Services
  static const String services = '/services';
  static String serviceById(int id) => '/services/$id';

  // Slots
  static const String slots = '/slots';
  static String availableSlots(int serviceId) => '/slots/available/$serviceId';
  static String slotById(int id) => '/slots/$id';

  // Bookings (user)
  static const String myBookings    = '/bookings/me';
  static const String createBooking = '/bookings';
  static String cancelBooking(int id) => '/bookings/$id/cancel';

  // Admin
  static const String adminStats   = '/admin/stats';
  static const String adminBookings = '/admin/bookings';
  static String adminUpdateBookingStatus(int id) => '/admin/bookings/$id/status';

  // Notifications
  static const String notifications            = '/notifications';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static String markNotificationRead(int id)   => '/notifications/$id/read';

  //Slots
  static const String bulkCreateSlots = '/slots/bulk';

}

