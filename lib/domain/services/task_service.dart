import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/models/enums.dart';
import '../../data/models/recurrence_rule.dart';
import '../repositories/task_repository.dart';

/// Service for task management business logic
class TaskService extends ChangeNotifier {
  final TaskRepository _repository;

  List<Task> _tasks = [];
  TaskFilter _filter = TaskFilter.all;
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
        filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
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
    notifyListeners();
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

  Future<void> toggleComplete(int id) async {
    final task = await _repository.getTaskById(id);
    if (task == null) return;

    if (!task.isCompleted) {
      task.isCompleted = true;
      task.completedAt = DateTime.now();
      await _repository.updateTask(task);

      // Generate next occurrence for recurring tasks
      if (task.recurrenceRule != null && task.recurrenceRule!.type != RecurrenceType.none) {
        final next = generateNextOccurrence(task);
        if (next != null) {
          await _repository.createTask(next);
        }
      }
    } else {
      task.isCompleted = false;
      task.completedAt = null;
      await _repository.updateTask(task);
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
        t.dueDate.year == date.year &&
        t.dueDate.month == date.month &&
        t.dueDate.day == date.day).toList();
  }

  /// Get all dates that have tasks (for calendar indicators)
  Set<DateTime> getDatesWithTasks() {
    return _tasks.map((t) => DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day)).toSet();
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

    final timeDiff = nextDueDate.difference(completedTask.dueDate);

    return Task()
      ..title = completedTask.title
      ..description = completedTask.description
      ..dueDate = nextDueDate
      ..reminderTime = completedTask.reminderTime.add(timeDiff)
      ..priority = completedTask.priority
      ..isCompleted = false
      ..createdAt = DateTime.now()
      ..modifiedAt = DateTime.now()
      ..isDeleted = false
      ..hasReminder = completedTask.hasReminder
      ..recurrenceRule = rule;
  }

  DateTime? _computeNextDueDate(DateTime current, RecurrenceRule rule) {
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
