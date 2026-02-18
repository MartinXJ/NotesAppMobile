import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/models/enums.dart';
import '../../data/models/recurrence_rule.dart';
import '../repositories/task_repository.dart';

/// Result when completing a recurring task
class RecurringCompleteResult {
  final String taskTitle;
  final bool generated;
  final int taskId;

  RecurringCompleteResult({
    required this.taskTitle,
    required this.generated,
    required this.taskId,
  });
}

/// Service for task management business logic
class TaskService extends ChangeNotifier {
  final TaskRepository _repository;

  List<Task> _tasks = [];
  TaskFilter _filter = TaskFilter.pending;
  TaskSort _sort = TaskSort.dueDate;

  TaskService(this._repository);

  List<Task> get tasks => _filteredAndSorted;
  TaskFilter get filter => _filter;
  TaskSort get sort => _sort;

  List<Task> get _filteredAndSorted {
    var filtered = List<Task>.from(_tasks);

    // Apply filter
    switch (_filter) {
      case TaskFilter.pending:
        filtered = filtered.where((t) => !t.isCompleted).toList();
        break;
      case TaskFilter.completed:
        filtered = filtered.where((t) => t.isCompleted).toList();
        break;
      case TaskFilter.all:
        break;
    }

    // Apply sort
    switch (_sort) {
      case TaskSort.dueDate:
        filtered.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TaskSort.priority:
        filtered.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case TaskSort.createdAt:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  Future<void> loadTasks() async {
    _tasks = await _repository.getAllActiveTasks();
    // Auto-archive: permanently delete completed tasks older than 30 days (unless keepForever)
    await _archiveOldCompletedTasks();
    notifyListeners();
  }

  /// Permanently delete completed tasks older than 30 days (unless keepForever)
  Future<void> _archiveOldCompletedTasks() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final toDelete = <int>[];
    for (final task in _tasks) {
      if (task.isCompleted &&
          !task.keepForever &&
          task.completedAt != null &&
          task.completedAt!.isBefore(cutoff)) {
        toDelete.add(task.id);
      }
    }
    for (final id in toDelete) {
      await _repository.permanentlyDeleteTask(id);
    }
    if (toDelete.isNotEmpty) {
      _tasks = await _repository.getAllActiveTasks();
    }
  }

  /// Archive all completed tasks (soft delete, kept for 30 days)
  Future<void> archiveCompleted() async {
    final completed = _tasks.where((t) => t.isCompleted && !t.keepForever).toList();
    for (final task in completed) {
      await _repository.softDeleteTask(task.id);
    }
    await loadTasks();
  }

  Future<int> createTask(Task task) async {
    final id = await _repository.createTask(task);
    await loadTasks();
    return id;
  }

  Future<void> updateTask(Task task) async {
    await _repository.updateTask(task);
    await loadTasks();
  }

  /// Result of completing a recurring task
  /// null = not recurring, true = auto-generated, false = needs confirmation
  Future<RecurringCompleteResult?> toggleComplete(int id) async {
    final task = await _repository.getTaskById(id);
    if (task == null) return null;

    if (!task.isCompleted) {
      task.isCompleted = true;
      task.completedAt = DateTime.now();
      await _repository.updateTask(task);

      // Check if this is a recurring task
      final rule = task.recurrenceRule;
      final isRecurring = rule != null && rule.type.index > 0;

      if (isRecurring) {
        if (task.autoGenerateNext) {
          // Auto-generate without asking
          final next = generateNextOccurrence(task);
          if (next != null) {
            await _repository.createTask(next);
          }
          await loadTasks();
          return RecurringCompleteResult(
            taskTitle: task.title,
            generated: true,
            taskId: id,
          );
        } else {
          // Needs confirmation from UI
          await loadTasks();
          return RecurringCompleteResult(
            taskTitle: task.title,
            generated: false,
            taskId: id,
          );
        }
      }
    } else {
      task.isCompleted = false;
      task.completedAt = null;
      await _repository.updateTask(task);
    }

    await loadTasks();
    return null;
  }

  /// Generate and save the next occurrence for a recurring task
  Future<void> confirmGenerateNext(int completedTaskId, {bool alwaysGenerate = false}) async {
    final task = await _repository.getTaskById(completedTaskId);
    if (task == null) return;

    // Save the "always" preference
    if (alwaysGenerate) {
      task.autoGenerateNext = true;
      await _repository.updateTask(task);
    }

    final next = generateNextOccurrence(task);
    if (next != null) {
      if (alwaysGenerate) next.autoGenerateNext = true;
      await _repository.createTask(next);
    }
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await _repository.softDeleteTask(id);
    await loadTasks();
  }

  Future<void> restoreTask(int id) async {
    await _repository.restoreTask(id);
    await loadTasks();
  }

  /// Get tasks for a specific calendar date
  List<Task> getTasksForDate(DateTime date) {
    return _tasks.where((t) =>
        t.dueDate != null &&
        t.dueDate!.year == date.year &&
        t.dueDate!.month == date.month &&
        t.dueDate!.day == date.day).toList();
  }

  /// Get all dates that have tasks (for calendar indicators)
  Set<DateTime> getDatesWithTasks() {
    return _tasks
        .where((t) => t.dueDate != null)
        .map((t) => DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day))
        .toSet();
  }

