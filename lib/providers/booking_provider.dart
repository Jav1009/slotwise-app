import 'package:flutter/material.dart';
import '../data/models/booking.dart';
import '../data/models/slot.dart';
import '../data/repositories/booking_repository.dart';

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

  Future<bool> createBooking({
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

  Future<bool> cancelBooking(int bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await BookingRepository.cancelBooking(bookingId);
      
      if (response.success) {
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

  // Admin methods
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
        // Update in allBookings
        final index = _allBookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _allBookings[index] = response.data!;
        }
        
        // Also update in myBookings if it exists there
        final myIndex = _myBookings.indexWhere((b) => b.id == bookingId);
        if (myIndex != -1) {
          _myBookings[myIndex] = response.data!;
        }
        
        // Update upcoming if needed
        if (response.data!.isUpcoming) {
          final upcomingIndex = _upcomingBookings.indexWhere((b) => b.id == bookingId);
          if (upcomingIndex != -1) {
            _upcomingBookings[upcomingIndex] = response.data!;
          }
        } else {
          _upcomingBookings.removeWhere((b) => b.id == bookingId);
        }
        
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

  void clearSelectedBooking() {
    _selectedBooking = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}