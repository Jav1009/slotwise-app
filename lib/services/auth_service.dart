// lib/services/auth_service.dart
//
// WHAT THIS FILE DOES:
//   All HTTP calls to your Node.js backend auth endpoints.
//   No Firebase Auth. No Supabase. Just your API + bcrypt + JWT.
//
// CHANGE FROM PREVIOUS VERSION:
//   Added: AuthService.getMe() — called by AuthProvider.tryRestoreSession()
//   This fetches GET /api/auth/me using the stored JWT to restore the session
//   on app restart without requiring the user to log in again.
//
// DEPENDS ON:
//   flutter_secure_storage  → stores JWT securely on device
//   firebase_messaging      → gets FCM token (push notifications ONLY)
//   http                    → HTTP requests
//
// NOTE ON BASE URL:
//   10.0.2.2:3000  → Android emulator (maps to your PC's localhost)
//   192.168.x.x    → Physical device (replace with your actual local IP)
//   Run `ipconfig` (Windows) or `ifconfig` (Mac) to find your IP

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// ─── Base URL ─────────────────────────────────────────────────────────────────
// Change to your local IP when testing on a physical device
// 10.0.2.2 works on the Android emulator only
const String _baseUrl =
    'http://192.168.50.147:3000/api'; // ← change for physical device

const _storage = FlutterSecureStorage();
const _tokenKey = 'slotwise_jwt_token'; // Must match StorageService._tokenKey

// ─── Auth Service ─────────────────────────────────────────────────────────────

class AuthService {
  // ── Token helpers ──────────────────────────────────────────────────────────

  // Save JWT to encrypted device storage after login/register
  static Future<void> saveToken(String token) async =>
      _storage.write(key: _tokenKey, value: token);

  // Read stored JWT — used in _authHeaders() for protected requests
  static Future<String?> getToken() async => _storage.read(key: _tokenKey);

  // Delete JWT — called on logout
  static Future<void> deleteToken() async => _storage.delete(key: _tokenKey);

