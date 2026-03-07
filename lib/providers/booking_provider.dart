// lib/providers/booking_provider.dart
// Bookings state management — covers both user booking flow
// and admin slot management operations.

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/models/booking_model.dart';
import '../data/models/slot_model.dart';
import '../data/services/api_service.dart';
import '../core/constants/api_constants.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // ── State ──────────────────────────────────────────────────
  List<BookingModel> _bookings      = [];
  List<SlotModel>   _availableSlots = [];
  List<SlotModel>   _adminSlots     = []; // All slots for admin view
  SlotModel?        _selectedSlot;
  bool              _isLoading      = false;
  String?           _error;

  // ── Getters ────────────────────────────────────────────────
  List<BookingModel> get bookings       => _bookings;
  List<SlotModel>    get availableSlots => _availableSlots;
  List<SlotModel>    get adminSlots     => _adminSlots;
  SlotModel?         get selectedSlot   => _selectedSlot;
  bool               get isLoading      => _isLoading;
  String?            get error          => _error;

  /// Upcoming = future date + not cancelled
  List<BookingModel> get upcomingBookings => _bookings
      .where((b) => b.isFuture && b.status != 'cancelled')
      .toList();

  /// Past = already happened OR cancelled/completed
  List<BookingModel> get pastBookings => _bookings
      .where((b) => !b.isFuture || b.status == 'cancelled' || b.status == 'completed')
      .toList();

  // ── Helpers ────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // USER BOOKING METHODS
  // ══════════════════════════════════════════════════════════

  /// Fetch the current user's full booking history
  Future<void> fetchMyBookings() async {
    await Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });

    try {
      final response = await _apiService.get(ApiConstants.myBookings);
      final List<dynamic> json = response.data['data']['bookings'];
      _bookings = json.map((j) => BookingModel.fromJson(j)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch available (is_available = true) slots for a service on a date.
  /// Used by the user booking flow (SlotPickerScreen).
  Future<void> fetchAvailableSlots(int serviceId, DateTime date) async {
    await Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final response = await _apiService.get(
        ApiConstants.availableSlots(serviceId),
        queryParameters: {'date': dateStr},
      );
      final List<dynamic> json = response.data['data']['slots'];
      _availableSlots = json.map((j) => SlotModel.fromJson(j)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Select a slot in the booking flow
  void selectSlot(SlotModel slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  /// Clear the selected slot (called after booking is confirmed)
  void clearSelectedSlot() {
    _selectedSlot = null;
    notifyListeners();
  }

  /// Create a booking for the current user.
  /// Returns true on success, false on failure.
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
          'slot_id':    slotId,
          'notes':      notes,
        },
      );
      // Refresh the bookings list so My Bookings screen is up to date
      await fetchMyBookings();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Cancel one of the current user's bookings.
  /// Returns true on success, false on failure.
  Future<bool> cancelBooking(int bookingId) async {
    await Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });

    try {
      await _apiService.put(ApiConstants.cancelBooking(bookingId));
      await fetchMyBookings();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // ADMIN SLOT METHODS
  // ══════════════════════════════════════════════════════════

  /// Fetch ALL slots for a given date (admin view — includes booked slots).
  /// Uses GET /slots?date=YYYY-MM-DD
  Future<void> fetchAdminSlots({required String date}) async {
    await Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });

    try {
      final response = await _apiService.get(
        ApiConstants.slots,
        queryParameters: {'date': date},
      );
      final List<dynamic> json = response.data['data']['slots'];
      _adminSlots = json.map((j) => SlotModel.fromJson(j)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new time slot (admin only).
  /// Returns true on success, false on failure.
  Future<bool> createSlot({
    required int serviceId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      await _apiService.post(
        ApiConstants.slots,
        data: {
          'service_id': serviceId,
          'date':       date,
          'start_time': startTime,
          'end_time':   endTime,
        },
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a slot by id (admin only).
  /// Backend rejects the request if the slot has any booking history.
  /// Removes the slot from local state immediately for a snappy UI.
  Future<bool> deleteSlot(int slotId) async {
    try {
      await _apiService.delete(ApiConstants.slotById(slotId));
      // Optimistic local removal — no need to re-fetch the whole list
      _adminSlots.removeWhere((s) => s.id == slotId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Shared helpers ─────────────────────────────────────────

  /// Clears any stored error string
  void clearError() {
    _error = null;
    notifyListeners();
  }
}