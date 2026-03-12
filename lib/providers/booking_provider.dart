// features/bookings/providers/booking_provider.dart
//
// Changes:
//   • fetchMyBookings: reads res.data['data'] (new consistent response shape)
//   • createBooking: reads res.data['data'] response shape
//   • Added: rescheduleBooking(bookingId, newSlotId)
//   • All filtered getters unchanged

import 'package:flutter/material.dart';
import 'package:slot_wise_booking/models/booking_model.dart';
import 'package:slot_wise_booking/services/api_service.dart';
import '../core/constants/api_constants.dart';

class BookingProvider extends ChangeNotifier {
  List<BookingModel> _bookings  = [];
  bool               _isLoading = false;
  String?            _error;

  List<BookingModel> get bookings  => _bookings;
  bool               get isLoading => _isLoading;
  String?            get error     => _error;

  // Filtered getters used by the TabBar in MyBookingsScreen
  List<BookingModel> get upcoming  => _bookings.where((b) => b.isUpcoming).toList();
  List<BookingModel> get past      => _bookings.where((b) => b.isPast).toList();
  List<BookingModel> get cancelled => _bookings.where((b) => b.isCancelled).toList();

  final _api = ApiService();

  // ── FETCH MY BOOKINGS ──────────────────────────────────────
  // GET /api/bookings/my
  Future<void> fetchMyBookings() async {
    _isLoading = true; notifyListeners();
    try {
      final res  = await _api.get(ApiConstants.myBookings);
      final list = res.data['data'] as List;
      _bookings  = list
          .map((j) => BookingModel.fromJson(j as Map<String, dynamic>))
          .toList();
      _error = null;
    } catch (e) {
      _error = 'Could not load bookings.';
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  // ── CREATE BOOKING ─────────────────────────────────────────
  // POST /api/bookings
  Future<bool> createBooking({
    required int serviceId,
    required int slotId,
    String? notes,
  }) async {
    _isLoading = true; notifyListeners();
    try {
      await _api.post(ApiConstants.bookings, {
        'service_id': serviceId,
        'slot_id':    slotId,
        'notes':      (notes?.isNotEmpty == true) ? notes : null,
      });
      await fetchMyBookings(); // Refresh list after booking
      _error = null;
      return true;
    } catch (e) {
      _error = 'Booking failed. This slot may no longer be available.';
      return false;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  // ── CANCEL BOOKING ─────────────────────────────────────────
  // PUT /api/bookings/:id/cancel
  Future<bool> cancelBooking(int bookingId) async {
    try {
      await _api.put('${ApiConstants.bookings}/$bookingId/cancel', {});
      await fetchMyBookings();
      return true;
    } catch (e) {
      _error = 'Cancellation failed.';
      notifyListeners();
      return false;
    }
  }

  // ── RESCHEDULE BOOKING ─────────────────────────────────────
  // PUT /api/bookings/:id/reschedule  { new_slot_id }
  Future<bool> rescheduleBooking({
    required int bookingId,
    required int newSlotId,
  }) async {
    _isLoading = true; notifyListeners();
    try {
      await _api.put('${ApiConstants.bookings}/$bookingId/reschedule', {
        'new_slot_id': newSlotId,
      });
      await fetchMyBookings();
      _error = null;
      return true;
    } catch (e) {
      _error = 'Reschedule failed. The selected slot may no longer be available.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }
}