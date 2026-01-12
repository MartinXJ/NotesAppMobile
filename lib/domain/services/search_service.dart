import 'package:isar/isar.dart';
import '../../data/database/isar_service.dart';
import '../../data/models/sermon_note.dart';
import '../../data/models/journal_note.dart';

/// Result wrapper for search results
class SearchResult {
  final int id;
  final String title;
  final String content;
  final DateTime modifiedAt;
  final bool isSermon;
  final int relevanceScore;

  SearchResult({
    required this.id,
    required this.title,
    required this.content,
    required this.modifiedAt,
    required this.isSermon,
    required this.relevanceScore,
  });
}

/// Service for searching notes
class SearchService {
  /// Search notes by query string
  /// Searches across title, content, and tags (case-insensitive)
  /// Returns results sorted by relevance (title matches first)
  Future<List<SearchResult>> search(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final isar = await IsarService.getInstance();
    final lowerQuery = query.toLowerCase();
    final results = <SearchResult>[];

    // Search sermon notes
    final sermonNotes = await isar.sermonNotes
        .filter()
        .isDeletedEqualTo(false)
        .findAll();

    for (final note in sermonNotes) {
      final score = _calculateRelevance(
        note.title,
        note.plainTextContent,
        note.tags,
        lowerQuery,
      );

      if (score > 0) {
        results.add(SearchResult(
          id: note.id,
          title: note.title,
          content: note.plainTextContent,
          modifiedAt: note.modifiedAt,
          isSermon: true,
          relevanceScore: score,
        ));
      }
    }

    // Search journal notes
    final journalNotes = await isar.journalNotes
        .filter()
        .isDeletedEqualTo(false)
        .findAll();

    for (final note in journalNotes) {
      final score = _calculateRelevance(
        note.title,
        note.plainTextContent,
        note.tags,
        lowerQuery,
      );

      if (score > 0) {
        results.add(SearchResult(
          id: note.id,
          title: note.title,
          content: note.plainTextContent,
          modifiedAt: note.modifiedAt,
          isSermon: false,
          relevanceScore: score,
        ));
      }
    }

    // Sort by relevance score (highest first), then by modified date
    results.sort((a, b) {
      final scoreCompare = b.relevanceScore.compareTo(a.relevanceScore);
      if (scoreCompare != 0) return scoreCompare;
      return b.modifiedAt.compareTo(a.modifiedAt);
    });

    return results;
  }

  /// Calculate relevance score for a note
  /// Title matches: 10 points
  /// Tag matches: 5 points per tag
  /// Content matches: 1 point
  int _calculateRelevance(
    String title,
    String content,
    List<String> tags,
    String query,
  ) {
    int score = 0;

    // Check title match (highest priority)
    if (title.toLowerCase().contains(query)) {
      score += 10;
    }

    // Check tag matches
    for (final tag in tags) {
      if (tag.toLowerCase().contains(query)) {
        score += 5;
      }
    }

    // Check content match
    if (content.toLowerCase().contains(query)) {
      score += 1;
    }

    return score;
  }
}
