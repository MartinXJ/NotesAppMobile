import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:solo_notes/main.dart';
import 'package:solo_notes/domain/services/theme_service.dart';
import 'package:solo_notes/domain/repositories/note_repository.dart';
import 'package:solo_notes/domain/repositories/task_repository.dart';
import 'package:solo_notes/domain/services/task_service.dart';
import 'package:solo_notes/data/models/note.dart';
import 'package:solo_notes/data/models/note_template.dart';
import 'package:solo_notes/data/models/task.dart';

/// Fake NoteRepository for testing (no Isar dependency)
class FakeNoteRepository implements NoteRepository {
  @override
  Future<int> createNote(Note note) async => 1;
  @override
  Future<Note?> getNoteById(int id) async => null;
  @override
  Future<List<Note>> getAllNotes() async => [];
  @override
  Future<void> updateNote(Note note) async {}
  @override
  Future<void> deleteNote(int id) async {}
  @override
  Future<int> createTemplate(NoteTemplate template) async => 1;
  @override
  Future<List<NoteTemplate>> getAllTemplates() async => [];
  @override
  Future<void> deleteTemplate(int id) async {}
  @override
  Future<List<String>> getAllTags() async => [];
  @override
  Future<List<Note>> getDeletedNotes() async => [];
  @override
  Future<void> restoreNote(int id) async {}
  @override
  Future<void> permanentlyDeleteNote(int id) async {}
}

/// Fake TaskRepository for testing
class FakeTaskRepository implements TaskRepository {
  @override
  Future<int> createTask(Task task) async => 1;
  @override
  Future<Task?> getTaskById(int id) async => null;
  @override
  Future<List<Task>> getAllActiveTasks() async => [];
  @override
  Future<List<Task>> getTasksByDateRange(DateTime start, DateTime end) async => [];
  @override
  Future<List<Task>> getCompletedTasks() async => [];
  @override
  Future<List<Task>> getDeletedTasks() async => [];
  @override
  Future<void> updateTask(Task task) async {}
  @override
  Future<void> softDeleteTask(int id) async {}
  @override
  Future<void> restoreTask(int id) async {}
  @override
  Future<void> permanentlyDeleteTask(int id) async {}
}

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    final fakeTaskRepo = FakeTaskRepository();
    final taskService = TaskService(fakeTaskRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          Provider<NoteRepository>(create: (_) => FakeNoteRepository()),
          Provider<TaskRepository>(create: (_) => fakeTaskRepo),
          ChangeNotifierProvider.value(value: taskService),
        ],
        child: const NotesApp(),
      ),
    );

    expect(find.byType(NotesApp), findsOneWidget);
  });
}
