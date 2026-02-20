import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/media_attachment.dart';

/// Horizontal scrollable media gallery shown in the note editor.
/// Supports add, remove, and rename of image attachments.
class MediaGalleryWidget extends StatelessWidget {
  final List<MediaAttachment> attachments;
  final bool isEditing;
  final VoidCallback onAddMedia;
  final void Function(int index) onRemove;
  final void Function(int index, String newName) onRename;

  const MediaGalleryWidget({
    super.key,
    required this.attachments,
    required this.isEditing,
    required this.onAddMedia,
    required this.onRemove,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty && !isEditing) return const SizedBox.shrink();

    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add button (edit mode only)
          if (isEditing)
            _AddButton(onTap: onAddMedia),

          // Attachment thumbnails
          ...attachments.asMap().entries.map((entry) {
            final index = entry.key;
            final attachment = entry.value;
            return _MediaThumbnail(
              attachment: attachment,
              isEditing: isEditing,
              onRemove: () => onRemove(index),
              onRename: (name) => onRename(index, name),
            );
          }),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 90,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).colorScheme.outline, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text('Add',
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  final MediaAttachment attachment;
  final bool isEditing;
  final VoidCallback onRemove;
  final void Function(String) onRename;

  const _MediaThumbnail({
    required this.attachment,
    required this.isEditing,
    required this.onRemove,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(attachment.localPath);
    final isEmoji = attachment.localPath.startsWith('emoji:');
    final name = attachment.displayName ?? _shortName(attachment.localPath);

    return GestureDetector(
      onLongPress: isEditing ? () => _showOptions(context) : null,
      onTap: isEmoji ? null : () => _showFullImage(context, file),
      child: Container(
        width: 80,
        height: 90,
        margin: const EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            // Image or emoji
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isEmoji
                  ? Container(
                      width: 80,
                      height: 80,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        attachment.localPath.replaceFirst('emoji:', ''),
                        style: const TextStyle(fontSize: 40),
                      ),
                    )
                  : file.existsSync()
                      ? Image.file(file,
                          width: 80, height: 80, fit: BoxFit.cover)
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 32),
                        ),
            ),

            // Remove button (edit mode)
            if (isEditing)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),

            // File name label
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onRemove();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(
        text: attachment.displayName ?? _shortName(attachment.localPath));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'File name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRename(controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, File file) {
    if (!file.existsSync()) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: InteractiveViewer(
            child: Image.file(file),
          ),
        ),
      ),
    );
  }

  String _shortName(String path) {
    final parts = path.split(Platform.pathSeparator);
    return parts.last.length > 12
        ? '${parts.last.substring(0, 12)}...'
        : parts.last;
  }
}
