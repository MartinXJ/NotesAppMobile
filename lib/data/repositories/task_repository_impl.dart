import 'package:isar/isar.dart';
import '../../domain/repositories/task_repository.dart';
import '../database/isar_service.dart';
import '../models/task.dart';

/// Implementation of TaskRepository using Isar
class TaskRepositoryImpl implements TaskRepository {
  @override
  Future<int> createTask(Task task) async {
    final isar = await IsarService.getInstance();
    return await isar.writeTxn(() async {
      return await isar.tasks.put(task);
    });
  }

  @override
  Future<Task?> getTaskById(int id) async {
    final isar = await IsarService.getInstance();
    return await isar.tasks.get(id);
  }

  @override
  Future<List<Task>> getAllActiveTasks() async {
    final isar = await IsarService.getInstance();
    return await isar.tasks
        .filter()
        .isDeletedEqualTo(false)
        .sortByDueDate()
        .findAll();
  }

  @override
  Future<List<Task>> getTasksByDateRange(DateTime start, DateTime end) async {
    final isar = await IsarService.getInstance();
    return await isar.tasks
        .filter()
        .isDeletedEqualTo(false)
        .dueDateBetween(start, end)
        .sortByDueDate()
        .findAll();
  }

  @override
  Future<List<Task>> getCompletedTasks() async {
    final isar = await IsarService.getInstance();
    return await isar.tasks
        .filter()
        .isDeletedEqualTo(false)
        .isCompletedEqualTo(true)
        .sortByDueDateDesc()
        .findAll();
  }

  @override
  Future<List<Task>> getDeletedTasks() async {
    final isar = await IsarService.getInstance();
    return await isar.tasks
        .filter()
        .isDeletedEqualTo(true)
        .sortByDeletedAtDesc()
        .findAll();
  }

  @override
  Future<void> updateTask(Task task) async {
    final isar = await IsarService.getInstance();
    task.modifiedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.tasks.put(task);
    });
  }

  @override
  Future<void> softDeleteTask(int id) async {
    final isar = await IsarService.getInstance();
    final task = await isar.tasks.get(id);
    if (task != null) {
      task.isDeleted = true;
      task.deletedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.tasks.put(task);
      });
    }
  }

  @override
  Future<void> restoreTask(int id) async {
    final isar = await IsarService.getInstance();
    final task = await isar.tasks.get(id);
    if (task != null && task.isDeleted) {
      task.isDeleted = false;
      task.deletedAt = null;
      await isar.writeTxn(() async {
        await isar.tasks.put(task);
      });
    }
  }

  @override
  Future<void> permanentlyDeleteTask(int id) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.tasks.delete(id);
    });
  }
}
