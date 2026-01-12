import 'package:isar/isar.dart';
import '../../domain/repositories/notes_repository.dart';
import '../database/isar_service.dart';
import '../models/sermon_note.dart';
import '../models/journal_note.dart';

/// Implementation of NotesRepository using Isar
class NotesRepositoryImpl implements NotesRepository {
  // Sermon Note CRUD operations
  
  @override
  Future<int> createSermonNote(SermonNote note) async {
    final isar = await IsarService.getInstance();
    return await isar.writeTxn(() async {
      return await isar.sermonNotes.put(note);
    });
  }

  @override
  Future<SermonNote?> getSermonNoteById(int id) async {
    final isar = await IsarService.getInstance();
    return await isar.sermonNotes.get(id);
  }

  @override
  Future<List<SermonNote>> getAllSermonNotes() async {
    final isar = await IsarService.getInstance();
    return await isar.sermonNotes
        .filter()
        .isDeletedEqualTo(false)
        .sortByModifiedAtDesc()
        .findAll();
  }

  @override
  Future<void> updateSermonNote(SermonNote note) async {
    final isar = await IsarService.getInstance();
    note.modifiedAt = DateTime.now();
    note.version++;
    await isar.writeTxn(() async {
      await isar.sermonNotes.put(note);
    });
  }

  @override
  Future<void> deleteSermonNote(int id) async {
    final isar = await IsarService.getInstance();
    final note = await isar.sermonNotes.get(id);
    if (note != null) {
      note.isDeleted = true;
      note.deletedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.sermonNotes.put(note);
      });
    }
  }

  // Journal Note CRUD operations
  
  @override
  Future<int> createJournalNote(JournalNote note) async {
    final isar = await IsarService.getInstance();
    return await isar.writeTxn(() async {
      return await isar.journalNotes.put(note);
    });
  }

  @override
  Future<JournalNote?> getJournalNoteById(int id) async {
    final isar = await IsarService.getInstance();
    return await isar.journalNotes.get(id);
  }

  @override
  Future<List<JournalNote>> getAllJournalNotes() async {
    final isar = await IsarService.getInstance();
    return await isar.journalNotes
        .filter()
        .isDeletedEqualTo(false)
        .sortByModifiedAtDesc()
        .findAll();
  }

  @override
  Future<void> updateJournalNote(JournalNote note) async {
    final isar = await IsarService.getInstance();
    note.modifiedAt = DateTime.now();
    note.version++;
    await isar.writeTxn(() async {
      await isar.journalNotes.put(note);
    });
  }

  @override
  Future<void> deleteJournalNote(int id) async {
    final isar = await IsarService.getInstance();
    final note = await isar.journalNotes.get(id);
    if (note != null) {
      note.isDeleted = true;
      note.deletedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.journalNotes.put(note);
      });
    }
  }

  // Query operations
  
  @override
  Future<List<String>> getAllTags() async {
    final isar = await IsarService.getInstance();
    
    // Get all unique tags from both sermon and journal notes
    final sermonTags = await isar.sermonNotes
        .filter()
        .isDeletedEqualTo(false)
        .findAll()
        .then((notes) => notes.expand((note) => note.tags).toSet().toList());
    
    final journalTags = await isar.journalNotes
        .filter()
        .isDeletedEqualTo(false)
        .findAll()
        .then((notes) => notes.expand((note) => note.tags).toSet().toList());
    
    // Combine and deduplicate
    final allTags = {...sermonTags, ...journalTags}.toList();
    allTags.sort();
    return allTags;
  }

  // Trash operations
  
  @override
  Future<List<SermonNote>> getDeletedSermonNotes() async {
    final isar = await IsarService.getInstance();
    return await isar.sermonNotes
        .filter()
        .isDeletedEqualTo(true)
        .sortByDeletedAtDesc()
        .findAll();
  }

  @override
  Future<List<JournalNote>> getDeletedJournalNotes() async {
    final isar = await IsarService.getInstance();
    return await isar.journalNotes
        .filter()
        .isDeletedEqualTo(true)
        .sortByDeletedAtDesc()
        .findAll();
  }

  @override
  Future<void> restoreSermonNote(int id) async {
    final isar = await IsarService.getInstance();
    final note = await isar.sermonNotes.get(id);
    if (note != null && note.isDeleted) {
      note.isDeleted = false;
      note.deletedAt = null;
      await isar.writeTxn(() async {
        await isar.sermonNotes.put(note);
      });
    }
  }

  @override
  Future<void> restoreJournalNote(int id) async {
    final isar = await IsarService.getInstance();
    final note = await isar.journalNotes.get(id);
    if (note != null && note.isDeleted) {
      note.isDeleted = false;
      note.deletedAt = null;
      await isar.writeTxn(() async {
        await isar.journalNotes.put(note);
      });
    }
  }

  @override
  Future<void> permanentlyDeleteSermonNote(int id) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.sermonNotes.delete(id);
    });
  }

  @override
  Future<void> permanentlyDeleteJournalNote(int id) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.journalNotes.delete(id);
    });
  }
}
