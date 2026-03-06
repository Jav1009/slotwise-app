// lib/data/services/api_service.dart
// Central API service for all HTTP requests

import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
    ));
    
    // Add interceptor to automatically inject JWT token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get token from secure storage
          final token = await StorageService.getToken();
          
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 (unauthorized) - token expired
          if (error.response?.statusCode == 401) {
            // Clear storage and redirect to login
            await StorageService.clearAll();
            // You could also emit an event here to trigger app-wide logout
          }
          
          return handler.next(error);
        },
      ),
    );
  }
  
  // GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // POST request
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // PUT request
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // DELETE request
  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Error handler
  String _handleError(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['message'];
      return message ?? 'Server error occurred';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server response timeout. Please try again.';
    } else {
      return 'Network error. Please check your connection.';
    }
  }
}