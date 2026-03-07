// lib/data/services/auth_service.dart
// Hybrid authentication service: Firebase + Backend API

import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import '../../core/constants/api_constants.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
  ));
  
  /// Register new user
  /// FLOW: Firebase Auth → Get token → Send to backend → Store JWT
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // STEP 1: Create user in Firebase
      final UserCredential userCredential = 
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // STEP 2: Get Firebase ID token
      final String? idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) {
        throw Exception('Failed to get Firebase token');
      }
      
      // STEP 3: Send token to backend
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'firebase_token': idToken,
          'name': name,
          'email': email,
        },
      );
      
      // STEP 4: Extract data
      final data = response.data['data'];
      final String jwtToken = data['token'];
      final UserModel user = UserModel.fromJson(data['user']);
      
      // STEP 5: Store JWT and user data
      await StorageService.saveToken(jwtToken);
      await StorageService.saveUserId(user.id);
      await StorageService.saveUserRole(user.role);
      
      return user;
      
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }
  
  
  /// Login existing user
  /// FLOW: Firebase Auth → Get token → Send to backend → Store JWT
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      // STEP 1: Authenticate with Firebase
      final UserCredential userCredential = 
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // STEP 2: Get Firebase ID token
      final String? idToken = await userCredential.user?.getIdToken();
      print('Firebase Token: $idToken');


      if (idToken == null) {
        throw Exception('Failed to get Firebase token');
      }
      
      // STEP 3: Send token to backend
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'firebase_token': idToken,
        },
      );
      
      // STEP 4: Extract data
      final data = response.data['data'];
      final String jwtToken = data['token'];
      final UserModel user = UserModel.fromJson(data['user']);
      
      // STEP 5: Store JWT and user data
      await StorageService.saveToken(jwtToken);
      await StorageService.saveUserId(user.id);
      await StorageService.saveUserRole(user.role);
      
      return user;
      
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
  
  /// Logout user
  /// Clears both Firebase session and JWT token
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await StorageService.clearAll();
  }
  
  /// Get current Firebase user
  User? get currentFirebaseUser => _firebaseAuth.currentUser;
  
  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await StorageService.getToken();
    final firebaseUser = currentFirebaseUser;
    return token != null && firebaseUser != null;
  }
  
  /// Get current user details from backend
  Future<UserModel> getCurrentUser() async {
    try {
      final token = await StorageService.getToken();
      
      if (token == null) {
        throw Exception('No token found');
      }
      
      final response = await _dio.get(
        ApiConstants.currentUser,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      return UserModel.fromJson(response.data['data']['user']);
      
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Handle Firebase Auth errors
  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication error occurred';
    }
  }
  
  /// Handle Dio (API) errors
  String _handleDioError(DioException e) {
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