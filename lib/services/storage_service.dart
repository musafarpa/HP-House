import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import '../config/constants.dart';

class StorageService {
  final _storage = SupabaseConfig.storage;
  final _uuid = const Uuid();

  // Upload avatar
  Future<String> uploadAvatar(String userId, File file) async {
    final extension = file.path.split('.').last;
    final fileName = '$userId/${_uuid.v4()}.$extension';

    await _storage.from(AppConstants.avatarsBucket).upload(
      fileName,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    return _storage.from(AppConstants.avatarsBucket).getPublicUrl(fileName);
  }

  // Upload room cover
  Future<String> uploadRoomCover(String roomId, File file) async {
    final extension = file.path.split('.').last;
    final fileName = '$roomId/${_uuid.v4()}.$extension';

    await _storage.from(AppConstants.roomCoversBucket).upload(
      fileName,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    return _storage.from(AppConstants.roomCoversBucket).getPublicUrl(fileName);
  }

  // Upload chat media
  Future<String> uploadChatMedia(String conversationId, File file) async {
    final extension = file.path.split('.').last;
    final fileName = '$conversationId/${_uuid.v4()}.$extension';

    await _storage.from(AppConstants.chatMediaBucket).upload(
      fileName,
      file,
    );

    return _storage.from(AppConstants.chatMediaBucket).getPublicUrl(fileName);
  }

  // Delete file
  Future<void> deleteFile(String bucket, String path) async {
    await _storage.from(bucket).remove([path]);
  }

  // Get public URL
  String getPublicUrl(String bucket, String path) {
    return _storage.from(bucket).getPublicUrl(path);
  }
}
