import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/media_attachment.dart';
import '../../data/models/enums.dart';
import '../../data/services/sticker_service.dart';

/// Bottom sheet sticker picker with Emoji and My Stickers tabs
class StickerPickerWidget extends StatefulWidget {
  final void Function(MediaAttachment sticker) onStickerSelected;

  const StickerPickerWidget({super.key, required this.onStickerSelected});

  @override
  State<StickerPickerWidget> createState() => _StickerPickerWidgetState();
}

class _StickerPickerWidgetState extends State<StickerPickerWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<File> _customStickers = [];
  bool _loadingCustom = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCustomStickers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomStickers() async {
    final stickers = await StickerService.getSavedStickers();
    if (mounted) {
      setState(() {
        _customStickers = stickers;
        _loadingCustom = false;
      });
    }
  }

  Future<void> _addFromGallery() async {
    final sticker = await StickerService.createFromGallery();
    if (sticker != null && mounted) {
      widget.onStickerSelected(sticker);
      Navigator.pop(context);
    }
  }

  void _onEmojiTap(String emoji) {
    final sticker = StickerService.createEmojiSticker(emoji);
    widget.onStickerSelected(sticker);
    Navigator.pop(context);
  }

  void _onCustomStickerTap(File file) {
    final sticker = MediaAttachment()
      ..localPath = file.path
      ..type = MediaType.sticker
      ..displayName = 'Sticker'
      ..positionX = 0
      ..positionY = 0
      ..width = 120
      ..height = 120;
    widget.onStickerSelected(sticker);
    Navigator.pop(context);
  }

  void _onCustomStickerLongPress(File file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sticker?'),
        content: const Text('Remove this sticker from your collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await StickerService.deleteSticker(file.path);
              _loadCustomStickers();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Text('Stickers',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        // Tabs
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Emoji'),
            Tab(text: 'My Stickers'),
          ],
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildEmojiTab(),
              _buildCustomTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiTab() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: StickerService.emojiCategories.map((category) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(category.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  )),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1,
              ),
              itemCount: category.emojis.length,
              itemBuilder: (ctx, i) {
                final emoji = category.emojis[i];
                return GestureDetector(
                  onTap: () => _onEmojiTap(emoji),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                );
              },
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCustomTab() {
    return Column(
      children: [
        // Add from gallery button
        Padding(
          padding: const EdgeInsets.all(12),
          child: OutlinedButton.icon(
            onPressed: _addFromGallery,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Create from Photo'),
          ),
        ),
        // Custom stickers grid
        Expanded(
          child: _loadingCustom
              ? const Center(child: CircularProgressIndicator())
              : _customStickers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_emotions_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline),
                          const SizedBox(height: 8),
                          Text('No custom stickers yet',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                              )),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _customStickers.length,
                      itemBuilder: (ctx, i) {
                        final file = _customStickers[i];
                        return GestureDetector(
                          onTap: () => _onCustomStickerTap(file),
                          onLongPress: () => _onCustomStickerLongPress(file),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(file, fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
