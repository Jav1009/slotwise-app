// // ============================================================
// // FILE: lib/features/auth/providers/auth_provider.dart
// // LOCATION: lib/features/auth/providers/auth_provider.dart
// //
// // WHAT CHANGED FROM FIREBASE VERSION:
// //   Removed: import firebase_auth
// //   Removed: FirebaseAuth.instance + FirebaseAuthException
// //   Added:   Supabase.instance.client.auth calls
// //   Added:   AuthException handling (Supabase equivalent)
// //   Logic:   Nearly identical — Supabase has the same signUp/signIn/signOut API
// //
// // THE TWO-SERVICE FLOW (same concept, different SDK):
// //
// //   REGISTER:
// //     1. supabase.auth.signUp(email, password)
// //        → Supabase creates the account, returns a Session with user.id (UUID)
// //        → This UUID is our uid — the bridge to MySQL
// //     2. POST /api/auth/register  { uid, name, email }
// //        → Node creates the MySQL users row linked by uid
// //     3. POST /api/auth/login  { uid }
// //        → Node returns our JWT with role embedded
// //
// //   LOGIN:
// //     1. supabase.auth.signInWithPassword(email, password)
// //        → Supabase verifies password, returns Session with user.id
// //     2. POST /api/auth/login  { uid }
// //        → Node finds MySQL user, returns JWT
// //     3. StorageService.saveToken(jwt) → secure device storage
// //
// //   LOGOUT:
// //     1. supabase.auth.signOut() → clears Supabase session
// //     2. StorageService.deleteToken() → removes our JWT
// //     3. _user = null → app shows LoginScreen
// //
// // KEY DIFFERENCE FROM FIREBASE:
// //   Supabase returns user.id (UUID string) instead of Firebase uid.
// //   We treat it exactly the same — store it in MySQL as the uid column.
// // ============================================================

// import 'package:flutter/material.dart';
// import 'package:slot_wise_booking/models/user_model.dart';
// import 'package:slot_wise_booking/services/api_service.dart';
// import 'package:slot_wise_booking/services/notification_service.dart';
// import 'package:slot_wise_booking/services/storage_service.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // replaces firebase_auth

// class AuthProvider extends ChangeNotifier {
//   // ── State ─────────────────────────────────────────────────────────
//   UserModel? _user;
//   bool _isLoading = false;
//   String? _errorMessage;

//   // ── Getters ───────────────────────────────────────────────────────
//   UserModel? get user => _user;
//   bool get isLoggedIn => _user != null;
//   bool get isAdmin => _user?.isAdmin ?? false;
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;

//   // Supabase auth client (replaces FirebaseAuth.instance)
//   final GoTrueClient _auth = Supabase.instance.client.auth;
//   final ApiService _api = ApiService();

//   //LOGIN
//   Future<bool> login(String email, String password) async {
//     _setLoading(true);
//     try {
//       // Step 1: Supabase verifies email + password
//       final AuthResponse res = await _auth.signInWithPassword(
//         email: email.trim(),
//         password: password,
//       );

//       // res.user!.id is the UUID our bridge key to MySQL uid
//       // The user.id from Supabase is our uid (UUID string)
//       // This is stored in MySQL users.uid and used as the bridge key
//       final String uid = res.user!.id;

//       // Step 2: Get our role-bearing JWT from Node API
//       //Call our Node API with the uid
//       // Node looks up MySQL user by uid, returns JWT with role embedded
//       final apires = await _api.post('/auth/login', {'uid': uid});
//       final String token = apires.data['token'] as String;

//       // Step 3: Store JWT + update app state
//       await StorageService.saveToken(token);
//       _user = UserModel.fromJson(apires.data['user']);
//       _errorMessage = null;
//       notifyListeners();
//       await NotificationService().registerToken();
//        NotificationService().listenForTokenRefresh();
//       return true;
//     } on AuthException catch (e) {
//       // Supabase-specific auth error
//       _errorMessage = _mapError(e.message);
//       notifyListeners();
//       return false;
//     } catch (e) {
//       _errorMessage = 'Login failed. Check your connection.';
//       notifyListeners();
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }

