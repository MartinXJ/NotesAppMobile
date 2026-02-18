import 'package:isar/isar.dart';
import '../../domain/repositories/note_repository.dart';
import '../database/isar_service.dart';
import '../models/note.dart';
import '../models/note_template.dart';

/// Implementation of NoteRepository using Isar
class NoteRepositoryImpl implements NoteRepository {
  // Note CRUD

  @override
  Future<int> createNote(Note note) async {
    final isar = await IsarService.getInstance();
    return await isar.writeTxn(() async {
      return await isar.notes.put(note);
    });
  }

  @override
  Future<Note?> getNoteById(int id) async {
    final isar = await IsarService.getInstance();
    return await isar.notes.get(id);
  }

  @override
  Future<List<Note>> getAllNotes() async {
    final isar = await IsarService.getInstance();
    return await isar.notes
        .filter()
        .isDeletedEqualTo(false)
        .sortByModifiedAtDesc()
        .findAll();
  }

  @override
  Future<void> updateNote(Note note) async {
    final isar = await IsarService.getInstance();
    note.modifiedAt = DateTime.now();
    note.version++;
    await isar.writeTxn(() async {
      await isar.notes.put(note);
    });
  }

  @override
  Future<void> deleteNote(int id) async {
    final isar = await IsarService.getInstance();
    final note = await isar.notes.get(id);
    if (note != null) {
      note.isDeleted = true;
      note.deletedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.notes.put(note);
      });
    }
  }

  // Template operations

  @override
  Future<int> createTemplate(NoteTemplate template) async {
    final isar = await IsarService.getInstance();
    return await isar.writeTxn(() async {
      return await isar.noteTemplates.put(template);
    });
  }

  @override
  Future<List<NoteTemplate>> getAllTemplates() async {
    final isar = await IsarService.getInstance();
    return await isar.noteTemplates.where().findAll();
  }

  @override
  Future<void> deleteTemplate(int id) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.noteTemplates.delete(id);
    });
  }

  // Template seeding

  /// Seeds default templates if the collection is empty
  Future<void> seedDefaultTemplates() async {
    final existing = await getAllTemplates();
    if (existing.isNotEmpty) return;

    final defaults = [
      NoteTemplate()
        ..name = 'Sermon'
        ..defaultTags = ['sermon']
        ..hasDate = true
        ..hasTitle = true,
      NoteTemplate()
        ..name = 'Journal'
        ..defaultTags = ['journal']
        ..hasDate = false
        ..hasTitle = true,
      NoteTemplate()
        ..name = 'Quick Note'
        ..defaultTags = []
        ..hasDate = false
        ..hasTitle = false,
    ];

    for (final template in defaults) {
      await createTemplate(template);
    }
  }

  // Queries

  @override
  Future<List<String>> getAllTags() async {
    final isar = await IsarService.getInstance();
    final notes = await isar.notes
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
    final allTags = notes.expand((note) => note.tags).toSet().toList();
    allTags.sort();
    return allTags;
  }

  // Trash

  @override
  Future<List<Note>> getDeletedNotes() async {
    final isar = await IsarService.getInstance();
    return await isar.notes
        .filter()
        .isDeletedEqualTo(true)
        .sortByDeletedAtDesc()
        .findAll();
  }

  @override
  Future<void> restoreNote(int id) async {
    final isar = await IsarService.getInstance();
    final note = await isar.notes.get(id);
    if (note != null && note.isDeleted) {
      note.isDeleted = false;
      note.deletedAt = null;
      await isar.writeTxn(() async {
        await isar.notes.put(note);
      });
    }
  }

  @override
  Future<void> permanentlyDeleteNote(int id) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.notes.delete(id);
    });
  }
}
