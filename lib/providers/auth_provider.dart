// ============================================================
// FILE: lib/features/auth/providers/auth_provider.dart
//
// CHANGES FROM PREVIOUS VERSION:
//   - Removed ALL Supabase imports and calls
//   - Added AppState enum (loading | authenticated | unauthenticated)
//   - Added tryRestoreSession() — reads stored JWT, calls GET /auth/me
//     to silently restore the session on app start
//   - login/register now call AuthService directly (bcrypt + JWT)
//   - logout clears FCM token, calls backend, wipes local JWT
//
// HOW AUTH STATE PERSISTENCE WORKS:
//   On every app start, SplashScreen calls tryRestoreSession().
//   That method checks flutter_secure_storage for a saved JWT.
//   If found → calls GET /api/auth/me to verify it's still valid.
//   If valid → sets _appState = AppState.authenticated → app routes to home.
//   If invalid/expired → deletes token → sets unauthenticated → LoginScreen.
//   This means users stay logged in between sessions automatically.
//
// FLOW SUMMARY:
//   App cold start
//     → SplashScreen shown (2s minimum for brand feel)
//     → tryRestoreSession() runs concurrently
//     → AppState.loading → .authenticated OR .unauthenticated
//     → SplashScreen listens and navigates to correct screen
// ============================================================

import 'package:flutter/material.dart';
import 'package:slot_wise_booking/models/user_model.dart';
import 'package:slot_wise_booking/services/auth_service.dart';
import 'package:slot_wise_booking/services/notification_service.dart';

// Represents the three possible states the app can be in at startup
enum AppState {
  loading,          // tryRestoreSession() in progress — splash screen showing
  authenticated,    // Valid JWT + user loaded — route to home screen
  unauthenticated,  // No JWT or expired — route to LoginScreen
}

class AuthProvider extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────
  UserModel?  _user;
  AppState    _appState     = AppState.loading; // Starts as loading — splash shows
  bool        _isLoading    = false;            // For login/register button spinners
  String?     _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────
  UserModel? get user         => _user;
  AppState   get appState     => _appState;
  bool       get isLoggedIn   => _appState == AppState.authenticated;
  bool       get isAdmin      => _user?.isAdmin ?? false;
  bool       get isLoading    => _isLoading;
  String?    get errorMessage => _errorMessage;

  // ── Restore session on app start ──────────────────────────────────
  // Called ONCE by SplashScreen immediately after it mounts.
  //
  // Steps:
  //   1. Read JWT from flutter_secure_storage (instant, no network)
  //   2. No JWT → unauthenticated → LoginScreen
  //   3. JWT found → GET /api/auth/me to verify it's still valid
  //   4. Valid → populate _user, set authenticated → Home screen
  //   5. 401 / expired → delete stale token → unauthenticated → LoginScreen
  //   6. Network error + token exists → stay authenticated (offline grace)
  // ──────────────────────────────────────────────────────────────────
  Future<void> tryRestoreSession() async {
    try {
      final hasToken = await AuthService.isLoggedIn();

      if (!hasToken) {
        _appState = AppState.unauthenticated;
        notifyListeners();
        return;
      }

      // Token found — verify with the server
      final result = await AuthService.getMe();

      if (result.success && result.user != null) {
        _user = UserModel(
          id:    result.user!.id,
          uid:   '',
          name:  result.user!.fullName,
          email: result.user!.email,
          role:  result.user!.role,
        );
        _appState = AppState.authenticated;
        // Restart the FCM token refresh listener (doesn't survive app restarts)
        NotificationService().listenForTokenRefresh();
      } else {
        // Token expired or rejected — clear it
        await AuthService.deleteToken();
        _appState = AppState.unauthenticated;
      }
    } catch (_) {
      // Network unreachable — be lenient. If they have a token, show home.
      // API calls will fail with 401 if it's actually invalid — that's fine.
      final hasToken = await AuthService.isLoggedIn();
      _appState = hasToken ? AppState.authenticated : AppState.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  // ── Login ─────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final result = await AuthService.login(
        email: email.trim(),
        password: password,
      );

      if (result.success && result.user != null) {
        _user = UserModel(
          id:    result.user!.id,
          uid:   '',
          name:  result.user!.fullName,
          email: result.user!.email,
          role:  result.user!.role,
        );
        _appState = AppState.authenticated;
        NotificationService().listenForTokenRefresh();
        notifyListeners();
        return true;
      }

      _errorMessage = result.message ?? 'Login failed.';
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Register ──────────────────────────────────────────────────────
  // RegisterScreen calls: auth.register(name, email, password)
  // We split the single name field on the first space.
  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final parts     = name.trim().split(' ');
      final firstName = parts.first;
      final lastName  = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      final result = await AuthService.register(
        firstName: firstName,
        lastName:  lastName,
        email:     email.trim(),
        password:  password,
      );

      if (result.success && result.user != null) {
        _user = UserModel(
          id:    result.user!.id,
          uid:   '',
          name:  result.user!.fullName,
          email: result.user!.email,
          role:  result.user!.role,
        );
        _appState = AppState.authenticated;
        NotificationService().listenForTokenRefresh();
        notifyListeners();
        return true;
      }

      _errorMessage = result.message ?? 'Registration failed.';
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────
  Future<void> logout() async {
    await NotificationService().unregisterToken(); // Delete FCM token from Firebase
    await AuthService.logout();                    // Backend clears fcm_token + delete JWT
    _user     = null;
    _appState = AppState.unauthenticated;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}