//   //REGISTER
//   Future<bool> register(String name, String email, String password) async {
//     _setLoading(true);
//     try {
//       // Step 1: Supabase creates the account
//       final AuthResponse res = await _auth.signUp(
//         email: email.trim(),
//         password: password,
//       );

//       final String uid = res.user!.id;

//       // Step 2: Create MySQL user record via Node API
//       await _api.post('/auth/register', {
//         'uid': uid,
//         'name': name.trim(),
//         'email': email.trim(),
//       });

//       // Step 3: Auto-login to get JWT and set user state
//       return await login(email, password);
//     } on AuthException catch (e) {
//       _errorMessage = _mapError(e.message);
//       notifyListeners();
//       return false;
//     } catch (e) {
//       _errorMessage = 'Registration failed. Try again.';
//       notifyListeners();
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }

//   //- LOGOUT
//   Future<void> logout() async {
//     await _auth.signOut(); // clears Supabase session
//     await StorageService.deleteToken(); // removes our Node JWT
//     _user = null; // Triggers UI → LoginScreen
//     notifyListeners();
//     await NotificationService().unregisterToken();
//   }

//   // ── HELPERS ────────────────────────────────────────────────────────
//   void _setLoading(bool v) {
//     _isLoading = v;
//     notifyListeners();
//   }

//   // Maps Supabase error messages to user-friendly strings
//   // Supabase uses plain string messages not error codes
//   String _mapError(String msg) {
//     final m = msg.toLowerCase();
//     if (m.contains('invalid login')) return 'Incorrect email or password.';
//     if (m.contains('already registered'))      return 'An account with this email already exists.';
//     if (m.contains('password should be'))      return 'Password must be at least 6 characters.';
//     if (m.contains('email not confirmed'))      return 'Check your email to confirm your account.';
//     if (m.contains('network')) return 'Network error. Check your internet connection.';
    
//     // Return the raw message if we don't recognise it
//     return msg;
//   }
// }

// ============================================================
// FILE: lib/features/auth/providers/auth_provider.dart
//
// WHAT CHANGED FROM PREVIOUS VERSION:
//   Removed: import supabase_flutter
//   Removed: GoTrueClient _auth = Supabase.instance.client.auth
//   Removed: _auth.signInWithPassword(), _auth.signUp(), _auth.signOut()
//   Removed: AuthException handling (Supabase-specific)
//   Removed: uid bridging flow (Supabase UID → Node login)
//
//   Now uses: AuthService (lib/services/auth_service.dart)
//   AuthService calls your Node.js backend directly with email+password
//   bcrypt verifies on the backend, JWT is returned and stored securely
//
// THE FLOW NOW (direct bcrypt + JWT, no third-party auth):
//
//   LOGIN:
//     1. AuthService.login(email, password)
//        → POST /api/auth/login with email+password
//        → Backend: bcrypt.compare() → if match, return JWT + user
//        → AuthService saves JWT to flutter_secure_storage
//        → AuthService registers FCM token automatically
//     2. AuthProvider sets _user from response
//     3. Consumer<AuthProvider> in main.dart rebuilds → correct screen
//
//   REGISTER:
//     1. AuthService.register(name, email, password)
//        → POST /api/auth/register
//        → Backend: bcrypt.hash(password) → INSERT into MySQL → return JWT
//        → AuthService saves JWT + registers FCM token
//     2. AuthProvider sets _user
//
//   LOGOUT:
//     1. AuthService.logout()
//        → POST /api/auth/logout (clears fcm_token in MySQL)
//        → Deletes JWT from flutter_secure_storage
//     2. _user = null → app shows LoginScreen
//
// NOTE ON register() SIGNATURE:
//   RegisterScreen calls: auth.register(name, email, password)
//   AuthService.register() takes: firstName, lastName, email, password
//   We split the single 'name' field on the first space here.
//   If user enters one word (e.g. "Javaughn"), firstName = "Javaughn", lastName = ""
// ============================================================

