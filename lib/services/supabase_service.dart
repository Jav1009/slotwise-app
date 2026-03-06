//

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  //
  static SupabaseClient get _client => Supabase.instance.client;

  //
  //
  static Future<String> uploadAvatar(File imageFile, int uid) async {
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage
        .from('avatars')
        .upload(
          path,
          imageFile,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    //
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  //
  //
  static Future<String> uploadServiceImage(File imageFile, int sid) async {
    final path = '$sid/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage
        .from('services')
        .upload(
          path,
          imageFile,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    //
    return _client.storage.from('services').getPublicUrl(path);
  }

  //
  //
  static Future<void> deleteByUrl(String publicUrl) async {
    try {
      final uri = Uri.parse(publicUrl);
      final segments = uri.pathSegments;
      final idx = segments.indexOf('public') + 1;
      if (idx <= 0 || idx >= segments.length) return;
      final bucket = segments[idx];
      final path = segments.sublist(idx + 1).join('/');
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      print('[SupabaseService] deleteByUrl skipped: $e');
    }
  }
}
