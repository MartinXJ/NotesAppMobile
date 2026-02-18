import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/utils/task_validators.dart';
import '../../data/models/task.dart';
import '../../data/models/enums.dart';
import '../../data/models/recurrence_rule.dart';
import '../../data/services/notification_service.dart';
import '../../domain/services/task_service.dart';

/// Reminder offset options (in minutes; negative = before due time)
class _ReminderOption {
  final String label;
  final int offsetMinutes; // negative = before due time, 0 = at due time

  const _ReminderOption(this.label, this.offsetMinutes);
}

const _reminderOptions = [
  _ReminderOption('At due time', 0),
  _ReminderOption('1 hour before', -60),
  _ReminderOption('2 hours before', -120),
  _ReminderOption('6 hours before', -360),
  _ReminderOption('12 hours before', -720),
  _ReminderOption('1 day before', -1440),
  _ReminderOption('3 days before', -4320),
  _ReminderOption('1 week before', -10080),
  _ReminderOption('2 weeks before', -20160),
];

/// Screen for creating and editing tasks with reminders
class TaskEditorScreen extends StatefulWidget {
  final int? taskId;

  const TaskEditorScreen({super.key, this.taskId});

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _dueDate = DateTime.now();
  TimeOfDay _dueTime = TimeOfDay.now();
  TaskPriority _priority = TaskPriority.medium;

  // One-time vs Repeat
  bool _isRepeat = false;
  RecurrenceType _recurrenceType = RecurrenceType.daily;
  List<int> _selectedWeekdays = [];

  // Date toggle
  bool _hasDate = false;

  // Reminder
  bool _hasReminder = false;
  int _reminderOffsetMinutes = 0; // 0 = at due time

  bool _isLoading = true;
  bool _isSaving = false;
  Task? _existingTask;

