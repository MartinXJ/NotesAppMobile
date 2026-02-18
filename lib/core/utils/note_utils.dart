import '../../data/models/note.dart';

/// Derives the display title for a Note.
/// Returns explicit title if non-empty, else first line of plainTextContent
/// (truncated to 50 chars), else "Untitled".
String getDisplayTitle(Note note) {
  if (note.title != null && note.title!.trim().isNotEmpty) {
    return note.title!;
  }

  final plain = note.plainTextContent.trim();
  if (plain.isNotEmpty) {
    // Take first line
    final firstLine = plain.split('\n').first.trim();
    if (firstLine.isNotEmpty) {
      return firstLine.length > 50 ? '${firstLine.substring(0, 50)}...' : firstLine;
    }
  }

  return 'Untitled';
}
