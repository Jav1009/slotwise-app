import '../../core/network/api_service.dart';
import '../models/service.dart';

class ServiceRepository {
  static Future<ApiResponse<List<Service>>> getAllServices({
    bool includeInactive = false,
  }) async {
    final response = await ApiService.get(
      '/services?includeInactive=$includeInactive'
    );
    
    if (response.success && response.data != null) {
      final List<dynamic> servicesJson = response.data is List
          ? response.data as List
          : response.data!['data'] as List? ?? [];
      
      final services = servicesJson
          .map((json) => Service.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse.success(services);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to fetch services');
  }

  static Future<ApiResponse<Service>> getServiceById(int id) async {
    final response = await ApiService.get('/services/$id');
    
    if (response.success && response.data != null) {
      final service = Service.fromJson(response.data!);
      return ApiResponse.success(service);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to fetch service');
  }

  static Future<ApiResponse<Service>> createService(Map<String, dynamic> data) async {
    final response = await ApiService.post('/services', data);
    
    if (response.success && response.data != null) {
      final serviceData = response.data!['service'] as Map<String, dynamic>;
      final service = Service.fromJson(serviceData);
      return ApiResponse.success(service);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to create service');
  }

  static Future<ApiResponse<Service>> updateService(
    int id, 
    Map<String, dynamic> data
  ) async {
    final response = await ApiService.put('/services/$id', data);
    
    if (response.success && response.data != null) {
      final serviceData = response.data!['service'] as Map<String, dynamic>;
      final service = Service.fromJson(serviceData);
      return ApiResponse.success(service);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to update service');
  }

  static Future<ApiResponse<void>> deleteService(int id) async {
    final response = await ApiService.delete('/services/$id');
    
    if (response.success) {
      return ApiResponse.success(null, message: response.message);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to delete service');
  }

  static Future<ApiResponse<Map<String, dynamic>>> getServiceStats() async {
    final response = await ApiService.get('/services/stats');
    
    if (response.success && response.data != null) {
      return ApiResponse.success(response.data!);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to fetch service stats');
  }

  static Future<ApiResponse<List<Slot>>> getServiceSlots(
    int serviceId, 
    String date
  ) async {
    final response = await ApiService.get('/services/$serviceId/slots?date=$date');
    
    if (response.success && response.data != null) {
      final List<dynamic> slotsJson = response.data is List
          ? response.data as List
          : response.data!['data'] as List? ?? [];
      
      final slots = slotsJson
          .map((json) => Slot.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse.success(slots);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to fetch slots');
  }
}