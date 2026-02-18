import 'package:isar/isar.dart';
import '../../data/database/isar_service.dart';
import '../../data/models/note.dart';
import '../../core/utils/note_utils.dart';

/// Result wrapper for search results
class SearchResult {
  final int id;
  final String displayTitle;
  final String contentPreview;
  final DateTime modifiedAt;
  final int relevanceScore;

  SearchResult({
    required this.id,
    required this.displayTitle,
    required this.contentPreview,
    required this.modifiedAt,
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

    final notes = await isar.notes
        .filter()
        .isDeletedEqualTo(false)
        .findAll();

    for (final note in notes) {
      final title = getDisplayTitle(note);
      final score = _calculateRelevance(
        title,
        note.plainTextContent,
        note.tags,
        lowerQuery,
      );

      if (score > 0) {
        final preview = note.plainTextContent.length > 100
            ? '${note.plainTextContent.substring(0, 100)}...'
            : note.plainTextContent;

        results.add(SearchResult(
          id: note.id,
          displayTitle: title,
          contentPreview: preview.isEmpty ? 'No content' : preview,
          modifiedAt: note.modifiedAt,
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

    if (title.toLowerCase().contains(query)) {
      score += 10;
    }

    for (final tag in tags) {
      if (tag.toLowerCase().contains(query)) {
        score += 5;
      }
    }

    if (content.toLowerCase().contains(query)) {
      score += 1;
    }

    return score;
  }
}
