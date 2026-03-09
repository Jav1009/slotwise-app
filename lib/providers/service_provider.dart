// features/services/providers/service_provider.dart
import 'package:flutter/material.dart';
import 'package:slot_wise_booking/models/service_model.dart';
import 'package:slot_wise_booking/services/api_service.dart';
import '../core/constants/api_constants.dart';

class ServiceProvider extends ChangeNotifier {
  List<ServiceModel> _services   = [];
  bool               _isLoading  = false;
  String?            _error;

  List<ServiceModel> get services  => _services;
  bool               get isLoading => _isLoading;
  String?            get error     => _error;

  final _api = ApiService();

  Future<void> fetchServices({String? search}) async {
    _isLoading = true; notifyListeners();
    try {
      final params = search != null && search.isNotEmpty ? {'search': search} : null;
      final res    = await _api.get(ApiConstants.services, params: params);
      _services    = (res.data as List)
          .map((j) => ServiceModel.fromJson(j as Map<String, dynamic>))
          .toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load services. Check your connection.';
    } finally {
      _isLoading = false; notifyListeners();
    }
  }
}