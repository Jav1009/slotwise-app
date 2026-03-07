// lib/providers/service_provider.dart
// Services state management — covers both the public service
// listing used by customers and admin CRUD operations.

import 'package:flutter/foundation.dart';
import '../data/models/service_model.dart';
import '../data/services/api_service.dart';
import '../core/constants/api_constants.dart';

class ServiceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // ── State ──────────────────────────────────────────────────
  List<ServiceModel> _services        = [];
  ServiceModel?      _selectedService;
  bool               _isLoading       = false;
  String?            _error;

  // ── Getters ────────────────────────────────────────────────
  List<ServiceModel> get services        => _services;
  ServiceModel?      get selectedService => _selectedService;
  bool               get isLoading       => _isLoading;
  String?            get error           => _error;

  // ── Helpers ────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // READ
  // ══════════════════════════════════════════════════════════

  /// Fetch all active services from the backend.
  /// Used by both the public ServicesListScreen and admin CRUD screens.
  Future<void> fetchServices() async {
    await Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });

    
try {
  final response = await _apiService.get(ApiConstants.services);
  final List<dynamic> json = response.data['data']['services'];
  _services = json.map((j) => ServiceModel.fromJson(j)).toList();
} catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  

  /// Fetch a single service by id. Returns null on failure.
  Future<ServiceModel?> getServiceById(int id) async {
    try {
      final response = await _apiService.get(ApiConstants.serviceById(id));
      return ServiceModel.fromJson(response.data['data']['service']);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════
  // CREATE  (admin only)
  // ══════════════════════════════════════════════════════════

  /// Create a new service. Expected keys in [data]:
  /// name, description, price, duration (maps to duration_minutes on backend)
  Future<bool> createService(Map<String, dynamic> data) async {
    try {
      // Map the Flutter form key 'duration' → backend key 'duration_minutes'
      final payload = {
        'name':             data['name'],
        'description':      data['description'],
        'price':            data['price'],
        'duration_minutes': data['duration'],
      };
      await _apiService.post(ApiConstants.services, data: payload);
      // Refresh the list so the new service appears immediately
      await fetchServices();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // UPDATE  (admin only)
  // ══════════════════════════════════════════════════════════

  /// Update an existing service by [id].
  /// Same key mapping as createService applies.
  Future<bool> updateService(int id, Map<String, dynamic> data) async {
    try {
      final payload = {
        'name':             data['name'],
        'description':      data['description'],
        'price':            data['price'],
        'duration_minutes': data['duration'],
      };
      await _apiService.put(ApiConstants.serviceById(id), data: payload);
      await fetchServices();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // DELETE  (admin only — soft delete, sets is_active = 0)
  // ══════════════════════════════════════════════════════════

  /// Soft-delete a service. Existing bookings referencing this
  /// service are preserved; it simply disappears from the public list.
  Future<bool> deleteService(int id) async {
    try {
      await _apiService.delete(ApiConstants.serviceById(id));
      await fetchServices();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // SELECTION HELPERS  (used by the booking flow)
  // ══════════════════════════════════════════════════════════

  /// Mark a service as the one the user is currently booking
  void selectService(ServiceModel service) {
    _selectedService = service;
    notifyListeners();
  }

  /// Clear the selected service (called after booking is confirmed)
  void clearSelection() {
    _selectedService = null;
    notifyListeners();
  }

  /// Clear any stored error string
  void clearError() {
    _error = null;
    notifyListeners();
  }
}