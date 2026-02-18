import 'package:isar/isar.dart';
import '../../data/database/isar_service.dart';
import '../../data/models/note.dart';

/// Filter criteria for notes
class NoteFilter {
  final List<String>? tags;
  final String? color;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateFilterType? dateFilterType;

  NoteFilter({
    this.tags,
    this.color,
    this.startDate,
    this.endDate,
    this.dateFilterType,
  });
}

/// Type of date filter
enum DateFilterType {
  created,
  modified,
  noteDate, // The optional date field on Note
}

/// Service for filtering notes
class FilterService {
  /// Apply filters to notes
  Future<List<Note>> applyFilters(NoteFilter filter) async {
    final isar = await IsarService.getInstance();

    var query = isar.notes.filter().isDeletedEqualTo(false);

    // Apply color filter
    if (filter.color != null) {
      query = query.colorHexEqualTo(filter.color!);
    }

    // Apply date filter
    if (filter.startDate != null || filter.endDate != null) {
      final dateType = filter.dateFilterType ?? DateFilterType.modified;

      if (dateType == DateFilterType.created) {
        if (filter.startDate != null && filter.endDate != null) {
          query = query.createdAtBetween(filter.startDate!, filter.endDate!);
        } else if (filter.startDate != null) {
          query = query.createdAtGreaterThan(filter.startDate!);
        } else if (filter.endDate != null) {
          query = query.createdAtLessThan(filter.endDate!);
        }
      } else if (dateType == DateFilterType.noteDate) {
        if (filter.startDate != null && filter.endDate != null) {
          query = query.dateBetween(filter.startDate!, filter.endDate!);
        } else if (filter.startDate != null) {
          query = query.dateGreaterThan(filter.startDate!);
        } else if (filter.endDate != null) {
          query = query.dateLessThan(filter.endDate!);
        }
      } else {
        // modified (default)
        if (filter.startDate != null && filter.endDate != null) {
          query = query.modifiedAtBetween(filter.startDate!, filter.endDate!);
        } else if (filter.startDate != null) {
          query = query.modifiedAtGreaterThan(filter.startDate!);
        } else if (filter.endDate != null) {
          query = query.modifiedAtLessThan(filter.endDate!);
        }
      }
    }

    final notes = await query.sortByModifiedAtDesc().findAll();

    // Apply tag filter in-memory (Isar doesn't support "contains all" for lists)
    if (filter.tags != null && filter.tags!.isNotEmpty) {
      return notes.where((note) {
        return filter.tags!.every((filterTag) =>
            note.tags.any((noteTag) =>
                noteTag.toLowerCase() == filterTag.toLowerCase()));
      }).toList();
    }

    return notes;
  }
}
