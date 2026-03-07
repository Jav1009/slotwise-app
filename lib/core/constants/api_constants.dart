// lib/core/constants/api_constants.dart
// Centralised API endpoint constants.
// Change baseUrl to match your current environment before running.

class ApiConstants {
  // ── Base URL ────────────────────────────────────────────────
  // Android Emulator : http://10.0.2.2:4000/api
  // iOS Simulator    : http://localhost:4000/api
  // Physical Device  : http://YOUR_COMPUTER_IP:4000/api
  static const String baseUrl = 'http://192.168.100.65:4000/api';

  // ── Timeouts ─────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // ── Auth ──────────────────────────────────────────────────────
  static const String register    = '/auth/register';
  static const String login       = '/auth/login';
  static const String currentUser = '/auth/me';

  // ── Services ──────────────────────────────────────────────────
  static const String services = '/services';
  static String serviceById(int id) => '/services/$id';

  // ── Slots ─────────────────────────────────────────────────────
  static const String slots = '/slots';
  static String availableSlots(int serviceId) => '/slots/available/$serviceId';
  static String slotById(int id) => '/slots/$id';

  // ── Bookings (user) ───────────────────────────────────────────
  static const String myBookings    = '/bookings/me';
  static const String createBooking = '/bookings';
  static String cancelBooking(int id) => '/bookings/$id/cancel';

  // ── Admin ─────────────────────────────────────────────────────
  // NOTE: These all require admin JWT — backed by adminOnly middleware
  static const String adminStats    = '/admin/stats';
  static const String adminBookings = '/admin/bookings';
  static String adminUpdateBookingStatus(int id) => '/admin/bookings/$id/status';

  // ── Notifications ─────────────────────────────────────────────
  static const String notifications         = '/notifications';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static String markNotificationRead(int id)   => '/notifications/$id/read';
}