  // Check if a token exists (does NOT validate with server — use getMe() for that)
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Build Authorization header for protected requests
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Register ───────────────────────────────────────────────────────────────
  // POST /api/auth/register
  // Body: { firstName, lastName, email, password }
  // Response: { data: { token, user } }
  // ──────────────────────────────────────────────────────────────────────────
  static Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await saveToken(body['data']['token']);
        await _registerFcmToken(); // Store device token for push notifications
        return AuthResult.success(
          token: body['data']['token'],
          user: _UserData.fromJson(body['data']['user']),
        );
      }

      return AuthResult.failure(body['message'] ?? 'Registration failed.');
    } catch (e) {
      return AuthResult.failure(
        'Could not connect to server. Check your network.',
      );
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  // POST /api/auth/login
  // Body: { email, password }
  // Response: { data: { token, user } }
  // ──────────────────────────────────────────────────────────────────────────
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await saveToken(body['data']['token']);
        await _registerFcmToken();
        return AuthResult.success(
          token: body['data']['token'],
          user: _UserData.fromJson(body['data']['user']),
        );
      }

      return AuthResult.failure(body['message'] ?? 'Login failed.');
    } catch (e) {
      return AuthResult.failure(
        'Could not connect to server. Check your network.',
      );
    }
  }

  // ── Get Current User ───────────────────────────────────────────────────────
  // GET /api/auth/me  (protected)
  // Called by AuthProvider.tryRestoreSession() on app restart
  // Uses the stored JWT to verify the session is still valid
  // ──────────────────────────────────────────────────────────────────────────
  static Future<AuthResult> getMe() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: headers,
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResult.success(
          user: _UserData.fromJson(body['data'] ?? body['user'] ?? body),
        );
      }

      // 401 = expired or invalid token
      return AuthResult.failure(body['message'] ?? 'Session expired.');
    } catch (e) {
      return AuthResult.failure('Could not connect to server.');
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  // POST /api/auth/logout  (protected)
  // Backend clears fcm_token in MySQL — device stops receiving push notifications
  // Then local JWT is deleted
  // ──────────────────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    try {
      final headers = await _authHeaders();
      await http.post(Uri.parse('$_baseUrl/auth/logout'), headers: headers);
    } catch (_) {
      // If server call fails, still log out locally
      // Worst case: user gets one stale notification — not a security issue
    } finally {
      await deleteToken(); // Always clear JWT regardless of server response
    }
  }

  // ── Forgot Password ────────────────────────────────────────────────────────
  // POST /api/auth/forgot-password
  // Backend sends OTP email — always returns 200 to prevent email enumeration
  // ──────────────────────────────────────────────────────────────────────────
  static Future<AuthResult> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResult.success(message: body['message']);
      }

      return AuthResult.failure(body['message'] ?? 'Request failed.');
    } catch (e) {
      return AuthResult.failure('Could not connect to server.');
    }
  }

  // ── Reset Password ─────────────────────────────────────────────────────────
  // POST /api/auth/reset-password
  // Body: { email, otp, newPassword }
  // ──────────────────────────────────────────────────────────────────────────
  static Future<AuthResult> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResult.success(message: body['message']);
      }

      return AuthResult.failure(body['message'] ?? 'Reset failed.');
    } catch (e) {
      return AuthResult.failure('Could not connect to server.');
    }
  }

  // ── FCM Token Registration ─────────────────────────────────────────────────
  // PUT /api/auth/fcm-token  (protected)
  // Called automatically after login and register
  // Stores the device's FCM token in MySQL so backend can send push notifications
  //
  // WHY: Without this, backend has no way to target this specific device.
  //      notificationController.js reads fcm_token from MySQL for every notification.
  // ──────────────────────────────────────────────────────────────────────────
  static Future<void> _registerFcmToken() async {
    try {
      // Request permission — required on iOS, optional on Android 13+
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return; // User denied — no push notifications for this device
      }

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null)
        return; // Firebase not configured or token unavailable

      final headers = await _authHeaders();
      await http.put(
        Uri.parse('$_baseUrl/auth/fcm-token'),
        headers: headers,
        body: jsonEncode({'fcm_token': fcmToken}),
      );
    } catch (_) {
      // Non-fatal — app works without push notifications
    }
  }

  // ── FCM Token Refresh Listener ─────────────────────────────────────────────
  // Firebase occasionally rotates FCM tokens (after reinstall, token expiry, etc.)
  // This keeps MySQL in sync with the latest token
  // Call this once — it's safe to call multiple times (same stream subscription)
  // ──────────────────────────────────────────────────────────────────────────
  static void listenForTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        final headers = await _authHeaders();
        await http.put(
          Uri.parse('$_baseUrl/auth/fcm-token'),
          headers: headers,
          body: jsonEncode({'fcm_token': newToken}),
        );
      } catch (_) {
        // Non-fatal
      }
    });
  }
}

// ─── Internal user data model ─────────────────────────────────────────────────
// Matches the user object returned by your Node.js backend
// This is separate from the app's UserModel to avoid import cycles

class _UserData {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;

  _UserData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });

  // Handles both { firstName, lastName } and { name } formats from backend
  factory _UserData.fromJson(Map<String, dynamic> json) {
    // If backend returns a single 'name' field, split it
    String first = json['firstName'] ?? '';
    String last = json['lastName'] ?? '';
    if (first.isEmpty && json['name'] != null) {
      final parts = (json['name'] as String).trim().split(' ');
      first = parts.first;
      last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return _UserData(
      id: json['id'],
      firstName: first,
      lastName: last,
      email: json['email'],
      role: json['role'] ?? 'user',
    );
  }

  String get fullName => lastName.isEmpty ? firstName : '$firstName $lastName';
}

// ─── Result wrapper ───────────────────────────────────────────────────────────
// Simple success/failure container — avoids throwing exceptions into the UI

class AuthResult {
  final bool success;
  final String? message;
  final String? token;
  final _UserData? user;

  AuthResult._({required this.success, this.message, this.token, this.user});

  factory AuthResult.success({
    String? message,
    String? token,
    _UserData? user,
  }) => AuthResult._(success: true, message: message, token: token, user: user);

  factory AuthResult.failure(String message) =>
      AuthResult._(success: false, message: message);
}
