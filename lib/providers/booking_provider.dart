import 'package:flutter/material.dart';
import '../data/models/booking.dart';
import '../data/models/slot.dart';
import '../data/repositories/booking_repository.dart';
import '../services/notification_service.dart';
import '../core/constants/app_constants.dart';

class BookingProvider extends ChangeNotifier {
  List<Booking> _myBookings = [];
  List<Booking> _upcomingBookings = [];
  Booking? _selectedBooking;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _stats;

  // Admin specific
  List<Booking> _allBookings = [];
  Map<String, dynamic>? _dashboardStats;
  List<Map<String, dynamic>> _analytics = [];

  // Getters
  List<Booking> get myBookings => _myBookings;
  List<Booking> get upcomingBookings => _upcomingBookings;
  Booking? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get stats => _stats;
  List<Booking> get allBookings => _allBookings;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  List<Map<String, dynamic>> get analytics => _analytics;

  // Filtered lists
  List<Booking> get pendingBookings => 
      _myBookings.where((b) => b.isPending).toList();
  
  List<Booking> get confirmedBookings => 
      _myBookings.where((b) => b.isConfirmed).toList();
  
  List<Booking> get completedBookings => 
      _myBookings.where((b) => b.isCompleted).toList();
  
  List<Booking> get cancelledBookings => 
      _myBookings.where((b) => b.isCancelled).toList();

  // Admin filtered lists
  List<Booking> get allPendingBookings => 
      _allBookings.where((b) => b.isPending).toList();
  
  List<Booking> get allConfirmedBookings => 
      _allBookings.where((b) => b.isConfirmed).toList();
  
  List<Booking> get allCompletedBookings => 
      _allBookings.where((b) => b.isCompleted).toList();
  
  List<Booking> get allCancelledBookings => 
      _allBookings.where((b) => b.isCancelled).toList();

  // ============= USER METHODS =============

  Future<void> fetchMyBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await BookingRepository.getMyBookings();
      
