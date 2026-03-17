import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';
import '../data/services/storage_service.dart';
import '../data/services/api_service.dart';
import '../data/services/fcm_service.dart';
import '../core/constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // ── Safe notify — defers if called during a build frame ────

  void _notify() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // ── Initialise on app launch ───────────────────────────────

  Future<void> initializeAuth() async {
    _isLoading = true;
    _notify();
    try {
      final loggedIn = await _authService.isLoggedIn();
      if (loggedIn) {
        _currentUser = await _authService.getCurrentUser();
        _error = null;
        _registerFcmToken();
      }
    } catch (e) {
      _error = e.toString();
      await StorageService.clearAll();
      _currentUser = null;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  // ── Register ───────────────────────────────────────────────

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    _notify();

    try {
      _currentUser = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      _registerFcmToken();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  // ── Login ──────────────────────────────────────────────────

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    _notify();

    try {
      _currentUser = await _authService.login(email: email, password: password);
      _registerFcmToken();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  // ── Logout ─────────────────────────────────────────────────

  Future<void> logout() async {
    _isLoading = true;
    _notify();
    try {
      await _authService.logout();
      _currentUser = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  // ── Update profile ─────────────────────────────────────────

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (avatarUrl != null) body['avatar_url'] = avatarUrl;

      final res = await _apiService.put(ApiConstants.updateProfile, data: body);
      _currentUser = UserModel.fromJson(res.data['data']['user']);
      _notify();
      return true;
    } catch (e) {
      _error = e.toString();
      _notify();
      return false;
    }
  }

  // ── Refresh current user from backend ─────────────────────

  Future<void> refreshUser() async {
    try {
      _currentUser = await _authService.getCurrentUser();
      _notify();
    } catch (e) {
      _error = e.toString();
      _notify();
    }
  }

  // ── FCM token registration ─────────────────────────────────

  void _registerFcmToken() {
    FCMService().saveTokenToBackend((token) async {
      try {
        await _apiService.post(
          ApiConstants.saveFcmToken,
          data: {'token': token},
        );
        debugPrint('FCM token saved to backend');
      } catch (e) {
        debugPrint('FCM token save failed: $e');
      }
    });
  }

  // ── Helpers ────────────────────────────────────────────────

  void clearError() {
    _error = null;
    _notify();
  }
}
