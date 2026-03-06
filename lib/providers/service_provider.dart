// lib/providers/service_provider.dart
// Services state management

import 'package:flutter/foundation.dart';
import '../data/models/service_model.dart';
import '../data/services/api_service.dart';
import '../core/constants/api_constants.dart';

class ServiceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<ServiceModel> _services = [];
  ServiceModel? _selectedService;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<ServiceModel> get services => _services;
  ServiceModel? get selectedService => _selectedService;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Fetch all services
  Future<void> fetchServices() async {
    await Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });
    
    try {
      final response = await _apiService.get(ApiConstants.services);
      
      final List<dynamic> servicesJson = response.data['data']['services'];
      _services = servicesJson
          .map((json) => ServiceModel.fromJson(json))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get service by ID
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
  
  /// Select a service
  void selectService(ServiceModel service) {
    _selectedService = service;
    notifyListeners();
  }
  
  /// Clear selected service
  void clearSelection() {
    _selectedService = null;
    notifyListeners();
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}