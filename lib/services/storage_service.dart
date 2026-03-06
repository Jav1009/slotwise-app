import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // Create the secure storage instance with Android-specific options
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // encryptedSharedPreferences: true uses EncryptedSharedPreferences
      // which provides hardware-backed encryption on supported devices
      encryptedSharedPreferences: true,
    ),
  );

  // The key under which the JWT is stored
  // Using a constant prevents typos across multiple call sites
  static const String _tokenKey = 'slotwise_jwt_token';

  // ─────────────────────────────────────────────────────────────────
  // Save the JWT token securely after successful login
  // Called by AuthProvider.login() and AuthProvider.register()
  // ─────────────────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // ─────────────────────────────────────────────────────────────────
  // Read the JWT token — called by ApiService Dio interceptor
  // Returns null if no token exists (user not logged in)
  // ─────────────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // ─────────────────────────────────────────────────────────────────
  // Delete the JWT token — called by AuthProvider.logout()
  // After this, getToken() will return null and all API calls
  // will be made without an Authorization header (they will fail
  // with 401, which is the correct behaviour for a logged-out user)
  // ─────────────────────────────────────────────────────────────────
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
