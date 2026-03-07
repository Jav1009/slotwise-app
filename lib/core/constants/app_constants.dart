class AppConstants {
  static const String appName = 'SlotWise';
  static const String baseUrl = 'http://localhost:3000/api'; // Change to your IP for device testing
  
  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  
  // Notification channels
  static const String notificationChannelId = 'slotwise_notifications';
  static const String notificationChannelName = 'Booking Notifications';
  static const String notificationChannelDescription = 'Notifications for booking updates';
  
  // Date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayTimeFormat = 'h:mm a';
  static const String displayDateTimeFormat = 'dd MMM yyyy, h:mm a';
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Booking statuses
  static const List<String> bookingStatuses = ['pending', 'confirmed', 'completed', 'cancelled'];
  
  // Error messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unauthorizedError = 'Session expired. Please login again.';
  
  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}