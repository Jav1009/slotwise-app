// lib/providers/admin_provider.dart
// State management for all admin operations.
// Holds dashboard stats, all bookings list, and exposes methods for fetching and mutating admin data.

import 'package:flutter/foundation.dart';
import '../data/services/api_service.dart';
import '../core/constants/api_constants.dart';

// ── AdminStats ────────────────────────────────────────────────

class AdminStats {
  final int todayBookings;
  final int totalBookings;
  final int pendingBookings;
  final int confirmedBookings;
  final int cancelledBookings;
  final double totalRevenue; // confirmed + completed only (from backend)
  final double
  pendingRevenue; // actual sum of pending booking prices (from backend)
  final int activeServices;
  final List<Map<String, dynamic>> popularServices;

  AdminStats({
    required this.todayBookings,
    required this.totalBookings,
    required this.pendingBookings,
    required this.confirmedBookings,
    required this.cancelledBookings,
    required this.totalRevenue,
    required this.pendingRevenue,
    required this.activeServices,
    required this.popularServices,
  });

  // ── Derived values ────────────────────────────────────────────

  /// Confirmed revenue = totalRevenue (backend already scopes this)
  double get confirmedRevenue => totalRevenue;

  /// Projected = confirmed + pending (best-case if all pending confirm)
  double get projectedRevenue => totalRevenue + pendingRevenue;

  /// Avg revenue per confirmed booking
  double get avgRevenuePerBooking =>
      confirmedBookings > 0 ? totalRevenue / confirmedBookings : 0.0;

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
    todayBookings: j['todayBookings'] ?? 0,
    totalBookings: j['totalBookings'] ?? 0,
    pendingBookings: j['pendingBookings'] ?? 0,
    confirmedBookings: j['confirmedBookings'] ?? 0,
    cancelledBookings: j['cancelledBookings'] ?? 0,
    totalRevenue: double.parse((j['totalRevenue'] ?? 0).toString()),
    pendingRevenue: double.parse((j['pendingRevenue'] ?? 0).toString()),
    activeServices: j['activeServices'] ?? 0,
    popularServices: List<Map<String, dynamic>>.from(
      j['popularServices'] ?? [],
    ),
  );
}

// ── AdminBooking ──────────────────────────────────────────────

class AdminBooking {
  final int id;
  final String status;
  final String customerName;
  final String customerEmail;
  final String serviceName;
  final double price;
  final String date;
  final String startTime;
  final String endTime;
  final String? notes;

  AdminBooking({
    required this.id,
    required this.status,
    required this.customerName,
    required this.customerEmail,
    required this.serviceName,
    required this.price,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.notes,
  });

  factory AdminBooking.fromJson(Map<String, dynamic> j) => AdminBooking(
    id: j['id'],
    status: j['status'],
    customerName: j['customerName'],
    customerEmail: j['customerEmail'],
    serviceName: j['serviceName'],
    price: double.parse((j['price'] ?? 0).toString()),
    date: j['date'],
    startTime: j['start_time'],
    endTime: j['end_time'],
    notes: j['notes'],
  );

  AdminBooking copyWithStatus(String s) => AdminBooking(
    id: id,
    status: s,
    customerName: customerName,
    customerEmail: customerEmail,
    serviceName: serviceName,
    price: price,
    date: date,
    startTime: startTime,
    endTime: endTime,
    notes: notes,
  );
}

// ── AdminProvider ─────────────────────────────────────────────

class AdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  AdminStats? _stats;
  List<AdminBooking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  AdminStats? get stats => _stats;
  List<AdminBooking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  // ── Stats ──────────────────────────────────────────────────

  Future<void> fetchStats({DateTime? startDate, DateTime? endDate}) async {
    await Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });
    try {
      final params = <String, dynamic>{};
      if (startDate != null && endDate != null) {
        params['start_date'] =
            '${startDate.year}-${_pad(startDate.month)}-${_pad(startDate.day)}';
        params['end_date'] =
            '${endDate.year}-${_pad(endDate.month)}-${_pad(endDate.day)}';
      }
      final res = await _apiService.get(
        ApiConstants.adminStats,
        queryParameters: params.isEmpty ? null : params,
      );
      _stats = AdminStats.fromJson(res.data['data']);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Bookings ───────────────────────────────────────────────

  Future<void> fetchAllBookings({String? status, String? date}) async {
    await Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });
    try {
      final res = await _apiService.get(
        ApiConstants.adminBookings,
        queryParameters: {
          if (status != null && status != 'all') 'status': status,
          'date': ?date,
        },
      );
      _bookings = (res.data['data']['bookings'] as List)
          .map((b) => AdminBooking.fromJson(b))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Bulk slots ─────────────────────────────────────────────

  Future<void> bulkCreateSlots(List<Map<String, dynamic>> slots) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _apiService.post(
        ApiConstants.bulkCreateSlots,
        data: {'slots': slots},
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Update booking status ──────────────────────────────────

  Future<bool> updateBookingStatus(int bookingId, String status) async {
    try {
      await _apiService.put(
        ApiConstants.adminUpdateBookingStatus(bookingId),
        data: {'status': status},
      );
      final idx = _bookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) {
        _bookings[idx] = _bookings[idx].copyWithStatus(status);
        notifyListeners();
      }
      fetchStats();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
