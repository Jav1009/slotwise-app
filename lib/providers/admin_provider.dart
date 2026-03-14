// features/admin/providers/admin_provider.dart
//
// Changes:
//   • fetchDashboardData: reads res.data['data'] (new consistent response shape)
//   • updateBookingStatus: unchanged
//     Today's Bookings stat still shows today only; Pending/Confirmed count all dates.
//   • Added: missed count in stats
//   • Polling: startPolling() / stopPolling() for live dashboard refresh
 //   • _disposed flag: prevents in-flight futures calling notifyListeners after dispose
//   • _initialLoadDone flag: isLoading only true until the FIRST fetch completes.
//     Fixes staff with 0 bookings getting a permanent spinner (the old isEmpty guard
//     would never clear when allBookings stayed empty).
 
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:slot_wise_booking/models/booking_model.dart';
import 'package:slot_wise_booking/services/api_service.dart';
import '../core/constants/api_constants.dart';

class AdminProvider extends ChangeNotifier {
  List<BookingModel> _allBookings = [];
  List<BookingModel>   _todayBookings = [];
  Map<String, dynamic> _stats    = {};
  bool   _isLoading = false;
  bool   _initialLoadDone  = false; // true after the FIRST fetch completes — never resets
  bool   _disposed  = false;   // guard: stops in-flight futures from calling notifyListeners after dispose
  String? _error;
  Timer? _pollTimer;

  List<BookingModel>   get allBookings => _allBookings;
  List<BookingModel>   get todayBookings => _todayBookings;
  Map<String, dynamic> get stats       => _stats;
  // Show spinner only on the very first load — background refreshes are silent.
  // isLoading is true ONLY on first fetch (no data yet) — avoids stuck spinner after logout
  // bool                 get isLoading   => _isLoading;
  bool                 get isLoading   => _isLoading && !_initialLoadDone;

  final _api = ApiService();

  // ── POLLING ────────────────────────────────────────────────
  void startPolling() {
    _pollTimer?.cancel();
    fetchDashboardData();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchDashboardData();
    });
  }
 
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
 
  @override
  void dispose() {
    _disposed = true;
    stopPolling();
    super.dispose();
  }
 
  // ── FETCH DASHBOARD DATA ───────────────────────────────────
  Future<void> fetchDashboardData() async {
    if (_disposed) return;
    _isLoading = true; notifyListeners();
    try {
      // Fetch today's bookings for dashboard stats
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
      
      // Fetch 1: today's bookings only (for "Today's Bookings" stat)
      final todayRes  = await _api.get(ApiConstants.bookings, params: {'date': dateStr});
      final todayList = (todayRes.data is Map ? todayRes.data['data'] : todayRes.data) as List;
      _todayBookings  = todayList
          .map((j) => BookingModel.fromJson(j as Map<String, dynamic>))
          .toList();
 
      // Fetch 2: ALL bookings (for accurate pending/confirmed/missed totals)
      final allRes  = await _api.get(ApiConstants.bookings);
      final allList = (allRes.data is Map ? allRes.data['data'] : allRes.data) as List;
      _allBookings  = allList
          .map((j) => BookingModel.fromJson(j as Map<String, dynamic>))
          .toList();

      // Compute stats from the list
      _stats = {
        'today':     _todayBookings.length,
        'pending':   _allBookings.where((b) => b.status == 'pending').length,
        'confirmed': _allBookings.where((b) => b.status == 'confirmed').length,
        'missed':    _allBookings.where((b) => b.status == 'missed').length,
        'revenue':   _allBookings
            .where((b) => b.status != 'cancelled')
            .fold<double>(0, (sum, b) => sum + b.price),
      };
      _error = null;
    } catch (e) {
      _error = 'Failed to load dashboard data.';
    } finally {
      _isLoading = false;
      _initialLoadDone = true; // spinner cleared permanently after first fetch
      if (!_disposed) notifyListeners();
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