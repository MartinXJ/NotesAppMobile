/// Validation utilities for task creation and editing
library;

/// Returns an error message if the title is invalid, null if valid.
String? validateTaskTitle(String? title) {
  if (title == null || title.trim().isEmpty) {
    return 'Title cannot be empty';
  }
  return null;
}

/// Returns an error message if the reminder time is in the past, null if valid.
String? validateReminderTime(DateTime reminderTime) {
  if (reminderTime.isBefore(DateTime.now())) {
    return 'Reminder time must be in the future';
  }
  return null;
}