import 'package:flutter/material.dart';
import 'package:slot_wise_booking/models/user_model.dart';
import 'package:slot_wise_booking/services/auth_service.dart';
import 'package:slot_wise_booking/services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────
  UserModel? _user;
  bool    _isLoading   = false;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────
  UserModel? get user         => _user;
  bool       get isLoggedIn   => _user != null;
  bool       get isAdmin      => _user?.isAdmin ?? false;
  bool       get isLoading    => _isLoading;
  String?    get errorMessage => _errorMessage;

  // ── Login ─────────────────────────────────────────────────────────
  // Called by LoginScreen with (email, password)
  // AuthService handles the HTTP call, JWT storage, and FCM registration
  // ──────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final result = await AuthService.login(
        email: email.trim(),
        password: password,
      );

      if (result.success && result.user != null) {
        // Map AuthService.UserModel → app UserModel
        // (they are compatible — same fields from the same backend response)
        _user = UserModel(
          id:    result.user!.id,
          uid:   '',            // uid column exists in DB but not used for auth
          name:  result.user!.fullName,
          email: result.user!.email,
          role:  result.user!.role,
        );
        _errorMessage = null;

        // Start listening for FCM token rotation
        // Safe to call multiple times — NotificationService is a singleton
        NotificationService().listenForTokenRefresh();

        notifyListeners();
        return true;
      }

      // Backend returned an error (wrong password, account not found, etc.)
      _errorMessage = result.message ?? 'Login failed.';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Register ──────────────────────────────────────────────────────
  // Called by RegisterScreen with (name, email, password)
  // name is a single string — we split it into firstName + lastName
  // ──────────────────────────────────────────────────────────────────
  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      // Split "John Doe" → firstName: "John", lastName: "Doe"
      // Split "Javaughn" → firstName: "Javaughn", lastName: ""
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
        _errorMessage = null;

        NotificationService().listenForTokenRefresh();

        notifyListeners();
        return true;
      }

      _errorMessage = result.message ?? 'Registration failed.';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────
  // Clears fcm_token on backend, deletes local JWT, resets state
  // ──────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    // Unregister FCM token from Firebase before we lose the JWT
    // (NotificationService.unregisterToken calls Firebase deleteToken)
    await NotificationService().unregisterToken();

    // Tell backend to clear fcm_token + delete local JWT
    await AuthService.logout();

    // Reset state — Consumer<AuthProvider> in main.dart rebuilds → LoginScreen
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Check stored session on app start ─────────────────────────────
  // Call this in initState of your root widget if you want to persist
  // login across app restarts without re-entering credentials.
  //
  // Usage in main.dart SlotwiseApp._SlotwiseAppState.initState():
  //   context.read<AuthProvider>().tryRestoreSession();
  // ──────────────────────────────────────────────────────────────────
  Future<void> tryRestoreSession() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) return; // No stored token → show LoginScreen

    try {
      // Token exists — fetch current user from backend to verify it's still valid
      // and to populate _user with fresh data (role may have changed, etc.)
      // We reuse the ApiService through AuthService here for consistency
      // This call uses the stored JWT via the Dio interceptor in ApiService
      final result = await AuthService.getMe();

      if (result.success && result.user != null) {
        _user = UserModel(
          id:    result.user!.id,
          uid:   '',
          name:  result.user!.fullName,
          email: result.user!.email,
          role:  result.user!.role,
        );
        NotificationService().listenForTokenRefresh();
        notifyListeners();
      } else {
        // Token is invalid/expired — clear it
        await AuthService.logout();
      }
    } catch (_) {
      // Can't reach server — keep user logged in with null _user
      // They'll get 401s on API calls which is acceptable offline behaviour
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}