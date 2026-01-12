import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/utils/platform_utils.dart';
import '../../data/models/enums.dart';
import 'package:intl/intl.dart';

/// Note card widget for displaying note in list
class NoteCard extends StatelessWidget {
  final int id;
  final String title;
  final String preview;
  final DateTime modifiedAt;
  final String colorHex;
  final List<String> tags;
  final NoteType noteType;
  final VoidCallback onTap;

  const NoteCard({
    super.key,
    required this.id,
    required this.title,
    required this.preview,
    required this.modifiedAt,
    required this.colorHex,
    required this.tags,
    required this.noteType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(colorHex);
    final dateStr = DateFormat('MMM d, yyyy').format(modifiedAt);

    if (PlatformUtils.isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    noteType == NoteType.sermon
                        ? CupertinoIcons.book
                        : CupertinoIcons.doc_text,
                    size: 16,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title.isEmpty ? 'Untitled' : title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                preview,
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.tertiaryLabel,
                    ),
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: tags.take(3).map((tag) => _buildTag(tag, true)).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    noteType == NoteType.sermon ? Icons.book : Icons.note,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title.isEmpty ? 'Untitled' : title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                preview,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: tags.take(3).map((tag) => _buildTag(tag, false)).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String tag, bool isIOS) {
    if (isIOS) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          tag,
          style: const TextStyle(
            fontSize: 10,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
      );
    }

    return Chip(
      label: Text(tag),
      labelStyle: const TextStyle(fontSize: 10),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}
