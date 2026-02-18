import '../../data/models/task.dart';

/// Repository interface for task management
abstract class TaskRepository {
  Future<int> createTask(Task task);
  Future<Task?> getTaskById(int id);
  Future<List<Task>> getAllActiveTasks();
  Future<List<Task>> getTasksByDateRange(DateTime start, DateTime end);
  Future<List<Task>> getCompletedTasks();
  Future<List<Task>> getDeletedTasks();
  Future<void> updateTask(Task task);
  Future<void> softDeleteTask(int id);
  Future<void> restoreTask(int id);
  Future<void> permanentlyDeleteTask(int id);
}
