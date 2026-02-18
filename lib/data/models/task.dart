import 'package:isar/isar.dart';
import 'enums.dart';
import 'recurrence_rule.dart';

part 'task.g.dart';

/// Task model for to-do items and reminders
@collection
class Task {
  /// Auto-increment ID
  Id id = Isar.autoIncrement;

  /// Task title (required)
  @Index(type: IndexType.value, caseSensitive: false)
  late String title;

  /// Optional description
  String? description;

  /// Due date for the task
  @Index()
  late DateTime dueDate;

  /// Reminder time (when to fire notification)
  late DateTime reminderTime;

  /// Priority level
  @enumerated
  TaskPriority priority = TaskPriority.medium;

  /// Whether the task is completed
  late bool isCompleted;

  /// When the task was completed
  DateTime? completedAt;

  /// Creation timestamp
  @Index()
  late DateTime createdAt;

  /// Last modification timestamp
  late DateTime modifiedAt;

  /// Soft delete flag
  late bool isDeleted;

  /// Deletion timestamp
  DateTime? deletedAt;

  /// Whether this task has a reminder enabled
  late bool hasReminder;

  /// Keep this task forever (never auto-delete when completed)
  bool keepForever = false;

  /// Recurrence rule (embedded, nullable)
  RecurrenceRule? recurrenceRule;
}