  void setFilter(TaskFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSort(TaskSort sort) {
    _sort = sort;
    notifyListeners();
  }

  /// Generate the next occurrence of a recurring task
  Task? generateNextOccurrence(Task completedTask) {
    final rule = completedTask.recurrenceRule;
    if (rule == null || rule.type == RecurrenceType.none) return null;

    final nextDueDate = _computeNextDueDate(completedTask.dueDate, rule);
    if (nextDueDate == null) return null;

    final timeDiff = completedTask.dueDate != null
        ? nextDueDate.difference(completedTask.dueDate!)
        : Duration.zero;

    return Task()
      ..title = completedTask.title
      ..description = completedTask.description
      ..dueDate = nextDueDate
      ..reminderTime = completedTask.reminderTime?.add(timeDiff)
      ..priority = completedTask.priority
      ..isCompleted = false
      ..createdAt = DateTime.now()
      ..modifiedAt = DateTime.now()
      ..isDeleted = false
      ..hasReminder = completedTask.hasReminder
      ..recurrenceRule = rule
      ..autoGenerateNext = completedTask.autoGenerateNext;
  }

  DateTime? _computeNextDueDate(DateTime? current, RecurrenceRule rule) {
    if (current == null) return null;
    switch (rule.type) {
      case RecurrenceType.daily:
        return current.add(const Duration(days: 1));

      case RecurrenceType.weekly:
        if (rule.daysOfWeek.isEmpty) return current.add(const Duration(days: 7));
        // Find next selected weekday after current
        final sortedDays = List<int>.from(rule.daysOfWeek)..sort();
        for (final day in sortedDays) {
          if (day > current.weekday) {
            return current.add(Duration(days: day - current.weekday));
          }
        }
        // Wrap to next week's first selected day
        return current.add(Duration(days: 7 - current.weekday + sortedDays.first));

      case RecurrenceType.monthly:
        final targetDay = rule.dayOfMonth ?? current.day;
        var nextMonth = current.month + 1;
        var nextYear = current.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        final daysInMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        return DateTime(nextYear, nextMonth, targetDay.clamp(1, daysInMonth),
            current.hour, current.minute);

      case RecurrenceType.yearly:
        final targetMonth = rule.month ?? current.month;
        final targetDay = rule.dayOfMonthForYearly ?? current.day;
        final nextYear = current.year + 1;
        final daysInMonth = DateTime(nextYear, targetMonth + 1, 0).day;
        return DateTime(nextYear, targetMonth, targetDay.clamp(1, daysInMonth),
            current.hour, current.minute);

      case RecurrenceType.none:
        return null;
    }
  }
}
