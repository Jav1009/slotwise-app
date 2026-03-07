import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/user.dart';

class AuthRepository {
  static final _storage = const FlutterSecureStorage();

  static Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post('/auth/login', {
      'email': email,
      'password': password,
    });

    if (response.success && response.data != null) {
      final token = response.data!['token'];
      final userData = response.data!['user'];
      
      if (token != null) {
        await _storage.write(key: AppConstants.tokenKey, value: token);
        await _storage.write(
          key: AppConstants.userKey, 
          value: jsonEncode(userData)
        );
        await _storage.write(
          key: AppConstants.userIdKey, 
          value: userData['id'].toString()
        );
        await _storage.write(
          key: AppConstants.userRoleKey, 
          value: userData['role']
        );
      }
    }

    return response;
  }

  static Future<ApiResponse<Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await ApiService.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
    });

    if (response.success && response.data != null) {
      final token = response.data!['token'];
      final userData = response.data!['user'];
      
      if (token != null) {
        await _storage.write(key: AppConstants.tokenKey, value: token);
        await _storage.write(
          key: AppConstants.userKey, 
          value: jsonEncode(userData)
        );
        await _storage.write(
          key: AppConstants.userIdKey, 
          value: userData['id'].toString()
        );
        await _storage.write(
          key: AppConstants.userRoleKey, 
          value: userData['role']
        );
      }
    }

    return response;
  }

  static Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    return await ApiService.get('/auth/me');
  }

  static Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    required String name,
    String? phone,
    String? avatarUrl,
  }) async {
    final response = await ApiService.put('/auth/me', {
      'name': name,
      'phone': phone,
      'avatar_url': avatarUrl,
    });

    if (response.success && response.data != null) {
      final userData = response.data!['user'];
      if (userData != null) {
        await _storage.write(
          key: AppConstants.userKey, 
          value: jsonEncode(userData)
        );
      }
    }

    return response;
  }

  static Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
    await _storage.delete(key: AppConstants.userIdKey);
    await _storage.delete(key: AppConstants.userRoleKey);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  static Future<User?> getStoredUser() async {
    final userData = await _storage.read(key: AppConstants.userKey);
    if (userData != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userData);
        return User.fromJson(userMap);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: AppConstants.userIdKey);
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(key: AppConstants.userRoleKey);
  }

  static Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin';
  }
}
