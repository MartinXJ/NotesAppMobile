import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../core/utils/platform_utils.dart';
import '../../domain/services/filter_service.dart';

/// Filter panel shown as a bottom sheet
class FilterPanel extends StatefulWidget {
  final NoteFilter currentFilter;
  final List<String> availableTags;
  final ValueChanged<NoteFilter> onFilterChanged;

  const FilterPanel({
    super.key,
    required this.currentFilter,
    required this.availableTags,
    required this.onFilterChanged,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late List<String> _selectedTags;
  late String? _selectedColor;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late DateFilterType? _dateFilterType;

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Red', 'hex': '#FFEF5350', 'color': Colors.red},
    {'name': 'Pink', 'hex': '#FFEC407A', 'color': Colors.pink},
    {'name': 'Purple', 'hex': '#FFAB47BC', 'color': Colors.purple},
    {'name': 'Blue', 'hex': '#FF42A5F5', 'color': Colors.blue},
    {'name': 'Cyan', 'hex': '#FF26C6DA', 'color': Colors.cyan},
    {'name': 'Teal', 'hex': '#FF26A69A', 'color': Colors.teal},
    {'name': 'Green', 'hex': '#FF66BB6A', 'color': Colors.green},
    {'name': 'Yellow', 'hex': '#FFFFEE58', 'color': Colors.yellow},
    {'name': 'Orange', 'hex': '#FFFFA726', 'color': Colors.orange},
  ];

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.currentFilter.tags ?? []);
    _selectedColor = widget.currentFilter.color;
    _startDate = widget.currentFilter.startDate;
    _endDate = widget.currentFilter.endDate;
    _dateFilterType = widget.currentFilter.dateFilterType;
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedTags.isNotEmpty) count++;
    if (_selectedColor != null) count++;
    if (_startDate != null || _endDate != null) count++;
    return count;
  }

  void _applyFilters() {
    widget.onFilterChanged(NoteFilter(
      tags: _selectedTags.isEmpty ? null : _selectedTags,
      color: _selectedColor,
      startDate: _startDate,
      endDate: _endDate,
      dateFilterType: _dateFilterType,
    ));
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedTags = [];
      _selectedColor = null;
      _startDate = null;
      _endDate = null;
      _dateFilterType = null;
    });
  }

  void _selectDatePreset(String preset) {
    final now = DateTime.now();
    setState(() {
      switch (preset) {
        case 'today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'week':
          _startDate = now.subtract(Duration(days: now.weekday - 1));
          _endDate = now;
          break;
        case 'month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
          break;
      }
    });
  }

  Future<void> _pickCustomDateRange() async {
    if (PlatformUtils.isIOS) {
      final start = await _showCupertinoDatePicker(_startDate ?? DateTime.now());
      if (start != null) {
        final end = await _showCupertinoDatePicker(_endDate ?? DateTime.now());
        if (end != null) {
          setState(() { _startDate = start; _endDate = end; });
        }
      }
    } else {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: _startDate != null && _endDate != null
            ? DateTimeRange(start: _startDate!, end: _endDate!) : null,
      );
      if (range != null) {
        setState(() { _startDate = range.start; _endDate = range.end; });
      }
    }
  }

  Future<DateTime?> _showCupertinoDatePicker(DateTime initial) async {
    DateTime? picked;
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
                CupertinoButton(child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context)),
                CupertinoButton(child: const Text('Done'), onPressed: () {
                  picked ??= initial;
                  Navigator.pop(context);
                }),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                onDateTimeChanged: (date) => picked = date,
              ),
            ),
          ],
        ),
      ),
    );
    return picked;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters', style: Theme.of(context).textTheme.titleLarge),
              Row(
                children: [
                  if (_activeFilterCount > 0)
                    TextButton(onPressed: _clearFilters,
                        child: const Text('Clear All')),
                  FilledButton(onPressed: _applyFilters,
                      child: const Text('Apply')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Color filter
          Text('Color', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _colors.map((c) {
              final isSelected = _selectedColor == c['hex'];
              return GestureDetector(
                onTap: () => setState(() =>
                    _selectedColor = isSelected ? null : c['hex']),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: c['color'] as Color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.black, width: 3) : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Tags filter
          if (widget.availableTags.isNotEmpty) ...[
            Text('Tags', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 4,
              children: widget.availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (_) => setState(() {
                    isSelected
                        ? _selectedTags.remove(tag)
                        : _selectedTags.add(tag);
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Date range filter
          Text('Date Range', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 4,
            children: [
              ActionChip(label: const Text('Today'),
                  onPressed: () => _selectDatePreset('today')),
              ActionChip(label: const Text('This Week'),
                  onPressed: () => _selectDatePreset('week')),
              ActionChip(label: const Text('This Month'),
                  onPressed: () => _selectDatePreset('month')),
              ActionChip(label: const Text('This Year'),
                  onPressed: () => _selectDatePreset('year')),
              ActionChip(label: const Text('Custom...'),
                  onPressed: _pickCustomDateRange),
            ],
          ),
          if (_startDate != null || _endDate != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_startDate != null ? DateFormat('MMM d, yyyy').format(_startDate!) : '...'} — ${_endDate != null ? DateFormat('MMM d, yyyy').format(_endDate!) : '...'}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
