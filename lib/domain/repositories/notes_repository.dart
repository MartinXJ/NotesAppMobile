import '../../data/models/sermon_note.dart';
import '../../data/models/journal_note.dart';

/// Repository interface for notes management
abstract class NotesRepository {
  // Sermon Note CRUD operations
  Future<int> createSermonNote(SermonNote note);
  Future<SermonNote?> getSermonNoteById(int id);
  Future<List<SermonNote>> getAllSermonNotes();
  Future<void> updateSermonNote(SermonNote note);
  Future<void> deleteSermonNote(int id);
  
  // Journal Note CRUD operations
  Future<int> createJournalNote(JournalNote note);
  Future<JournalNote?> getJournalNoteById(int id);
  Future<List<JournalNote>> getAllJournalNotes();
  Future<void> updateJournalNote(JournalNote note);
  Future<void> deleteJournalNote(int id);
  
  // Query operations
  Future<List<String>> getAllTags();
  
  // Trash operations
  Future<List<SermonNote>> getDeletedSermonNotes();
  Future<List<JournalNote>> getDeletedJournalNotes();
  Future<void> restoreSermonNote(int id);
  Future<void> restoreJournalNote(int id);
  Future<void> permanentlyDeleteSermonNote(int id);
  Future<void> permanentlyDeleteJournalNote(int id);
}
