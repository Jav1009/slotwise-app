// lib/services/image_upload_service.dart
//
// REWRITTEN — removed Supabase dependency entirely.
// Images are now uploaded directly to the Node.js backend as multipart/form-data.
// Backend saves the file and returns a public URL (or a path served statically).
//
// If you later switch to S3 / Cloudinary / Firebase Storage:
//   Only this file needs to change — all screens call the same static methods.
//
// Backend endpoint expected:
//   POST /api/upload/avatar         → { data: { url: "https://..." } }
//   POST /api/upload/service-image  → { data: { url: "https://..." } }
//   Both accept: multipart/form-data with field name "file"
//
// pubspec.yaml dependency needed (already likely present):
//   dio: ^5.x.x

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:slot_wise_booking/services/api_service.dart';
import 'package:slot_wise_booking/services/storage_service.dart';

class ImageUploadService {
  static final ApiService _api = ApiService();

  // ── Upload profile picture ─────────────────────────────────
  // Called by EditProfileScreen after user picks an image.
  //
  // Takes a File (already picked by image_picker in the screen).
  // Returns the public URL string on success.
  // Throws on failure — caller should catch and show error.
  // ----------------------------------------------------------
  static Future<String> uploadProfilePicture(File imageFile) async {
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
        // Content type — Dio infers from filename but explicit is safer
      ),
    });

    // POST /api/upload/avatar  (protected — JWT injected by ApiService interceptor)
    final res = await _api.postFormData('/upload/avatar', formData);
    final url = res.data['data']?['url'] as String?;

    if (url == null || url.isEmpty) {
      throw Exception('Upload succeeded but no URL returned from server.');
    }
    return url;
  }

  // ── Upload service image ───────────────────────────────────
  // Called by ManageServicesScreen when staff sets a service thumbnail.
  // ----------------------------------------------------------
  static Future<String> uploadServiceImage(File imageFile) async {
    final fileName = 'service_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      ),
    });

    final res = await _api.postFormData('/upload/service-image', formData);
    final url = res.data['data']?['url'] as String?;

    if (url == null || url.isEmpty) {
      throw Exception('Upload succeeded but no URL returned from server.');
    }
    return url;
  }
}