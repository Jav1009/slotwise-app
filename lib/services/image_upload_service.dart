// // ============================================================
// // FILE: lib/core/services/image_upload_service.dart
// // LOCATION: lib/core/services/image_upload_service.dart
// //
// // WHAT CHANGED FROM FIREBASE VERSION:
// //   Removed: import firebase_service.dart
// //   Added:   import supabase_service.dart
// //   All calls: FirebaseService.upload... → SupabaseService.upload...
// //   Everything else is identical — same ImagePicker logic, same return types
// //
// // PURPOSE:
// //   Combines ImagePicker (picks the file) with SupabaseService (uploads it).
// //   Screens call one method and get back a URL — no picking or
// //   uploading details to manage in the UI layer.
// //
// // USAGE IN PROFILE SCREEN:
// //   final url = await ImageUploadService.pickAndUploadAvatar(user.id);
// //   if (url != null) {
// //     await _api.put('/auth/profile', {'profile_picture_url': url});
// //   }
// // ============================================================

// import 'dart:io';
// import 'package:image_picker/image_picker.dart';
// import 'supabase_service.dart'; // was: firebase_service.dart

// class ImageUploadService {
//   static final ImagePicker _picker = ImagePicker();

//   // Pick avatar → compress upload to Supabase return URL
//   //
//   // RETURNS:
//   //   String  → Supabase Storage public URL on success
//   //   null    → user cancelled the gallery picker
//   // ----------------------------------------------------------
//   static Future<String?> pickAndUploadAvatar (int userId) async {
//     final XFile? picked = await _picker.pickImage(
//     source: ImageSource.gallery,
//     imageQuality: 70,
//     maxWidth: 400,
//     );

//     if (picked == null) return null; // user cancelled
//     return await SupabaseService.uploadAvatar (File(picked.path), userId);
//   }

//   // Pick service thumbnail upload to Supabase return URL
//   //
//   // RETURNS:
//   //   String  → Supabase Storage public URL on success
//   //   null    → user cancelled the gallery picker
//   // ----------------------------------------------------------
//   static Future<String?> pickAndUploadServiceImage(int serviceId) async {
//     final XFile? picked = await _picker.pickImage(
//     source: ImageSource.gallery,
//     imageQuality: 80,
//     maxWidth: 800,
//     );
//     if (picked == null) return null;
//     return await SupabaseService.uploadServiceImage(File(picked.path), serviceId);
//   }

// }

// lib/services/image_upload_service.dart
//
// WHAT CHANGED FROM PREVIOUS VERSION:
//   Removed: import supabase_service.dart
//   Removed: SupabaseService.uploadAvatar() / uploadServiceImage() calls
//   Added:   Direct multipart upload to your Node.js backend
//
// WHY: Supabase is no longer used. Image uploads now go to your backend.
//   The backend can save to disk (local storage) or forward to any cloud
//   storage you add later (S3, Cloudinary, etc.).
//
// BACKEND ENDPOINT NEEDED:
//   POST /api/upload/avatar         → returns { url: "http://..." }
//   POST /api/upload/service-image  → returns { url: "http://..." }
//   Both accept multipart/form-data with a field named 'image'
//   Both are protected (require JWT)
//
// HOW MULTIPART UPLOAD WORKS:
//   Instead of JSON, we send the file as form-data.
//   The backend uses multer (npm install multer) to receive and save the file.
//   The response is a JSON object with the URL of the saved image.
//
// USAGE IN PROFILE SCREEN (unchanged from before):
//   final url = await ImageUploadService.pickAndUploadAvatar(user.id);
//   if (url != null) {
//     await _api.put('/auth/profile', {'profile_picture_url': url});
//   }

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'storage_service.dart'; // for getToken()
import '../core/constants/api_constants.dart';

class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();

  // ── Pick and upload avatar ─────────────────────────────────────────────────
  // Opens gallery → compresses image → uploads to backend → returns public URL
  //
  // RETURNS:
  //   String  → public URL of the uploaded image
  //   null    → user cancelled the picker OR upload failed
  // ──────────────────────────────────────────────────────────────────────────
  static Future<String?> pickAndUploadAvatar(int userId) async {
    final XFile? picked = await _picker.pickImage(
      source:       ImageSource.gallery,
      imageQuality: 70,  // Compress to ~70% quality
      maxWidth:     400, // Cap width at 400px for avatars
    );

    if (picked == null) return null; // User cancelled

    return await _uploadImage(
      filePath: picked.path,
      endpoint: '/upload/avatar',
      fieldName: 'image',
    );
  }

  // ── Pick and upload service image ──────────────────────────────────────────
  // Same flow but for service thumbnail images (higher quality, wider)
  // ──────────────────────────────────────────────────────────────────────────
  static Future<String?> pickAndUploadServiceImage(int serviceId) async {
    final XFile? picked = await _picker.pickImage(
      source:       ImageSource.gallery,
      imageQuality: 80,  // Slightly higher quality for service images
      maxWidth:     800,
    );

    if (picked == null) return null;

    return await _uploadImage(
      filePath: picked.path,
      endpoint: '/upload/service-image',
      fieldName: 'image',
    );
  }

  // ── Internal multipart upload ──────────────────────────────────────────────
  // Sends the file to your Node.js backend as multipart/form-data
  // The backend uses multer to receive it and returns the URL
  // ──────────────────────────────────────────────────────────────────────────
  static Future<String?> _uploadImage({
    required String filePath,
    required String endpoint,
    required String fieldName,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return null; // Not logged in

      // Build the upload URL from the same base as ApiConstants
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      // Create a multipart request — this is how file uploads work over HTTP
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      final streamedResponse = await request.send();
      final response         = await http.Response.fromStream(streamedResponse);
      final body             = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return body['url'] as String?; // Backend returns { url: "https://..." }
      }

      print('[ImageUploadService] Upload failed: ${body['message']}');
      return null;
    } catch (e) {
      print('[ImageUploadService] Error: $e');
      return null;
    }
  }
}