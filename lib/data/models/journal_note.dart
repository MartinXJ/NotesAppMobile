import 'package:isar/isar.dart';
import 'media_attachment.dart';

part 'journal_note.g.dart';

/// Journal note model for personal journaling
@collection
class JournalNote {
  /// Auto-increment ID
  Id id = Isar.autoIncrement;

  /// Note title
  late String title;

  /// Note content in Quill Delta JSON format
  late String content;

  /// Plain text content for search indexing
  @Index(type: IndexType.value, caseSensitive: false)
  late String plainTextContent;

  /// Creation timestamp
  @Index()
  late DateTime createdAt;

  /// Last modification timestamp
  @Index()
  late DateTime modifiedAt;

  /// Note color in hex format
  late String colorHex;

  /// Tags for categorization
  @Index(type: IndexType.value, caseSensitive: false)
  List<String> tags = [];

  /// Media attachments (images, stickers)
  List<MediaAttachment> mediaAttachments = [];

  /// Device ID that last modified this note
  late String deviceId;

  /// Version counter for conflict resolution
  late int version;

  /// Sync status flag
  late bool isSynced;

  /// Soft delete flag
  late bool isDeleted;

  /// Deletion timestamp
  DateTime? deletedAt;

  /// Remote ID (Google Drive file ID)
  String? remoteId;
}
