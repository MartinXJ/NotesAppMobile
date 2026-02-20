import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/media_attachment.dart';
import '../models/enums.dart';
import 'media_service.dart';

/// Service for managing custom sticker collection
class StickerService {
  static const _uuid = Uuid();

  /// Built-in emoji stickers organized by category
  static const List<EmojiCategory> emojiCategories = [
    EmojiCategory(name: 'Faith', emojis: [
      '🙏', '✝️', '📖', '🕊️', '⛪', '🕯️', '👼', '🌟',
      '💒', '🛐', '📿', '🫶',
    ]),
    EmojiCategory(name: 'Hearts', emojis: [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
      '💕', '💖', '💗', '💝',
    ]),
    EmojiCategory(name: 'Expressions', emojis: [
      '😊', '🥰', '😇', '🤗', '😌', '🥲', '😂', '🤩',
      '🫡', '🤔', '💪', '👏',
    ]),
    EmojiCategory(name: 'Nature', emojis: [
      '🌸', '🌺', '🌻', '🌹', '🍃', '🌿', '☀️', '🌈',
      '⭐', '🌙', '🦋', '🌊',
    ]),
    EmojiCategory(name: 'Objects', emojis: [
      '📝', '✏️', '🎵', '🎶', '☕', '🎯', '💡', '🔔',
      '📌', '🏷️', '🎨', '✨',
    ]),
  ];

  /// Get the stickers directory
  static Future<Directory> _stickersDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'stickers'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Save an image from gallery as a custom sticker
  static Future<MediaAttachment?> createFromGallery() async {
    final picked = await MediaService.pickImages(maxCount: 1);
    if (picked.isEmpty) return null;

    final source = File(picked.first.localPath);
    if (!await source.exists()) return null;

    try {
      // Copy to stickers directory
      final dir = await _stickersDir();
      final ext = p.extension(source.path).isNotEmpty
          ? p.extension(source.path)
          : '.png';
      final fileName = '${_uuid.v4()}$ext';
      final dest = File(p.join(dir.path, fileName));
      await source.copy(dest.path);

      // Remove the copy in media dir (it was a temp pick)
      await MediaService.deleteFile(source.path);

      return MediaAttachment()
        ..localPath = dest.path
        ..type = MediaType.sticker
        ..displayName = 'Sticker'
        ..positionX = 0
        ..positionY = 0
        ..width = 120
        ..height = 120;
    } catch (e) {
      debugPrint('[DEBUG] StickerService: create from gallery failed: $e');
      return null;
    }
  }

  /// Create a MediaAttachment for an emoji sticker (rendered as text overlay)
  static MediaAttachment createEmojiSticker(String emoji) {
    return MediaAttachment()
      ..localPath = 'emoji:$emoji'
      ..type = MediaType.sticker
      ..displayName = emoji
      ..positionX = 0
      ..positionY = 0
      ..width = 120
      ..height = 120;
  }

  /// Get all saved custom stickers
  static Future<List<File>> getSavedStickers() async {
    try {
      final dir = await _stickersDir();
      final files = <File>[];
      await for (final entity in dir.list()) {
        if (entity is File) files.add(entity);
      }
      // Sort newest first
      files.sort((a, b) => b.path.compareTo(a.path));
      return files;
    } catch (_) {
      return [];
    }
  }

  /// Delete a custom sticker
  static Future<void> deleteSticker(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('[DEBUG] StickerService: delete failed: $e');
    }
  }
}

/// Category of built-in emoji stickers
class EmojiCategory {
  final String name;
  final List<String> emojis;

  const EmojiCategory({required this.name, required this.emojis});
}
