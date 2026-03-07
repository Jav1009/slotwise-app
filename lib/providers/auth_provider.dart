import 'package:flutter/material.dart';
import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/notification_repository.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    _isInitialized = false;
    notifyListeners();

    try {
      final isLoggedIn = await AuthRepository.isLoggedIn();
      
      if (isLoggedIn) {
        final response = await AuthRepository.getProfile();
        
        if (response.success && response.data != null) {
          _currentUser = User.fromJson(response.data!);
        } else {
          // Token might be invalid, logout
          await AuthRepository.logout();
          _currentUser = null;
        }
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthRepository.login(
        email: email,
        password: password,
      );
      
      if (response.success && response.data != null) {
        _currentUser = User.fromJson(response.data!['user']);
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

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthRepository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      
      if (response.success && response.data != null) {
        _currentUser = User.fromJson(response.data!['user']);
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

  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthRepository.updateProfile(
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      
      if (response.success && response.data != null) {
        _currentUser = User.fromJson(response.data!['user']);
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

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await AuthRepository.logout();
    _currentUser = null;

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
