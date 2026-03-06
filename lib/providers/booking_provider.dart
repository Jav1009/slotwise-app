// lib/providers/booking_provider.dart
// Bookings state management

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/models/booking_model.dart';
import '../data/models/slot_model.dart';
import '../data/services/api_service.dart';
import '../core/constants/api_constants.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<BookingModel> _bookings = [];
  List<SlotModel> _availableSlots = [];
  SlotModel? _selectedSlot;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<BookingModel> get bookings => _bookings;
  List<BookingModel> get upcomingBookings => _bookings
      .where((b) => b.isFuture && b.status != 'cancelled')
      .toList();
  List<BookingModel> get pastBookings => _bookings
      .where((b) => !b.isFuture || b.status == 'cancelled' || b.status == 'completed')
      .toList();
  List<SlotModel> get availableSlots => _availableSlots;
  SlotModel? get selectedSlot => _selectedSlot;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Fetch user's bookings
  Future<void> fetchMyBookings() async {
    await Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });
    
    try {
      final response = await _apiService.get(ApiConstants.myBookings);
      
      final List<dynamic> bookingsJson = response.data['data']['bookings'];
      _bookings = bookingsJson
          .map((json) => BookingModel.fromJson(json))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Fetch available slots for a service on a date
  Future<void> fetchAvailableSlots(int serviceId, DateTime date) async {
    await Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });
    
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      
      final response = await _apiService.get(
        ApiConstants.availableSlots(serviceId),
        queryParameters: {'date': dateString},
      );
      
      final List<dynamic> slotsJson = response.data['data']['slots'];
      _availableSlots = slotsJson
          .map((json) => SlotModel.fromJson(json))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Select a time slot
  void selectSlot(SlotModel slot) {
    _selectedSlot = slot;
    notifyListeners();
  }
  
  /// Clear selected slot
  void clearSelectedSlot() {
    _selectedSlot = null;
    notifyListeners();
  }
  
  /// Create a booking
  Future<bool> createBooking({
    required int serviceId,
    required int slotId,
    String? notes,
  }) async {
    await Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });
    
    try {
      await _apiService.post(
        ApiConstants.createBooking,
        data: {
          'service_id': serviceId,
          'slot_id': slotId,
          'notes': notes,
        },
      );
      
      // Refresh bookings list
      await fetchMyBookings();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Cancel a booking
  Future<bool> cancelBooking(int bookingId) async {
    await Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });
    
    try {
      await _apiService.put(ApiConstants.cancelBooking(bookingId));
      
      // Refresh bookings list
      await fetchMyBookings();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}