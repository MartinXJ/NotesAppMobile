import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sermon_note.dart';
import '../models/journal_note.dart';
import '../models/app_settings.dart';
import '../models/task.dart';
import '../models/note.dart';
import '../models/note_template.dart';

/// Service for managing Isar database instance
class IsarService {
  static Isar? _isar;
  static String? _testDirectory;

  /// Set test directory for unit tests
  static void setTestDirectory(String path) {
    _testDirectory = path;
  }

  /// Get the Isar instance (singleton)
  static Future<Isar> getInstance() async {
    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }

    final String directory;
    if (_testDirectory != null) {
      directory = _testDirectory!;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      directory = dir.path;
    }
    
    _isar = await Isar.open(
      [
        SermonNoteSchema,
        JournalNoteSchema,
        AppSettingsSchema,
        TaskSchema,
        NoteSchema,
        NoteTemplateSchema,
      ],
      directory: directory,
      name: 'notes_app_db',
      inspector: true, // [DEBUG] Enable Isar Inspector for debugging
    );

    return _isar!;
  }

  /// Close the database
  static Future<void> close() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
      _isar = null;
    }
  }

  /// Clear all data (for testing purposes)
  static Future<void> clearAllData() async {
    final isar = await getInstance();
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}
