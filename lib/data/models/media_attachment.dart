import 'package:isar/isar.dart';
import 'enums.dart';

part 'media_attachment.g.dart';

/// Embedded model for media attachments in notes
@embedded
class MediaAttachment {
  /// Local file path
  late String localPath;

  /// Remote path (Google Drive file ID)
  String? remotePath;

  /// Type of media (image or sticker)
  @enumerated
  late MediaType type;

  /// X position in note
  late double positionX;

  /// Y position in note
  late double positionY;

  /// Width of media
  late double width;

  /// Height of media
  late double height;
}