  final _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTask() async {
    if (widget.taskId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final taskService = Provider.of<TaskService>(context, listen: false);
    final tasks = taskService.tasks;
    _existingTask = tasks.where((t) => t.id == widget.taskId).firstOrNull;

    if (_existingTask != null) {
      _titleController.text = _existingTask!.title;
      _descriptionController.text = _existingTask!.description ?? '';
      _priority = _existingTask!.priority;
      _hasReminder = _existingTask!.hasReminder;

      if (_existingTask!.dueDate != null) {
        _hasDate = true;
        _dueDate = _existingTask!.dueDate!;
        _dueTime = TimeOfDay.fromDateTime(_existingTask!.dueDate!);
      }

      if (_existingTask!.recurrenceRule != null) {
        _isRepeat = true;
        _recurrenceType = _existingTask!.recurrenceRule!.type;
        _selectedWeekdays = List.from(_existingTask!.recurrenceRule!.daysOfWeek);
      }

      // Restore reminder offset from stored reminderTime vs dueDate
      if (_hasReminder) {
        final diff = _existingTask!.reminderTime
            ?.difference(_existingTask!.dueDate ?? _existingTask!.reminderTime!)
            .inMinutes ?? 0;
        final match = _reminderOptions
            .where((o) => o.offsetMinutes == diff)
            .firstOrNull;
        _reminderOffsetMinutes = match?.offsetMinutes ?? diff;
      }
    }

    setState(() => _isLoading = false);
  }

  DateTime get _dueDateTime => DateTime(
        _dueDate.year, _dueDate.month, _dueDate.day,
        _dueTime.hour, _dueTime.minute,
      );

  DateTime get _computedReminderTime =>
      _dueDateTime.add(Duration(minutes: _reminderOffsetMinutes));

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final taskService = Provider.of<TaskService>(context, listen: false);
    final dueDateTime = _hasDate ? _dueDateTime : null;
    final reminderTime = (_hasDate && _hasReminder) ? _computedReminderTime : null;

    // Validate reminder time is in the future
    if (_hasDate && _hasReminder && reminderTime != null && reminderTime.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder time must be in the future')),
        );
        setState(() => _isSaving = false);
      }
      return;
    }

    RecurrenceRule? rule;
    if (_isRepeat) {
      rule = RecurrenceRule()
        ..type = _recurrenceType
        ..daysOfWeek = _selectedWeekdays
        ..dayOfMonth = _dueDate.day
        ..month = _dueDate.month
        ..dayOfMonthForYearly = _dueDate.day;
    }

    try {
      if (_existingTask != null) {
        _existingTask!.title = _titleController.text.trim();
        _existingTask!.description = _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim();
        _existingTask!.dueDate = dueDateTime;
        _existingTask!.reminderTime = reminderTime;
        _existingTask!.priority = _priority;
        _existingTask!.hasReminder = _hasDate && _hasReminder;
        _existingTask!.recurrenceRule = rule;
        await taskService.updateTask(_existingTask!);

        try {
          await NotificationService.cancelForTask(_existingTask!.id);
          if (_hasDate && _hasReminder && reminderTime != null) {
            if (rule != null) {
              await NotificationService.scheduleRecurring(
                taskId: _existingTask!.id,
                title: _existingTask!.title,
                rule: rule,
                baseTime: reminderTime,
              );
            } else {
              await NotificationService.scheduleOneTime(
                taskId: _existingTask!.id,
                title: _existingTask!.title,
                scheduledDate: reminderTime,
              );
            }
          }
        } catch (_) {}
      } else {
        final task = Task()
          ..title = _titleController.text.trim()
          ..description = _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim()
          ..dueDate = dueDateTime
          ..reminderTime = reminderTime
          ..priority = _priority
          ..isCompleted = false
          ..createdAt = DateTime.now()
          ..modifiedAt = DateTime.now()
          ..isDeleted = false
          ..hasReminder = _hasDate && _hasReminder
          ..recurrenceRule = rule;

        final id = await taskService.createTask(task);

        try {
          if (_hasDate && _hasReminder && reminderTime != null) {
            if (rule != null) {
              await NotificationService.scheduleRecurring(
                taskId: id,
                title: task.title,
                rule: rule,
                baseTime: reminderTime,
              );
            } else {
              await NotificationService.scheduleOneTime(
                taskId: id,
                title: task.title,
                scheduledDate: reminderTime,
              );
            }
          }
        } catch (_) {}
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving task: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    if (PlatformUtils.isIOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: 260,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context)),
                  CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _dueDate,
                  onDateTimeChanged: (date) => setState(() => _dueDate = date),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _dueDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked != null) setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickTime() async {
    if (PlatformUtils.isIOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: 260,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context)),
                  CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime:
                      DateTime(2026, 1, 1, _dueTime.hour, _dueTime.minute),
                  onDateTimeChanged: (dt) =>
                      setState(() => _dueTime = TimeOfDay.fromDateTime(dt)),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final picked =
          await showTimePicker(context: context, initialTime: _dueTime);
      if (picked != null) setState(() => _dueTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.taskId == null ? 'Create a new Task' : 'Editing a Task'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveTask,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // One-time vs Repeat (at the top)
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false,
                    label: Text('One-time'),
                    icon: Icon(Icons.looks_one_outlined)),
                ButtonSegment(
                    value: true,
                    label: Text('Repeat'),
                    icon: Icon(Icons.repeat)),
              ],
              selected: {_isRepeat},
              onSelectionChanged: (s) => setState(() {
                _isRepeat = s.first;
                // Repeat requires a date — auto-enable it
                if (_isRepeat) _hasDate = true;
              }),
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What needs to be done?',
                border: OutlineInputBorder(),
              ),
              validator: validateTaskTitle,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Task Date toggle
            SwitchListTile(
              title: const Text('Task Date'),
              subtitle: const Text('Set a date for this task'),
              value: _hasDate,
              onChanged: (v) async {
                if (!v && _isRepeat) {
                  // Block: repeat tasks require a date
                  final switchToOneTime = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Date required for Repeat tasks'),
                      content: const Text(
                          'Repeat tasks must have a date. Switch to One-time to remove the date?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Switch to One-time')),
                      ],
                    ),
                  );
                  if (switchToOneTime == true) {
                    setState(() {
                      _isRepeat = false;
                      _hasDate = false;
                      _hasReminder = false;
                    });
                  }
                } else {
                  setState(() {
                    _hasDate = v;
                    if (!v) _hasReminder = false;
                  });
                }
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Date + time pickers (only if date enabled)
            if (_hasDate) ...[
              // Repeat every (only if Repeat mode)
              if (_isRepeat) ...[
                const SizedBox(height: 8),
                Text('Repeat every',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                        label: const Text('Daily'),
                        selected: _recurrenceType == RecurrenceType.daily,
                        onSelected: (_) => setState(
                            () => _recurrenceType = RecurrenceType.daily)),
                    ChoiceChip(
                        label: const Text('Weekly'),
                        selected: _recurrenceType == RecurrenceType.weekly,
                        onSelected: (_) => setState(
                            () => _recurrenceType = RecurrenceType.weekly)),
                    ChoiceChip(
                        label: const Text('Monthly'),
                        selected: _recurrenceType == RecurrenceType.monthly,
                        onSelected: (_) => setState(
                            () => _recurrenceType = RecurrenceType.monthly)),
                    ChoiceChip(
                        label: const Text('Yearly'),
                        selected: _recurrenceType == RecurrenceType.yearly,
                        onSelected: (_) => setState(
                            () => _recurrenceType = RecurrenceType.yearly)),
                  ],
                ),
                if (_recurrenceType == RecurrenceType.weekly) ...[
                  const SizedBox(height: 12),
                  Text('On these days:',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: List.generate(7, (i) {
                      final dayNum = i + 1;
                      final isSelected = _selectedWeekdays.contains(dayNum);
                      return FilterChip(
                        label: Text(_weekdayNames[i]),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selected
                                ? _selectedWeekdays.add(dayNum)
                                : _selectedWeekdays.remove(dayNum);
                          });
                        },
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Task Date'),
                      subtitle: Text(
                          DateFormat('EEE, MMM d, yyyy').format(_dueDate)),
                      onTap: _pickDate,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Time'),
                      subtitle: Text(_dueTime.format(context)),
                      onTap: _pickTime,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Priority
            Text('Priority', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<TaskPriority>(
              segments: const [
                ButtonSegment(
                    value: TaskPriority.low,
                    label: Text('Low'),
                    icon: Icon(Icons.arrow_downward)),
                ButtonSegment(
                    value: TaskPriority.medium,
                    label: Text('Medium'),
                    icon: Icon(Icons.remove)),
                ButtonSegment(
                    value: TaskPriority.high,
                    label: Text('High'),
                    icon: Icon(Icons.arrow_upward)),
              ],
              selected: {_priority},
              onSelectionChanged: (s) =>
                  setState(() => _priority = s.first),
            ),
            const SizedBox(height: 20),

            // Reminder (only if date is set)
            if (_hasDate) ...[
              const SizedBox(height: 20),

              SwitchListTile(
                title: const Text('Reminder'),
                subtitle: const Text('Get notified before the due time'),
                value: _hasReminder,
                onChanged: (v) => setState(() => _hasReminder = v),
                contentPadding: EdgeInsets.zero,
              ),

              if (_hasReminder) ...[
                const SizedBox(height: 8),
                Text('Notify me',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _reminderOptions.map((opt) {
                    return ChoiceChip(
                      label: Text(opt.label),
                      selected: _reminderOffsetMinutes == opt.offsetMinutes,
                      onSelected: (_) => setState(
                          () => _reminderOffsetMinutes = opt.offsetMinutes),
                    );
                  }).toList(),
                ),
              ],
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
