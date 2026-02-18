import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/utils/platform_utils.dart';
import '../../data/models/enums.dart';
import 'package:intl/intl.dart';

/// Note card widget for displaying note in list
class NoteCard extends StatefulWidget {
  final int id;
  final String title;
  final String preview;
  final DateTime modifiedAt;
  final DateTime? sermonDate;
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
    this.sermonDate,
    required this.colorHex,
    required this.tags,
    required this.noteType,
    required this.onTap,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(widget.colorHex);
    final dateStr = DateFormat('MMM d, yyyy').format(widget.modifiedAt);
    final sermonDateStr = widget.sermonDate != null ? DateFormat('MMM d, yyyy').format(widget.sermonDate!) : null;

    if (PlatformUtils.isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: widget.onTap,
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
                    widget.noteType == NoteType.sermon
                        ? CupertinoIcons.book
                        : CupertinoIcons.doc_text,
                    size: 16,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title.isEmpty ? 'Untitled' : widget.title,
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
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  widget.preview,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  maxLines: _expanded ? 10 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    sermonDateStr != null ? 'Sermon: $sermonDateStr' : dateStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.tertiaryLabel,
                    ),
                  ),
                  if (sermonDateStr != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Modified: $dateStr',
                      style: const TextStyle(fontSize: 10, color: CupertinoColors.tertiaryLabel),
                    ),
                  ],
                  if (widget.tags.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: widget.tags.take(3).map((tag) => _buildTag(tag, true)).toList(),
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
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.noteType == NoteType.sermon ? Icons.book : Icons.note,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title.isEmpty ? 'Untitled' : widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  widget.preview,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: _expanded ? 10 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    sermonDateStr != null ? 'Sermon: $sermonDateStr' : dateStr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (sermonDateStr != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Modified: $dateStr',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                  if (widget.tags.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: widget.tags.take(3).map((tag) => _buildTag(tag, false)).toList(),
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