      if (response.success) {
        _myBookings = response.data!;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUpcomingBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await BookingRepository.getUpcomingBookings();
      
      if (response.success) {
        _upcomingBookings = response.data!;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBookingById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await BookingRepository.getBookingById(id);
      
      if (response.success) {
        _selectedBooking = response.data;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Enhanced booking creation with push notifications
  Future<bool> createBookingWithNotifications({
    required int serviceId,
    required Slot slot,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await BookingRepository.createBooking(
        serviceId: serviceId,
        slotId: slot.id,
        notes: notes,
      );
      
      if (response.success) {
        final booking = response.data!;
        _myBookings.insert(0, booking);
        if (booking.isUpcoming) {
          _upcomingBookings.add(booking);
        }
        
        // Send push notifications
        await _sendBookingNotifications(booking);
        
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Legacy method for backward compatibility
  Future<bool> createBooking({
    required int serviceId,
    required Slot slot,
    String? notes,
  }) {
    return createBookingWithNotifications(
      serviceId: serviceId,
      slot: slot,
      notes: notes,
    );
  }

  /// Send all notifications for a new booking
  Future<void> _sendBookingNotifications(Booking booking) async {
    try {
      final notificationService = NotificationService();
      
      // 1. Show local confirmation notification
      await notificationService.showLocalNotification(
        id: booking.id,
        title: '✅ Booking Confirmed!',
        body: 'Your appointment for ${booking.serviceName} on ${booking.displayDateTime} has been confirmed.',
        type: 'booking_confirmed',
        data: {
          'type': 'booking_confirmed',
          'booking_id': booking.id,
          'action': 'open_booking',
          'service': booking.serviceName,
          'date': booking.displayDate,
          'time': booking.displayTime,
        },
      );

      // 2. Schedule reminder 1 hour before appointment
      await notificationService.scheduleReminder(
        bookingId: booking.id,
        serviceName: booking.serviceName,
        appointmentTime: booking.dateTime,
      );

      // 3. Notify admins (this would be sent from backend)
      // await _notifyAdmins(booking);
      
      debugPrint('✅ All notifications sent for booking ${booking.id}');
    } catch (e) {
      debugPrint('❌ Error sending notifications: $e');
    }
  }

  Future<bool> cancelBooking(int bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await BookingRepository.cancelBooking(bookingId);
      
      if (response.success) {
        // Get the booking before updating
        final cancelledBooking = _myBookings.firstWhere((b) => b.id == bookingId);
        
        // Update in myBookings
        final index = _myBookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          final updatedBooking = _myBookings[index].copyWith(status: 'cancelled');
          _myBookings[index] = updatedBooking;
        }
        
        // Remove from upcoming
        _upcomingBookings.removeWhere((b) => b.id == bookingId);
        
        // Update selected if needed
        if (_selectedBooking?.id == bookingId) {
          _selectedBooking = _selectedBooking?.copyWith(status: 'cancelled');
        }
        
        // Send cancellation notification
        await _sendCancellationNotification(cancelledBooking);
        
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _sendCancellationNotification(Booking booking) async {
    try {
      await NotificationService().showLocalNotification(
        id: booking.id + 5000, // Different ID to avoid conflict
        title: '❌ Booking Cancelled',
        body: 'Your appointment for ${booking.serviceName} on ${booking.displayDateTime} has been cancelled.',
        type: 'booking_cancelled',
        data: {
          'type': 'booking_cancelled',
          'booking_id': booking.id,
          'action': 'open_booking',
        },
      );
    } catch (e) {
      debugPrint('Error sending cancellation notification: $e');
    }
  }

  Future<void> fetchBookingStats() async {
    try {
      final response = await BookingRepository.getBookingStats();
      if (response.success) {
        _stats = response.data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch booking stats error: $e');
    }
  }

  // ============= ADMIN METHODS =============

  Future<void> fetchAllBookings({
    String? status,
    String? date,
    int? serviceId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await BookingRepository.getAllBookings(
        status: status,
        date: date,
        serviceId: serviceId,
      );
      
      if (response.success) {
        _allBookings = response.data!;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBookingStatus(int bookingId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await BookingRepository.updateBookingStatus(bookingId, status);
      
      if (response.success) {
        final updatedBooking = response.data!;
        
        // Update in allBookings
        final index = _allBookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _allBookings[index] = updatedBooking;
        }
        
        // Also update in myBookings if it exists there
        final myIndex = _myBookings.indexWhere((b) => b.id == bookingId);
        if (myIndex != -1) {
          _myBookings[myIndex] = updatedBooking;
        }
        
        // Update upcoming if needed
        if (updatedBooking.isUpcoming) {
          final upcomingIndex = _upcomingBookings.indexWhere((b) => b.id == bookingId);
          if (upcomingIndex != -1) {
            _upcomingBookings[upcomingIndex] = updatedBooking;
          }
        } else {
          _upcomingBookings.removeWhere((b) => b.id == bookingId);
        }
        
        // Send status update notification
        await _sendStatusUpdateNotification(updatedBooking, status);
        
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _sendStatusUpdateNotification(Booking booking, String newStatus) async {
    String title, body;
    
    switch (newStatus) {
      case 'confirmed':
        title = '✅ Booking Confirmed';
        body = 'Your booking for ${booking.serviceName} has been confirmed!';
        break;
      case 'completed':
        title = '🎉 Service Completed';
        body = 'Thank you for using ${booking.serviceName}. We hope to see you again!';
        break;
      case 'cancelled':
        title = '❌ Booking Cancelled';
        body = 'Your booking for ${booking.serviceName} has been cancelled.';
        break;
      default:
        return;
    }

    try {
      await NotificationService().showLocalNotification(
        id: booking.id + 2000,
        title: title,
        body: body,
        type: 'booking_$newStatus',
        data: {
          'type': 'booking_$newStatus',
          'booking_id': booking.id,
          'action': 'open_booking',
        },
      );
    } catch (e) {
      debugPrint('Error sending status notification: $e');
    }
  }

  Future<void> fetchDashboardStats() async {
    try {
      final response = await BookingRepository.getDashboardStats();
      if (response.success) {
        _dashboardStats = response.data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch dashboard stats error: $e');
    }
  }

  Future<void> fetchAnalytics(String startDate, String endDate) async {
    try {
      final response = await BookingRepository.getBookingAnalytics(
        startDate: startDate,
        endDate: endDate,
      );
      if (response.success) {
        _analytics = response.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch analytics error: $e');
    }
  }

  // ============= UTILITY METHODS =============

  /// Get upcoming bookings count
  int getUpcomingCount() {
    return _myBookings.where((b) => b.isUpcoming).length;
  }

  /// Get past bookings count
  int getPastCount() {
    return _myBookings.where((b) => !b.isUpcoming).length;
  }

  /// Check if user has any active bookings
  bool hasActiveBookings() {
    return _myBookings.any((b) => b.isUpcoming && !b.isCancelled);
  }

  /// Get booking by ID
  Booking? getBookingById(int id) {
    try {
      return _myBookings.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear selected booking
  void clearSelectedBooking() {
    _selectedBooking = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refreshAllData() async {
    await Future.wait([
      fetchMyBookings(),
      fetchUpcomingBookings(),
      fetchBookingStats(),
    ]);
  }
}
