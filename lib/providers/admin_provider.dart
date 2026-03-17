// lib/providers/admin_provider.dart
// State management for all admin operations.
// Holds dashboard stats, all bookings list, and exposes
// methods for fetching and mutating admin data.

import 'package:flutter/foundation.dart';
import '../data/services/api_service.dart';
import '../core/constants/api_constants.dart';

// ── AdminStats model ──────────────────────────────────────────

class AdminStats {
  final int todayBookings;
  final int totalBookings;
  final double totalRevenue;
  final int activeServices;
  final int pendingBookings;
  final List<Map<String, dynamic>> popularServices;

  AdminStats({
    required this.todayBookings,
    required this.totalBookings,
    required this.totalRevenue,
    required this.activeServices,
    required this.pendingBookings,
    required this.popularServices,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
    todayBookings: j['todayBookings'] ?? 0,
    totalBookings: j['totalBookings'] ?? 0,
    totalRevenue: double.parse((j['totalRevenue'] ?? 0).toString()),
    activeServices: j['activeServices'] ?? 0,
    pendingBookings: j['pendingBookings'] ?? 0,
    popularServices: List<Map<String, dynamic>>.from(
      j['popularServices'] ?? [],
    ),
  );
}

// ── AdminBooking model ────────────────────────────────────────

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

  AdminBooking copyWithStatus(String newStatus) => AdminBooking(
    id: id,
    status: newStatus,
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

  // ── Stats ──────────────────────────────────────────────────

  Future<void> fetchStats() async {
    await Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });
    try {
      final res = await _apiService.get(ApiConstants.adminStats);
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
          if (date != null) 'date': date,
        },
      );
      // Matches { success: true, data: { bookings: [...] } }
      _bookings = (res.data['data']['bookings'] as List)
          .map((b) => AdminBooking.fromJson(b))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Bulk slot creation ─────────────────────────────────────

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

  /// Calls PUT /api/admin/bookings/:id/status
  /// The backend (bookingController) handles sending the push notification
  /// to the user automatically — nothing extra needed here.
  Future<bool> updateBookingStatus(int bookingId, String status) async {
    try {
      await _apiService.put(
        ApiConstants.adminUpdateBookingStatus(bookingId),
        data: {'status': status},
      );

      // Optimistic local update so the UI reflects the change instantly
      final idx = _bookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) {
        _bookings[idx] = _bookings[idx].copyWithStatus(status);
        notifyListeners();
      }

      // Re-fetch stats so revenue and pending count stay accurate
      fetchStats();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
