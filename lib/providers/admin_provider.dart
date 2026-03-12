// features/admin/providers/admin_provider.dart
//
// Changes:
//   • fetchDashboardData: reads res.data['data'] (new consistent response shape)
//   • updateBookingStatus: unchanged

import 'package:flutter/material.dart';
import 'package:slot_wise_booking/models/booking_model.dart';
import 'package:slot_wise_booking/services/api_service.dart';
import '../core/constants/api_constants.dart';

class AdminProvider extends ChangeNotifier {
  List<BookingModel> _allBookings = [];
  Map<String, dynamic> _stats    = {};
  bool   _isLoading = false;
  String? _error;

  List<BookingModel>   get allBookings => _allBookings;
  Map<String, dynamic> get stats       => _stats;
  bool                 get isLoading   => _isLoading;

  final _api = ApiService();

  Future<void> fetchDashboardData() async {
    _isLoading = true; notifyListeners();
    try {
      // Fetch today's bookings for dashboard stats
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
      final res = await _api.get(ApiConstants.bookings, params: {'date': dateStr});

      // Accept both { data: [...] } and legacy plain array
      final list = (res.data is Map ? res.data['data'] : res.data) as List;
      
      _allBookings = list
          .map((j) => BookingModel.fromJson(j as Map<String, dynamic>))
          .toList();

      // Compute stats from the list
      _stats = {
        'today':     _allBookings.length,
        'pending':   _allBookings.where((b) => b.status == 'pending').length,
        'confirmed': _allBookings.where((b) => b.status == 'confirmed').length,
        'revenue':   _allBookings
            .where((b) => b.status != 'cancelled')
            .fold<double>(0, (sum, b) => sum + b.price),
      };
      _error = null;
    } catch (e) {
      _error = 'Failed to load dashboard data.';
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<bool> updateBookingStatus(int bookingId, String status) async {
    try {
      await _api.put('${ApiConstants.bookings}/$bookingId/status', {'status': status});
      await fetchDashboardData();
      return true;
    } catch (e) {
      return false;
    }
  }
}