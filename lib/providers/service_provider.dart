// features/services/providers/service_provider.dart
//
// Changes:
//   • fetchServices: supports category filter param; reads res.data['data']
//   • Added: fetchCategories() — loads distinct categories for filter chips
//   • Added: selectedCategory state + setCategory()

import 'package:flutter/material.dart';
import 'package:slot_wise_booking/models/service_model.dart';
import 'package:slot_wise_booking/services/api_service.dart';
import '../core/constants/api_constants.dart';

class ServiceProvider extends ChangeNotifier {
  List<ServiceModel> _services   = [];
  List<String>       _categories = [];
  String?            _selectedCategory;
  bool               _isLoading  = false;
  String?            _error;

  List<ServiceModel> get services         => _services;
  List<String>       get categories       => _categories;
  String?            get selectedCategory => _selectedCategory;
  bool               get isLoading        => _isLoading;
  String?            get error            => _error;

  final _api = ApiService();

  // ── FETCH SERVICES ────────────────────────────────────────
  // GET /api/services?search=&category=
  Future<void> fetchServices({String? search, String? category}) async {
    _isLoading = true; notifyListeners();
    try {
      final params = <String, String>{};
      if (search   != null && search.isNotEmpty)   params['search']   = search;
      if (category != null && category.isNotEmpty) params['category'] = category;

      final res    = await _api.get(ApiConstants.services, params: params.isNotEmpty ? params : null);
      
      final list = res.data['data'] as List? ?? res.data as List;
      _services = list
          .map((j) => ServiceModel.fromJson(j as Map<String, dynamic>))
          .toList();
      _error = null;
    } catch (e, stack) {
      // _error = 'Failed to load services. Check your connection.';
      debugPrint('[ServiceProvider.fetchServices] ERROR: $e');
      debugPrint(stack.toString());
      _error = e.toString(); // ← show actual error on screen instead of generic message
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  // ── FETCH CATEGORIES ──────────────────────────────────────
  // GET /api/services/categories
  Future<void> fetchCategories() async {
    try {
      final res = await _api.get('${ApiConstants.services}/categories');
      final list = res.data['data'] as List? ?? [];
      _categories = list.map((c) => c.toString()).toList();
      notifyListeners();
    } catch (_) {
      // Non-fatal — categories just won't show if this fails
    }
  }

  // ── SET CATEGORY FILTER ────────────────────────────────────
  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
    fetchServices(category: category);
  }

  // ── CLEAR FILTERS ──────────────────────────────────────────
  void clearFilters() {
    _selectedCategory = null;
    fetchServices();
  }
}