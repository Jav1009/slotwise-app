import 'package:flutter/material.dart';
import '../data/models/service.dart';
import '../data/models/slot.dart';
import '../data/repositories/service_repository.dart';

class ServiceProvider extends ChangeNotifier {
  List<Service> _services = [];
  Service? _selectedService;
  List<Slot> _availableSlots = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  Map<String, dynamic>? _stats;

  List<Service> get services => _services;
  Service? get selectedService => _selectedService;
  List<Slot> get availableSlots => _availableSlots;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get stats => _stats;

  List<Service> get filteredServices {
    if (_searchQuery.isEmpty) return _services;
    return _services.where((service) =>
      service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (service.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  List<Service> get activeServices {
    return _services.where((service) => service.isActive).toList();
  }

  Future<void> fetchServices({bool includeInactive = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ServiceRepository.getAllServices(
        includeInactive: includeInactive
      );
      
      if (response.success) {
        _services = response.data!;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchServiceById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ServiceRepository.getServiceById(id);
      
      if (response.success) {
        _selectedService = response.data;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createService(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ServiceRepository.createService(data);
      
      if (response.success) {
        _services.add(response.data!);
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateService(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ServiceRepository.updateService(id, data);
      
      if (response.success) {
        final index = _services.indexWhere((s) => s.id == id);
        if (index != -1) {
          _services[index] = response.data!;
        }
        if (_selectedService?.id == id) {
          _selectedService = response.data;
        }
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteService(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ServiceRepository.deleteService(id);
      
      if (response.success) {
        _services.removeWhere((s) => s.id == id);
        if (_selectedService?.id == id) {
          _selectedService = null;
        }
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchServiceSlots(int serviceId, String date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ServiceRepository.getServiceSlots(serviceId, date);
      
      if (response.success) {
        _availableSlots = response.data!;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchServiceStats() async {
    try {
      final response = await ServiceRepository.getServiceStats();
      if (response.success) {
        _stats = response.data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch service stats error: $e');
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectService(Service service) {
    _selectedService = service;
    notifyListeners();
  }

  void clearSelectedService() {
    _selectedService = null;
    notifyListeners();
  }

  void clearAvailableSlots() {
    _availableSlots = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}