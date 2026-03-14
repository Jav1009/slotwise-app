// lib/features/auth/providers/auth_provider.dart
//
// Full rewrite — removed Supabase entirely.
// Auth is now handled purely by the Node.js backend (bcrypt + JWT).
//
// REGISTER flow:
//   POST /api/auth/register { firstName, lastName, email, password }
//   → Backend hashes password, inserts user, returns JWT + user object
//   → We store JWT in secure storage + set _user state
//
// LOGIN flow:
//   POST /api/auth/login { email, password }
//   → Backend verifies bcrypt hash, returns JWT + user object
//   → We store JWT + update FCM token
//
// LOGOUT flow:
//   POST /api/auth/logout (protected)
//   → Backend clears FCM token in DB
//   → We delete JWT from storage, clear _user state

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:slot_wise_booking/models/user_model.dart';
import 'package:slot_wise_booking/services/api_service.dart';
import 'package:slot_wise_booking/services/notification_service.dart';
import 'package:slot_wise_booking/services/storage_service.dart';

// enum AppState { authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ────────────────────────────────────────────────
  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isStaff => _user?.isStaff ?? false;
  bool get isStaffOrAdmin => _user?.isStaffOrAdmin ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  // AppState get appState =>
  //     _user != null ? AppState.authenticated : AppState.unauthenticated;

  final ApiService _api = ApiService();

  // ── TRY RESTORE SESSION ────────────────────────────────────
  Future<void> tryRestoreSession() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      // Validate token by fetching user data
      final res = await _api.get('/auth/me');
      _user = UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
      notifyListeners();
    } catch (e) {
      // If token is invalid, delete it
      await StorageService.deleteToken();
    }
  }

  // ── LOGIN ──────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final res = await _api.post('/auth/login', {
        'email': email.trim(),
        'password': password,
      });

      final data = res.data['data'] as Map<String, dynamic>;
      final token = data['token'] as String;

      await StorageService.saveToken(token);
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _errorMessage = null;
      notifyListeners();

      // Register FCM token with backend after successful login
      await NotificationService().registerToken();
      NotificationService().listenForTokenRefresh();

      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Login failed. Check your connection.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── REGISTER ───────────────────────────────────────────────
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final res = await _api.post('/auth/register', {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'password': password,
      });

      final data = res.data['data'] as Map<String, dynamic>;
      final token = data['token'] as String;

      await StorageService.saveToken(token);
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _errorMessage = null;
      notifyListeners();

      await NotificationService().registerToken();
      NotificationService().listenForTokenRefresh();

      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed. Try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── LOGOUT ─────────────────────────────────────────────────
  // Future<void> logout() async {
  //   try {
  //     // Tell backend to clear FCM token (fire-and-forget — don't block logout on failure)
  //     await _api.post('/auth/logout', {});
  //   } catch (_) {}
//
  //   await StorageService.deleteToken();
  //   _user = null;
  //   notifyListeners();
  // }

  // Future<void> logout() async {
  //   // Clear local state FIRST so the UI transitions to LoginScreen immediately.
  //   // Never block the user waiting for a network call to complete.
  //   await StorageService.deleteToken();
  //   _user = null;
  //   notifyListeners();
 //
  //   // Fire-and-forget: tell backend to clear FCM token.
  //   // Wrapped in try/catch so a slow or failed request never hangs the app.
  //   _api.post('/auth/logout', {}).catchError((_) {});
  // }

  Future<void> logout() async {
    // Capture token BEFORE deleting it — the backend needs it to clear the FCM token.
    // If we delete first, ApiService has nothing to put in the Authorization header.
    final token = await StorageService.getToken();
 
    // Clear local state immediately so the UI transitions to LoginScreen.
    await StorageService.deleteToken();
    _user = null;
    notifyListeners();
 
    // Fire-and-forget: tell backend to clear FCM token.
    // Pass token explicitly since storage is already cleared.
    if (token != null) {
      _api.post(
        '/auth/logout',
        {},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      ).catchError((e) => Response(requestOptions: RequestOptions(path: '/auth/logout')));
    }
  }

  // ── REFRESH USER (after profile edit) ─────────────────────
  Future<void> refreshUser() async {
    try {
      final res = await _api.get('/auth/me');
      _user = UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
      notifyListeners();
    } catch (_) {}
  }

  // ── UPDATE USER IN STATE (without API call) ────────────────
  // Used after local edits (e.g., profile picture updated)
  void updateUserState(UserModel updated) {
    _user = updated;
    notifyListeners();
  }

  // ── HELPERS ────────────────────────────────────────────────
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  /// Extracts a user-friendly message from a DioException.
  /// Reads the backend's JSON error body when available.
  String _extractError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data?['message'] as String?;

    if (message != null && message.isNotEmpty) return message;

    switch (statusCode) {
      case 400:
        return 'Please check all fields and try again.';
      case 401:
        return 'Incorrect email or password.';
      case 403:
        return 'Your account has been deactivated. Contact support.';
      case 409:
        return 'An account with this email already exists.';
      default:
        return 'Something went wrong. Check your connection.';
    }
  }
}
