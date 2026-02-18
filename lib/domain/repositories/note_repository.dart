import '../../data/models/note.dart';
import '../../data/models/note_template.dart';

/// Repository interface for unified notes management
abstract class NoteRepository {
  // Note CRUD
  Future<int> createNote(Note note);
  Future<Note?> getNoteById(int id);
  Future<List<Note>> getAllNotes();
  Future<void> updateNote(Note note);
  Future<void> deleteNote(int id); // soft delete

  // Template operations
  Future<int> createTemplate(NoteTemplate template);
  Future<List<NoteTemplate>> getAllTemplates();
  Future<void> deleteTemplate(int id);

  // Queries
  Future<List<String>> getAllTags();

  // Trash
  Future<List<Note>> getDeletedNotes();
  Future<void> restoreNote(int id);
  Future<void> permanentlyDeleteNote(int id);
}
