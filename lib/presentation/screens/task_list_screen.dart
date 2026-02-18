import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/task.dart';
import '../../data/models/enums.dart';
import '../../domain/services/task_service.dart';
import 'task_editor_screen.dart';

/// Screen displaying tasks in list or calendar view
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _isCalendarView = false;
  DateTime _selectedDate = DateTime.now();
  DateTime _calendarMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskService>(context, listen: false).loadTasks();
    });
  }

  Future<void> _navigateToEditor({int? taskId}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => TaskEditorScreen(taskId: taskId)),
    );
    if (result == true && mounted) {
      Provider.of<TaskService>(context, listen: false).loadTasks();
    }
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return Colors.red;
      case TaskPriority.medium: return Colors.orange;
      case TaskPriority.low: return Colors.green;
    }
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return 'High';
      case TaskPriority.medium: return 'Medium';
      case TaskPriority.low: return 'Low';
    }
  }

  Future<void> _handleToggleComplete(Task task, TaskService taskService) async {
    final result = await taskService.toggleComplete(task.id);

    if (result == null || !mounted) return;

    if (result.generated) {
      // Auto-generated, just show toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recurring task completed. Next "${result.taskTitle}" created.'),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // Needs confirmation — show dialog
      bool alwaysGenerate = false;
      final shouldGenerate = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Recurring Task Completed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('"${result.taskTitle}" is a recurring task. Generate the next occurrence?'),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: alwaysGenerate,
                  onChanged: (v) => setDialogState(() => alwaysGenerate = v ?? false),
                  title: const Text('Always generate for this task'),
                  subtitle: const Text("Don't ask again"),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Generate Next'),
              ),
            ],
          ),
        ),
      );

      if (shouldGenerate == true && mounted) {
        await taskService.confirmGenerateNext(
          result.taskId,
          alwaysGenerate: alwaysGenerate,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Next "${result.taskTitle}" created.'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recurring task completed.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showTaskOptions(Task task, TaskService taskService) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(task.keepForever ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(task.keepForever ? 'Remove keep forever' : 'Keep forever'),
              subtitle: const Text('Prevents auto-archive after 30 days'),
              onTap: () async {
                task.keepForever = !task.keepForever;
                await taskService.updateTask(task);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await taskService.deleteTask(task.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'archive') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Archive completed tasks?'),
                    content: const Text('Completed tasks will be archived and permanently deleted after 30 days (unless pinned).'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Archive')),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  final taskService = Provider.of<TaskService>(context, listen: false);
                  await taskService.archiveCompleted();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Completed tasks archived')),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'archive', child: Text('Archive completed tasks')),
            ],
          ),
          IconButton(
            icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_month),
            onPressed: () => setState(() => _isCalendarView = !_isCalendarView),
            tooltip: _isCalendarView ? 'List view' : 'Calendar view',
          ),
        ],
      ),
      body: Consumer<TaskService>(
        builder: (context, taskService, _) {
          return Column(
            children: [
              // Filter chips
              _buildFilterChips(taskService),
              // Content
              Expanded(
                child: _isCalendarView
                    ? _buildCalendarView(taskService)
                    : _buildListView(taskService),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips(TaskService taskService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: taskService.filter == TaskFilter.all,
            onSelected: (_) => taskService.setFilter(TaskFilter.all),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Pending'),
            selected: taskService.filter == TaskFilter.pending,
            onSelected: (_) => taskService.setFilter(TaskFilter.pending),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Completed'),
            selected: taskService.filter == TaskFilter.completed,
            onSelected: (_) => taskService.setFilter(TaskFilter.completed),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(TaskService taskService) {
    final tasks = taskService.tasks;

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('No tasks yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _navigateToEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Create your first task'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) => _buildTaskTile(tasks[index], taskService),
    );
  }

  Widget _buildTaskTile(Task task, TaskService taskService) {
    final isOverdue = !task.isCompleted && task.dueDate != null && task.dueDate!.isBefore(DateTime.now());

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await taskService.deleteTask(task.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${task.title}" deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => taskService.restoreTask(task.id),
              ),
            ),
          );
        }
        return false; // We already handled deletion
      },
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => _handleToggleComplete(task, taskService),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Theme.of(context).colorScheme.outline : null,
          ),
        ),
        subtitle: Row(
          children: [
            if (task.dueDate != null) ...[
              Icon(Icons.calendar_today, size: 12, color: isOverdue ? Colors.red : null),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  DateFormat('MMM d, yyyy – h:mm a').format(task.dueDate!),
                  style: TextStyle(fontSize: 12, color: isOverdue ? Colors.red : null),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _priorityColor(task.priority).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(_priorityLabel(task.priority), style: TextStyle(fontSize: 10, color: _priorityColor(task.priority))),
            ),
            if (task.hasReminder) ...[
              const SizedBox(width: 4),
              Icon(Icons.notifications_active, size: 14, color: Theme.of(context).colorScheme.primary),
            ],
            if (task.keepForever) ...[
              const SizedBox(width: 4),
              Icon(Icons.push_pin, size: 14, color: Theme.of(context).colorScheme.tertiary),
            ],
          ],
        ),
        onTap: () => _navigateToEditor(taskId: task.id),
        onLongPress: () => _showTaskOptions(task, taskService),
      ),
    );
  }

  Widget _buildCalendarView(TaskService taskService) {
    final datesWithTasks = taskService.getDatesWithTasks();
    final tasksForSelected = taskService.getTasksForDate(_selectedDate);

    return Column(
      children: [
        // Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() {
                _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1);
              }),
            ),
            Text(
              DateFormat('MMMM yyyy').format(_calendarMonth),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() {
                _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1);
              }),
            ),
          ],
        ),

        // Day headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),

        // Calendar grid
        _buildCalendarGrid(datesWithTasks),

        const Divider(),

        // Tasks for selected date
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              DateFormat('EEEE, MMMM d').format(_selectedDate),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),

        Expanded(
          child: tasksForSelected.isEmpty
              ? Center(child: Text('No tasks on this day', style: TextStyle(color: Theme.of(context).colorScheme.outline)))
              : ListView.builder(
                  itemCount: tasksForSelected.length,
                  itemBuilder: (context, index) => _buildTaskTile(tasksForSelected[index], taskService),
                ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(Set<DateTime> datesWithTasks) {
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1=Mon

    final cells = <Widget>[];

    // Empty cells before first day
    for (var i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    // Day cells
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_calendarMonth.year, _calendarMonth.month, day);
      final hasTask = datesWithTasks.contains(date);
      final isSelected = _selectedDate.year == date.year &&
          _selectedDate.month == date.month &&
          _selectedDate.day == date.day;
      final isToday = DateTime.now().year == date.year &&
          DateTime.now().month == date.month &&
          DateTime.now().day == date.day;

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
              border: isToday ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                    fontWeight: isToday ? FontWeight.bold : null,
                  ),
                ),
                if (hasTask)
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.2,
        children: cells,
      ),
    );
  }
}
