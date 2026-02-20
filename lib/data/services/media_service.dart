import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../models/media_attachment.dart';
import '../models/enums.dart';

/// Service for picking, storing, and deleting media attachments
class MediaService {
  static const _uuid = Uuid();

  /// Request limited/selected photo access (Instagram-style)
  /// Returns the permission state
  static Future<PermissionState> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: false,
        ),
      ),
    );
    return result;
  }

  /// Open the system photo picker with limited access support.
  /// Returns a list of [MediaAttachment] copied into app storage.
  /// [maxCount] limits how many images can be selected at once.
  static Future<List<MediaAttachment>> pickImages({int maxCount = 9}) async {
    final permission = await requestPermission();

    if (!permission.hasAccess && permission != PermissionState.limited) {
      if (permission == PermissionState.denied) {
        await PhotoManager.openSetting();
      }
      return [];
    }

    // On Android 14+ / iOS 14+, presentLimited lets user pick which photos to share.
    // After that, load the accessible assets.
    if (permission == PermissionState.limited) {
      await PhotoManager.presentLimited();
    }

    return pickMultipleImages(maxCount: maxCount);
  }

  /// Pick multiple images using the asset picker (multi-select grid UI)
  static Future<List<MediaAttachment>> pickMultipleImages({
    int maxCount = 9,
  }) async {
    final permission = await requestPermission();
    if (!permission.hasAccess && permission != PermissionState.limited) {
      if (permission == PermissionState.denied) {
        await PhotoManager.openSetting();
      }
      return [];
    }

    // Load available assets
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
      ),
    );

    if (albums.isEmpty) return [];

    final recentAlbum = albums.first;
    final assets = await recentAlbum.getAssetListRange(start: 0, end: 300);

    return _assetsToAttachments(assets, maxCount);
  }

  static Future<List<MediaAttachment>> _assetsToAttachments(
    List<AssetEntity> assets,
    int maxCount,
  ) async {
    final attachments = <MediaAttachment>[];
    for (final asset in assets.take(maxCount)) {
      final file = await asset.originFile;
      if (file == null) continue;
      try {
        final saved = await _copyToAppStorage(file, asset.title ?? '');
        attachments.add(MediaAttachment()
          ..localPath = saved
          ..type = MediaType.image
          ..displayName = asset.title
          ..positionX = 0
          ..positionY = 0
          ..width = 300
          ..height = 200);
      } catch (e) {
        debugPrint('[DEBUG] MediaService: copy failed: $e');
      }
    }
    return attachments;
  }

  /// Copy a file into the app's media directory and return the new path
  static Future<String> _copyToAppStorage(File source, String originalName) async {
    final dir = await _mediaDir();
    final ext = p.extension(originalName).isNotEmpty
        ? p.extension(originalName)
        : '.jpg';
    final fileName = '${_uuid.v4()}$ext';
    final dest = File(p.join(dir.path, fileName));
    await source.copy(dest.path);
    return dest.path;
  }

  /// Delete a media file from app storage
  static Future<void> deleteFile(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('[DEBUG] MediaService: delete failed: $e');
    }
  }

  /// Rename a media attachment (updates displayName only — file stays same)
  static MediaAttachment rename(MediaAttachment attachment, String newName) {
    return MediaAttachment()
      ..localPath = attachment.localPath
      ..remotePath = attachment.remotePath
      ..type = attachment.type
      ..displayName = newName.trim().isEmpty ? null : newName.trim()
      ..positionX = attachment.positionX
      ..positionY = attachment.positionY
      ..width = attachment.width
      ..height = attachment.height;
  }

  /// Get or create the app media storage directory
  static Future<Directory> _mediaDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(appDir.path, 'media'));
    if (!await mediaDir.exists()) await mediaDir.create(recursive: true);
    return mediaDir;
  }

  /// Get current media storage usage in bytes
  static Future<int> getCurrentStorageBytes() async {
    try {
      final dir = await _mediaDir();
      int total = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) total += await entity.length();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Format bytes into a human-readable string (e.g. "45.2 MB")
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
