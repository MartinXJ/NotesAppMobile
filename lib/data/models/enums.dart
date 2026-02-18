/// Type of media attachment
enum MediaType {
  image,
  sticker,
}

/// Theme mode for the application
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Priority level for tasks
enum TaskPriority {
  low,
  medium,
  high,
}

/// Recurrence type for task reminders
enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

/// Filter for task list
enum TaskFilter {
  all,
  pending,
  completed,
}

/// Sort order for task list
enum TaskSort {
  dueDate,
  priority,
  createdAt,
}
