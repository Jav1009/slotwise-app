// lib/core/constants/api_constants.dart
// API endpoint constants

class ApiConstants {
  // Base URL - CHANGE THIS FOR YOUR ENVIRONMENT
  // Development options:
  // - Android Emulator: 'http://10.0.2.2:4000/api'
  // - iOS Simulator: 'http://localhost:4000/api'
  // - Physical Device: 'http://YOUR_COMPUTER_IP:4000/api'
  static const String baseUrl = 'http://192.168.100.65:4000/api';
  
  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String currentUser = '/auth/me';
  
  // Services endpoints
  static const String services = '/services';
  static String serviceById(int id) => '/services/$id';
  
  // Slots endpoints
  static String availableSlots(int serviceId) => '/slots/available/$serviceId';
  static const String slots = '/slots';
  
  // Bookings endpoints
  static const String myBookings = '/bookings/me';
  static const String createBooking = '/bookings';
  static String cancelBooking(int id) => '/bookings/$id/cancel';
  
  // Admin endpoints
  static const String adminBookings = '/bookings/admin/all';
  static String adminUpdateBookingStatus(int id) => '/bookings/admin/$id/status';
  
  // Notifications endpoints
  static const String notifications = '/notifications';
  static String markNotificationRead(int id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}