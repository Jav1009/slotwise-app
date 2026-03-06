// core/services/api_service.dart
// Central HTTP client using Dio.
//
// WHY DIO instead of http package?
//   Dio supports Interceptors — middleware functions that run before
//   every request. Our RequestInterceptor automatically reads the stored
//   JWT and injects it as an Authorization header on every API call.
//   Without this, we'd have to remember to add the header in every single
//   controller method — error-prone and repetitive.
import 'package:dio/dio.dart';
import 'package:slot_wise_booking/core/constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl:        ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Interceptor: runs before EVERY request
    // Reads JWT from secure storage and injects it into the Authorization header
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException err, handler) {
          // Log all API errors for debugging
          print('[API Error] ${err.requestOptions.method} ${err.requestOptions.path}: ${err.response?.statusCode}');
          return handler.next(err);
        },
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, dynamic data) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, dynamic data) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) =>
      _dio.delete(path);
}