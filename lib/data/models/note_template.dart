import 'package:isar/isar.dart';

part 'note_template.g.dart';

/// Reusable note template/preset
@collection
class NoteTemplate {
  /// Auto-increment ID
  Id id = Isar.autoIncrement;

  /// Template name (e.g. "Sermon", "Journal", "Quick Note")
  late String name;

  /// Default tags applied when creating a note from this template
  List<String> defaultTags = [];

  /// Whether notes from this template show a date picker
  late bool hasDate;

  /// Whether notes from this template show a title field
  late bool hasTitle;

  /// Optional default color hex
  String? defaultColorHex;
}
