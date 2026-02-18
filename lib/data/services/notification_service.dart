import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task.dart';
import '../models/enums.dart';
import '../models/recurrence_rule.dart';

/// Callback for handling notification taps (set from main.dart)
typedef NotificationTapCallback = void Function(int taskId);

/// Service for scheduling and managing local notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static NotificationTapCallback? onNotificationTap;

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final taskId = response.id;
        if (taskId != null) {
          onNotificationTap?.call(taskId);
        }
      },
    );

    // Request permissions on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static const _channelId = 'task_reminders';
  static const _channelName = 'Task Reminders';
  static const _channelDesc = 'Notifications for task reminders';

  static NotificationDetails get _notificationDetails {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Schedule a one-time notification
  static Future<void> scheduleOneTime({
    required int taskId,
    required String title,
    required DateTime scheduledDate,
  }) async {
    await _plugin.zonedSchedule(
      taskId,
      'Task Reminder',
      title,
      tz.TZDateTime.from(scheduledDate, tz.local),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  /// Schedule recurring notifications based on recurrence rule
  static Future<void> scheduleRecurring({
    required int taskId,
    required String title,
    required RecurrenceRule rule,
    required DateTime baseTime,
  }) async {
    switch (rule.type) {
      case RecurrenceType.daily:
        await _plugin.zonedSchedule(
          taskId,
          'Task Reminder',
          title,
          tz.TZDateTime.from(baseTime, tz.local),
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        break;

      case RecurrenceType.weekly:
        if (rule.daysOfWeek.isEmpty) break;
        for (var i = 0; i < rule.daysOfWeek.length; i++) {
          final day = rule.daysOfWeek[i];
          final nextDate = _nextWeekday(baseTime, day);
          await _plugin.zonedSchedule(
            taskId * 10 + i,
            'Task Reminder',
            title,
            tz.TZDateTime.from(nextDate, tz.local),
            _notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
        break;

      case RecurrenceType.monthly:
        await _plugin.zonedSchedule(
          taskId,
          'Task Reminder',
          title,
          tz.TZDateTime.from(baseTime, tz.local),
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        );
        break;

      case RecurrenceType.yearly:
        await _plugin.zonedSchedule(
          taskId,
          'Task Reminder',
          title,
          tz.TZDateTime.from(baseTime, tz.local),
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
        );
        break;

      case RecurrenceType.none:
        break;
    }
  }

  /// Cancel all notifications for a task
  static Future<void> cancelForTask(int taskId) async {
    // Cancel the main notification
    await _plugin.cancel(taskId);
    // Cancel weekly multi-day notifications (taskId * 10 + 0..6)
    for (var i = 0; i < 7; i++) {
      await _plugin.cancel(taskId * 10 + i);
    }
  }

  /// Reschedule all active reminders (called on app restart)
  static Future<void> rescheduleAll(List<Task> tasks) async {
    await _plugin.cancelAll();

    for (final task in tasks) {
      if (!task.hasReminder || task.isDeleted) continue;
      if (task.isCompleted && (task.recurrenceRule == null || task.recurrenceRule!.type == RecurrenceType.none)) continue;

      final rule = task.recurrenceRule;
      if (rule != null && rule.type != RecurrenceType.none) {
        await scheduleRecurring(
          taskId: task.id,
          title: task.title,
          rule: rule,
          baseTime: task.reminderTime,
        );
      } else {
        if (task.reminderTime.isAfter(DateTime.now())) {
          await scheduleOneTime(
            taskId: task.id,
            title: task.title,
            scheduledDate: task.reminderTime,
          );
        }
      }
    }
  }

  /// Find the next occurrence of a specific weekday
  static DateTime _nextWeekday(DateTime from, int targetWeekday) {
    var daysUntil = targetWeekday - from.weekday;
    if (daysUntil <= 0) daysUntil += 7;
    return DateTime(from.year, from.month, from.day + daysUntil, from.hour, from.minute);
  }
}
