import '../../core/network/api_service.dart';
import '../models/booking.dart';
import '../models/slot.dart';

class BookingRepository {
  static Future<ApiResponse<List<Booking>>> getMyBookings() async {
    final response = await ApiService.get('/bookings/my');
    
    if (response.success && response.data != null) {
      final List<dynamic> bookingsJson = response.data is List
          ? response.data as List
          : response.data!['data'] as List? ?? [];
      
      final bookings = bookingsJson
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse.success(bookings);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to fetch bookings');
  }

  static Future<ApiResponse<List<Booking>>> getUpcomingBookings() async {
    final response = await ApiService.get('/bookings/upcoming');
    
    if (response.success && response.data != null) {
      final List<dynamic> bookingsJson = response.data is List
          ? response.data as List
          : response.data!['data'] as List? ?? [];
      
      final bookings = bookingsJson
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse.success(bookings);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to fetch upcoming bookings');
  }

  static Future<ApiResponse<Booking>> getBookingById(int id) async {
    final response = await ApiService.get('/bookings/$id');
    
    if (response.success && response.data != null) {
      final booking = Booking.fromJson(response.data!);
      return ApiResponse.success(booking);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to fetch booking');
  }

  static Future<ApiResponse<Booking>> createBooking({
    required int serviceId,
    required int slotId,
    String? notes,
  }) async {
    final response = await ApiService.post('/bookings', {
      'service_id': serviceId,
      'slot_id': slotId,
      'notes': notes,
    });
    
    if (response.success && response.data != null) {
      final bookingData = response.data!['booking'] as Map<String, dynamic>;
      final booking = Booking.fromJson(bookingData);
      return ApiResponse.success(booking);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to create booking');
  }

  static Future<ApiResponse<void>> cancelBooking(int bookingId) async {
    final response = await ApiService.put('/bookings/$bookingId/cancel', {});
    
    if (response.success) {
      return ApiResponse.success(null, message: response.message);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to cancel booking');
  }

  static Future<ApiResponse<Map<String, dynamic>>> getBookingStats() async {
    final response = await ApiService.get('/bookings/stats');
    
    if (response.success && response.data != null) {
      return ApiResponse.success(response.data!);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to fetch booking stats');
  }

  // Admin methods
  static Future<ApiResponse<List<Booking>>> getAllBookings({
    String? status,
    String? date,
    int? serviceId,
  }) async {
    String url = '/admin/bookings?';
    if (status != null) url += 'status=$status&';
    if (date != null) url += 'date=$date&';
    if (serviceId != null) url += 'service_id=$serviceId';
    
    final response = await ApiService.get(url);
    
    if (response.success && response.data != null) {
      final List<dynamic> bookingsJson = response.data is List
          ? response.data as List
          : response.data!['data'] as List? ?? [];
      
      final bookings = bookingsJson
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse.success(bookings);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to fetch all bookings');
  }

  static Future<ApiResponse<Booking>> updateBookingStatus(
    int bookingId, 
    String status
  ) async {
    final response = await ApiService.put('/admin/bookings/$bookingId/status', {
      'status': status,
    });
    
    if (response.success && response.data != null) {
      final bookingData = response.data!['booking'] as Map<String, dynamic>;
      final booking = Booking.fromJson(bookingData);
      return ApiResponse.success(booking);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to update booking status');
  }

  static Future<ApiResponse<Map<String, dynamic>>> getDashboardStats() async {
    final response = await ApiService.get('/admin/dashboard');
    
    if (response.success && response.data != null) {
      return ApiResponse.success(response.data!);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to fetch dashboard stats');
  }

  static Future<ApiResponse<List<Map<String, dynamic>>>> getBookingAnalytics({
    required String startDate,
    required String endDate,
  }) async {
    final response = await ApiService.get(
      '/admin/analytics?start_date=$startDate&end_date=$endDate'
    );
    
    if (response.success && response.data != null) {
      final List<dynamic> analyticsJson = response.data is List
          ? response.data as List
          : response.data!['data'] as List? ?? [];
      
      final analytics = analyticsJson
          .map((json) => json as Map<String, dynamic>)
          .toList();
      
      return ApiResponse.success(analytics);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to fetch analytics');
  }
}