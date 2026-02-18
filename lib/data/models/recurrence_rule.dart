import 'package:isar/isar.dart';
import 'enums.dart';

part 'recurrence_rule.g.dart';

/// Embedded recurrence rule for task reminders
@embedded
class RecurrenceRule {
  /// Recurrence type (none, daily, weekly, monthly, yearly)
  @enumerated
  RecurrenceType type = RecurrenceType.none;

  /// Days of week for weekly recurrence (1=Mon..7=Sun)
  List<int> daysOfWeek = [];

  /// Day of month for monthly recurrence
  int? dayOfMonth;

  /// Month for yearly recurrence (1-12)
  int? month;

  /// Day of month for yearly recurrence
  int? dayOfMonthForYearly;
}
