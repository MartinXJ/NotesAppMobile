import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../database/isar_service.dart';
import '../models/sermon_note.dart';
import '../models/journal_note.dart';
import '../models/note.dart';
import '../models/app_settings.dart';
import '../models/enums.dart';

/// One-time migration from SermonNote + JournalNote to unified Note collection
class MigrationService {
  /// Runs migration if not already completed. Returns count of migrated notes.
  static Future<int> migrateIfNeeded() async {
    final isar = await IsarService.getInstance();

    // Check if migration already done
    var settings = await isar.appSettings.get(1);
    if (settings != null && settings.notesMigrationComplete) {
      return 0;
    }

    int migrated = 0;

    // Migrate sermon notes
    final sermonNotes = await isar.sermonNotes.where().findAll();
    for (final sermon in sermonNotes) {
      try {
        final note = _sermonNoteToNote(sermon);
        await isar.writeTxn(() async {
          await isar.notes.put(note);
        });
        migrated++;
      } catch (e) {
        // Log error, skip this record, continue
        debugPrint('[DEBUG] Migration error for SermonNote id=${sermon.id}: $e');
      }
    }

    // Migrate journal notes
    final journalNotes = await isar.journalNotes.where().findAll();
    for (final journal in journalNotes) {
      try {
        final note = _journalNoteToNote(journal);
        await isar.writeTxn(() async {
          await isar.notes.put(note);
        });
        migrated++;
      } catch (e) {
        debugPrint('[DEBUG] Migration error for JournalNote id=${journal.id}: $e');
      }
    }

    // Mark migration complete
    settings ??= AppSettings()
      ..themeMode = AppThemeMode.system
      ..autoSync = false
      ..syncIntervalMinutes = 30
      ..defaultNoteColor = '#FF9E9E9E'
      ..fontSize = 16.0;
    settings.notesMigrationComplete = true;
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings!);
    });

    return migrated;
  }

  /// Converts a SermonNote to a unified Note
  static Note _sermonNoteToNote(SermonNote sermon) {
    final tags = List<String>.from(sermon.tags);
    if (!tags.contains('sermon')) {
      tags.add('sermon');
    }

    return Note()
      ..title = sermon.title
      ..content = sermon.content
      ..plainTextContent = sermon.plainTextContent
      ..colorHex = sermon.colorHex
      ..tags = tags
      ..date = sermon.sermonDate
      ..createdAt = sermon.createdAt
      ..modifiedAt = sermon.modifiedAt
      ..deviceId = sermon.deviceId
      ..version = sermon.version
      ..isSynced = sermon.isSynced
      ..isDeleted = sermon.isDeleted
      ..deletedAt = sermon.deletedAt
      ..remoteId = sermon.remoteId
      ..mediaAttachments = sermon.mediaAttachments;
  }

  /// Converts a JournalNote to a unified Note (date = null)
  static Note _journalNoteToNote(JournalNote journal) {
    final tags = List<String>.from(journal.tags);
    if (!tags.contains('journal')) {
      tags.add('journal');
    }

    return Note()
      ..title = journal.title
      ..content = journal.content
      ..plainTextContent = journal.plainTextContent
      ..colorHex = journal.colorHex
      ..tags = tags
      ..date = null
      ..createdAt = journal.createdAt
      ..modifiedAt = journal.modifiedAt
      ..deviceId = journal.deviceId
      ..version = journal.version
      ..isSynced = journal.isSynced
      ..isDeleted = journal.isDeleted
      ..deletedAt = journal.deletedAt
      ..remoteId = journal.remoteId
      ..mediaAttachments = journal.mediaAttachments;
  }
}
