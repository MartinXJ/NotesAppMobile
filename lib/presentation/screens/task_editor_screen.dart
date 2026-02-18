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
  bool _hasReminder = false;
  RecurrenceType _recurrenceType = RecurrenceType.none;
  List<int> _selectedWeekdays = [];
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
    // Find task from loaded tasks
    final tasks = taskService.tasks;
    _existingTask = tasks.where((t) => t.id == widget.taskId).firstOrNull;

    if (_existingTask != null) {
      _titleController.text = _existingTask!.title;
      _descriptionController.text = _existingTask!.description ?? '';
      _dueDate = _existingTask!.dueDate;
      _dueTime = TimeOfDay.fromDateTime(_existingTask!.dueDate);
      _priority = _existingTask!.priority;
      _hasReminder = _existingTask!.hasReminder;
      if (_existingTask!.recurrenceRule != null) {
        _recurrenceType = _existingTask!.recurrenceRule!.type;
        _selectedWeekdays = List.from(_existingTask!.recurrenceRule!.daysOfWeek);
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final taskService = Provider.of<TaskService>(context, listen: false);
    final dueDateTime = DateTime(
      _dueDate.year, _dueDate.month, _dueDate.day,
      _dueTime.hour, _dueTime.minute,
    );

    // Validate reminder time
    if (_hasReminder && dueDateTime.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder time must be in the future')),
        );
        setState(() => _isSaving = false);
      }
      return;
    }

    RecurrenceRule? rule;
    if (_recurrenceType != RecurrenceType.none) {
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
            ? null : _descriptionController.text.trim();
        _existingTask!.dueDate = dueDateTime;
        _existingTask!.reminderTime = dueDateTime;
        _existingTask!.priority = _priority;
        _existingTask!.hasReminder = _hasReminder;
        _existingTask!.recurrenceRule = rule;
        await taskService.updateTask(_existingTask!);

        // Update notifications (non-blocking)
        try {
          await NotificationService.cancelForTask(_existingTask!.id);
          if (_hasReminder) {
            if (rule != null && rule.type != RecurrenceType.none) {
              await NotificationService.scheduleRecurring(
                taskId: _existingTask!.id, title: _existingTask!.title,
                rule: rule, baseTime: dueDateTime,
              );
            } else {
              await NotificationService.scheduleOneTime(
                taskId: _existingTask!.id, title: _existingTask!.title,
                scheduledDate: dueDateTime,
              );
            }
          }
        } catch (_) {}
      } else {
        final task = Task()
          ..title = _titleController.text.trim()
          ..description = _descriptionController.text.trim().isEmpty
              ? null : _descriptionController.text.trim()
          ..dueDate = dueDateTime
          ..reminderTime = dueDateTime
          ..priority = _priority
          ..isCompleted = false
          ..createdAt = DateTime.now()
          ..modifiedAt = DateTime.now()
          ..isDeleted = false
          ..hasReminder = _hasReminder
          ..recurrenceRule = rule;

        final id = await taskService.createTask(task);

        // Schedule notifications (non-blocking)
        try {
          if (_hasReminder) {
            if (rule != null && rule.type != RecurrenceType.none) {
              await NotificationService.scheduleRecurring(
                taskId: id, title: task.title, rule: rule, baseTime: dueDateTime,
              );
            } else {
              await NotificationService.scheduleOneTime(
                taskId: id, title: task.title, scheduledDate: dueDateTime,
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
                  CupertinoButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
                  CupertinoButton(child: const Text('Done'), onPressed: () => Navigator.pop(context)),
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
        context: context, initialDate: _dueDate,
        firstDate: DateTime(2020), lastDate: DateTime(2100),
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
                  CupertinoButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
                  CupertinoButton(child: const Text('Done'), onPressed: () => Navigator.pop(context)),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(2026, 1, 1, _dueTime.hour, _dueTime.minute),
                  onDateTimeChanged: (dt) => setState(() => _dueTime = TimeOfDay.fromDateTime(dt)),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final picked = await showTimePicker(context: context, initialTime: _dueTime);
      if (picked != null) setState(() => _dueTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.taskId == null ? 'New Task' : 'Edit Task'),
        actions: [
          IconButton(
            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveTask,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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

            // Due date and time
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Due Date'),
                    subtitle: Text(DateFormat('EEE, MMM d, yyyy').format(_dueDate)),
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
            const SizedBox(height: 16),

            // Priority
            Text('Priority', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<TaskPriority>(
              segments: const [
                ButtonSegment(value: TaskPriority.low, label: Text('Low'), icon: Icon(Icons.arrow_downward)),
                ButtonSegment(value: TaskPriority.medium, label: Text('Medium'), icon: Icon(Icons.remove)),
                ButtonSegment(value: TaskPriority.high, label: Text('High'), icon: Icon(Icons.arrow_upward)),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 16),

            // Reminder toggle
            SwitchListTile(
              title: const Text('Reminder'),
              subtitle: const Text('Get notified at the due time'),
              value: _hasReminder,
              onChanged: (v) => setState(() => _hasReminder = v),
              contentPadding: EdgeInsets.zero,
            ),

            // Recurrence (only if reminder is on)
            if (_hasReminder) ...[
              const SizedBox(height: 8),
              Text('Repeat', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(label: const Text('None'), selected: _recurrenceType == RecurrenceType.none, onSelected: (_) => setState(() => _recurrenceType = RecurrenceType.none)),
                  ChoiceChip(label: const Text('Daily'), selected: _recurrenceType == RecurrenceType.daily, onSelected: (_) => setState(() => _recurrenceType = RecurrenceType.daily)),
                  ChoiceChip(label: const Text('Weekly'), selected: _recurrenceType == RecurrenceType.weekly, onSelected: (_) => setState(() => _recurrenceType = RecurrenceType.weekly)),
                  ChoiceChip(label: const Text('Monthly'), selected: _recurrenceType == RecurrenceType.monthly, onSelected: (_) => setState(() => _recurrenceType = RecurrenceType.monthly)),
                  ChoiceChip(label: const Text('Yearly'), selected: _recurrenceType == RecurrenceType.yearly, onSelected: (_) => setState(() => _recurrenceType = RecurrenceType.yearly)),
                ],
              ),

              // Weekly day selector
              if (_recurrenceType == RecurrenceType.weekly) ...[
                const SizedBox(height: 12),
                Text('On these days:', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: List.generate(7, (i) {
                    final dayNum = i + 1; // 1=Mon..7=Sun
                    final isSelected = _selectedWeekdays.contains(dayNum);
                    return FilterChip(
                      label: Text(_weekdayNames[i]),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selected ? _selectedWeekdays.add(dayNum) : _selectedWeekdays.remove(dayNum);
                        });
                      },
                    );
                  }),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
