import 'package:isar/isar.dart';
import 'enums.dart';

part 'app_settings.g.dart';

/// Application settings model (singleton)
@collection
class AppSettings {
  /// Fixed ID for singleton pattern
  Id id = 1;

  /// Theme mode (light, dark, system)
  @enumerated
  late AppThemeMode themeMode;

  /// Auto-sync enabled flag
  late bool autoSync;

  /// Sync interval in minutes
  late int syncIntervalMinutes;

  /// Last sync timestamp
  DateTime? lastSyncTime;

  /// Default note color in hex format
  late String defaultNoteColor;

  /// Font size for notes
  late double fontSize;

  /// Google account email
  String? googleAccountEmail;

  /// Google account ID
  String? googleAccountId;

  /// Whether notes migration from SermonNote/JournalNote to Note is complete
  bool notesMigrationComplete = false;

  /// Media storage limit in MB (0 = unlimited)
  int storageLimitMb = 0;
}
