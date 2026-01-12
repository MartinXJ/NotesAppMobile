import 'package:isar/isar.dart';
import '../../data/database/isar_service.dart';
import '../../data/models/sermon_note.dart';
import '../../data/models/journal_note.dart';
import '../../data/models/enums.dart';

/// Filter criteria for notes
class NoteFilter {
  final NoteType? type;
  final List<String>? tags;
  final String? color;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateFilterType? dateFilterType;

  NoteFilter({
    this.type,
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
  sermon, // For sermon notes only
}

/// Result wrapper for filter results
class FilterResult {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime? sermonDate;
  final String colorHex;
  final List<String> tags;
  final bool isSermon;

  FilterResult({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.modifiedAt,
    this.sermonDate,
    required this.colorHex,
    required this.tags,
    required this.isSermon,
  });
}

/// Service for filtering notes
class FilterService {
  /// Apply filters to notes
  Future<List<FilterResult>> applyFilters(NoteFilter filter) async {
    final isar = await IsarService.getInstance();
    final results = <FilterResult>[];

    // Determine which note types to query
    final querySermon = filter.type == null || filter.type == NoteType.sermon;
    final queryJournal = filter.type == null || filter.type == NoteType.journal;

    // Query sermon notes if needed
    if (querySermon) {
      final sermonNotes = await _filterSermonNotes(isar, filter);
      results.addAll(sermonNotes);
    }

    // Query journal notes if needed
    if (queryJournal) {
      final journalNotes = await _filterJournalNotes(isar, filter);
      results.addAll(journalNotes);
    }

    // Sort by modified date (most recent first)
    results.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

    return results;
  }

  /// Filter sermon notes
  Future<List<FilterResult>> _filterSermonNotes(
    Isar isar,
    NoteFilter filter,
  ) async {
    var query = isar.sermonNotes.filter().isDeletedEqualTo(false);

    // Apply color filter
    if (filter.color != null) {
      query = query.colorHexEqualTo(filter.color!);
    }

    // Apply date filter
    if (filter.startDate != null || filter.endDate != null) {
      query = _applyDateFilter(
        query,
        filter.startDate,
        filter.endDate,
        filter.dateFilterType ?? DateFilterType.modified,
        true, // isSermon
      );
    }

    final notes = await query.findAll();

    // Apply tag filter (in-memory since Isar doesn't support array contains all)
    final filteredNotes = filter.tags != null && filter.tags!.isNotEmpty
        ? notes.where((note) => _containsAllTags(note.tags, filter.tags!)).toList()
        : notes;

    return filteredNotes.map((note) => FilterResult(
      id: note.id,
      title: note.title,
      content: note.plainTextContent,
      createdAt: note.createdAt,
      modifiedAt: note.modifiedAt,
      sermonDate: note.sermonDate,
      colorHex: note.colorHex,
      tags: note.tags,
      isSermon: true,
    )).toList();
  }

  /// Filter journal notes
  Future<List<FilterResult>> _filterJournalNotes(
    Isar isar,
    NoteFilter filter,
  ) async {
    var query = isar.journalNotes.filter().isDeletedEqualTo(false);

    // Apply color filter
    if (filter.color != null) {
      query = query.colorHexEqualTo(filter.color!);
    }

    // Apply date filter
    if (filter.startDate != null || filter.endDate != null) {
      query = _applyDateFilter(
        query,
        filter.startDate,
        filter.endDate,
        filter.dateFilterType ?? DateFilterType.modified,
        false, // isSermon
      );
    }

    final notes = await query.findAll();

    // Apply tag filter (in-memory)
    final filteredNotes = filter.tags != null && filter.tags!.isNotEmpty
        ? notes.where((note) => _containsAllTags(note.tags, filter.tags!)).toList()
        : notes;

    return filteredNotes.map((note) => FilterResult(
      id: note.id,
      title: note.title,
      content: note.plainTextContent,
      createdAt: note.createdAt,
      modifiedAt: note.modifiedAt,
      sermonDate: null,
      colorHex: note.colorHex,
      tags: note.tags,
      isSermon: false,
    )).toList();
  }

  /// Apply date filter to query
  dynamic _applyDateFilter(
    dynamic query,
    DateTime? startDate,
    DateTime? endDate,
    DateFilterType dateFilterType,
    bool isSermon,
  ) {
    // For sermon notes with sermon date filter
    if (isSermon && dateFilterType == DateFilterType.sermon) {
      if (startDate != null && endDate != null) {
        return query.sermonDateBetween(startDate, endDate);
      } else if (startDate != null) {
        return query.sermonDateGreaterThan(startDate);
      } else if (endDate != null) {
        return query.sermonDateLessThan(endDate);
      }
    }

    // For created date filter
    if (dateFilterType == DateFilterType.created) {
      if (startDate != null && endDate != null) {
        return query.createdAtBetween(startDate, endDate);
      } else if (startDate != null) {
        return query.createdAtGreaterThan(startDate);
      } else if (endDate != null) {
        return query.createdAtLessThan(endDate);
      }
    }

    // For modified date filter (default)
    if (startDate != null && endDate != null) {
      return query.modifiedAtBetween(startDate, endDate);
    } else if (startDate != null) {
      return query.modifiedAtGreaterThan(startDate);
    } else if (endDate != null) {
      return query.modifiedAtLessThan(endDate);
    }

    return query;
  }

  /// Check if note tags contain all filter tags
  bool _containsAllTags(List<String> noteTags, List<String> filterTags) {
    return filterTags.every((filterTag) =>
        noteTags.any((noteTag) => noteTag.toLowerCase() == filterTag.toLowerCase()));
  }
}
