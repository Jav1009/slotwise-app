import 'dart:io';
import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../constants/app_constants.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiResponse.success(T data, {String? message, int? statusCode}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode, Map<String, dynamic>? errors}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }
}

class ApiService {
  static final Dio _dio = DioClient().dio;

  static Future<ApiResponse<Map<String, dynamic>>> get(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, 
    Map<String, dynamic> data
  ) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> put(
    String endpoint, 
    Map<String, dynamic> data
  ) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> patch(
    String endpoint, 
    Map<String, dynamic> data
  ) async {
    try {
      final response = await _dio.patch(endpoint, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  static ApiResponse<Map<String, dynamic>> _handleResponse(Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ApiResponse.success(
        response.data is Map<String, dynamic> 
            ? response.data 
            : {'data': response.data},
        message: response.data?['message'],
        statusCode: response.statusCode,
      );
    }
    
    return ApiResponse.error(
      'Unexpected response: ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  static ApiResponse<Map<String, dynamic>> _handleError(DioException e) {
    if (e.response != null) {
      // Server responded with error
      final data = e.response?.data;
      final message = data is Map<String, dynamic> 
          ? (data['message'] ?? 'An error occurred')
          : 'Server error: ${e.response?.statusCode}';
      
      return ApiResponse.error(
        message,
        statusCode: e.response?.statusCode,
        errors: data is Map<String, dynamic> ? data['errors'] : null,
      );
    } else if (e.type == DioExceptionType.connectionTimeout ||
               e.type == DioExceptionType.receiveTimeout ||
               e.type == DioExceptionType.sendTimeout) {
      return ApiResponse.error(AppConstants.networkError);
    } else if (e.type == DioExceptionType.connectionError) {
      return ApiResponse.error('No internet connection. Please check your network.');
    } else {
      return ApiResponse.error('Network error: ${e.message}');
    }
  }
}
