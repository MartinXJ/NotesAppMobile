import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../core/utils/platform_utils.dart';
import '../../domain/repositories/note_repository.dart';
import '../../data/models/note.dart';
import '../../data/models/note_template.dart';
import '../../data/models/media_attachment.dart';
import '../../data/services/media_service.dart';
import '../widgets/media_gallery_widget.dart';

/// Note editor screen with preview/edit mode and overflow menu
class NoteEditorScreen extends StatefulWidget {
  final int? noteId;
  final NoteTemplate? template;

  const NoteEditorScreen({
    super.key,
    this.noteId,
    this.template,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late QuillController _quillController;
  bool _isPreviewMode = false;
  bool _isLoading = true;
  bool _isSaving = false;
  Timer? _autoSaveTimer;

  // Note metadata (managed via overflow menu)
  String? _title;
  DateTime? _date;
  String _colorHex = '#FF9E9E9E';
  List<String> _tags = [];
  List<MediaAttachment> _mediaAttachments = [];
  int? _savedNoteId;

  // Template info for new notes
  bool _templateHasDate = false;

  final List<Map<String, dynamic>> _availableColors = [
    {'name': 'Grey', 'hex': '#FF9E9E9E', 'color': Colors.grey},
    {'name': 'Red', 'hex': '#FFEF5350', 'color': Colors.red},
    {'name': 'Pink', 'hex': '#FFEC407A', 'color': Colors.pink},
    {'name': 'Purple', 'hex': '#FFAB47BC', 'color': Colors.purple},
    {'name': 'Blue', 'hex': '#FF42A5F5', 'color': Colors.blue},
    {'name': 'Cyan', 'hex': '#FF26C6DA', 'color': Colors.cyan},
    {'name': 'Teal', 'hex': '#FF26A69A', 'color': Colors.teal},
    {'name': 'Green', 'hex': '#FF66BB6A', 'color': Colors.green},
    {'name': 'Yellow', 'hex': '#FFFFEE58', 'color': Colors.yellow},
    {'name': 'Orange', 'hex': '#FFFFA726', 'color': Colors.orange},
  ];

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    // Existing notes open in preview mode, new notes in edit mode
    _isPreviewMode = widget.noteId != null;
    _savedNoteId = widget.noteId;

    // Apply template defaults for new notes
    if (widget.template != null && widget.noteId == null) {
      _tags = List.from(widget.template!.defaultTags);
      _templateHasDate = widget.template!.hasDate;
      if (widget.template!.defaultColorHex != null) {
        _colorHex = widget.template!.defaultColorHex!;
      }
      if (_templateHasDate) {
        _date = DateTime.now();
      }
    }

    _loadNote();
    _quillController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _quillController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    _autoSaveTimer?.cancel();
    if (_savedNoteId != null) {
      _autoSaveTimer = Timer(const Duration(seconds: 2), () {
        _saveNote(showMessage: false);
      });
    }
  }

  Future<void> _loadNote() async {
    if (widget.noteId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final repository = Provider.of<NoteRepository>(context, listen: false);
    final note = await repository.getNoteById(widget.noteId!);
    if (note != null) {
      _title = note.title;
      _colorHex = note.colorHex;
      _tags = List.from(note.tags);
      _date = note.date;
      _mediaAttachments = List.from(note.mediaAttachments);

      if (note.content.isNotEmpty) {
        try {
          final doc = Document.fromJson(jsonDecode(note.content));
          _quillController = QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
          _quillController.addListener(_onContentChanged);
        } catch (e) {
          _quillController.document.insert(0, note.content);
        }
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveNote({bool showMessage = true}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final repository = Provider.of<NoteRepository>(context, listen: false);
    final content = jsonEncode(_quillController.document.toDelta().toJson());
    final plainText = _quillController.document.toPlainText();

    try {
      if (_savedNoteId == null) {
        // Create new note
        final note = Note()
          ..title = _title
          ..content = content
          ..plainTextContent = plainText
          ..colorHex = _colorHex
          ..tags = _tags
          ..date = _date
          ..mediaAttachments = _mediaAttachments
          ..createdAt = DateTime.now()
          ..modifiedAt = DateTime.now()
          ..deviceId = ''
          ..version = 1
          ..isSynced = false
          ..isDeleted = false;

        final id = await repository.createNote(note);
        _savedNoteId = id;

        if (showMessage && mounted) {
          _showSaveMessage('Note saved');
          Navigator.of(context).pop(true);
        }
      } else {
        // Update existing note
        final note = await repository.getNoteById(_savedNoteId!);
        if (note != null) {
          note.title = _title;
          note.content = content;
          note.plainTextContent = plainText;
          note.colorHex = _colorHex;
          note.tags = _tags;
          note.date = _date;
          note.mediaAttachments = _mediaAttachments;
          await repository.updateNote(note);

          if (showMessage && mounted) {
            _showSaveMessage('Note saved');
          }
        }
      }
    } catch (e) {
      if (showMessage && mounted) {
        _showSaveMessage('Error saving note: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleBack() async {
    _autoSaveTimer?.cancel();
    final hasContent = (_title != null && _title!.trim().isNotEmpty) ||
        _quillController.document.toPlainText().trim().isNotEmpty;
    if (_savedNoteId != null || hasContent) {
      await _saveNote(showMessage: false);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  void _showSaveMessage(String message) {
    if (PlatformUtils.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // --- Media actions ---

  Future<void> _addMedia() async {
    final picked = await MediaService.pickImages(maxCount: 9);
    if (picked.isEmpty) return;
    setState(() => _mediaAttachments.addAll(picked));
    if (_savedNoteId != null) _saveNote(showMessage: false);
  }

  void _removeMedia(int index) async {
    final attachment = _mediaAttachments[index];
    setState(() => _mediaAttachments.removeAt(index));
    await MediaService.deleteFile(attachment.localPath);
    if (_savedNoteId != null) _saveNote(showMessage: false);
  }

  void _renameMedia(int index, String newName) {
    final updated = MediaService.rename(_mediaAttachments[index], newName);
    setState(() => _mediaAttachments[index] = updated);
    if (_savedNoteId != null) _saveNote(showMessage: false);
  }

  // --- Overflow menu actions ---

  void _showOverflowMenu() {
    if (PlatformUtils.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () { Navigator.pop(context); _addMedia(); },
              child: const Text('Add Media'),
            ),
            CupertinoActionSheetAction(
              onPressed: () { Navigator.pop(context); _editTitle(); },
              child: const Text('Edit Title'),
            ),
            CupertinoActionSheetAction(
              onPressed: () { Navigator.pop(context); _pickDate(); },
              child: Text(_date != null ? 'Change Date' : 'Set Date'),
            ),
            CupertinoActionSheetAction(
              onPressed: () { Navigator.pop(context); _manageTags(); },
              child: const Text('Manage Tags'),
            ),
            CupertinoActionSheetAction(
              onPressed: () { Navigator.pop(context); _pickColor(); },
              child: const Text('Pick Color'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () { Navigator.pop(context); _deleteNote(); },
              child: const Text('Delete Note'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Add Media'),
                onTap: () { Navigator.pop(context); _addMedia(); },
              ),
              ListTile(
                leading: const Icon(Icons.title),
                title: const Text('Edit Title'),
                subtitle: Text(_title ?? 'No title'),
                onTap: () { Navigator.pop(context); _editTitle(); },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(_date != null ? 'Change Date' : 'Set Date'),
                subtitle: _date != null
                    ? Text(DateFormat('MMM d, yyyy').format(_date!))
                    : null,
                onTap: () { Navigator.pop(context); _pickDate(); },
              ),
              ListTile(
                leading: const Icon(Icons.label),
                title: const Text('Manage Tags'),
                subtitle: Text(_tags.isEmpty ? 'No tags' : _tags.join(', ')),
                onTap: () { Navigator.pop(context); _manageTags(); },
              ),
              ListTile(
                leading: Icon(Icons.circle,
                    color: Color(int.parse(
                        _colorHex.replaceFirst('#', '0x')))),
                title: const Text('Pick Color'),
                onTap: () { Navigator.pop(context); _pickColor(); },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Note',
                    style: TextStyle(color: Colors.red)),
                onTap: () { Navigator.pop(context); _deleteNote(); },
              ),
            ],
          ),
        ),
      );
    }
  }

  void _editTitle() {
    final controller = TextEditingController(text: _title ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Title'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Note title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _title = controller.text.trim().isEmpty
                  ? null : controller.text.trim());
              Navigator.pop(context);
              if (_savedNoteId != null) _saveNote(showMessage: false);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    if (PlatformUtils.isIOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Clear'),
                    onPressed: () {
                      setState(() => _date = null);
                      Navigator.pop(context);
                      if (_savedNoteId != null) _saveNote(showMessage: false);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _date ?? DateTime.now(),
                  onDateTimeChanged: (date) {
                    setState(() => _date = date);
                    if (_savedNoteId != null) _saveNote(showMessage: false);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _date ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        setState(() => _date = picked);
        if (_savedNoteId != null) _saveNote(showMessage: false);
      }
    }
  }

  void _manageTags() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Manage Tags'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _tags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () {
                    setDialogState(() => _tags.remove(tag));
                    setState(() {});
                  },
                )).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(hintText: 'Add tag'),
                      onSubmitted: (value) {
                        final tag = value.trim();
                        if (tag.isNotEmpty && !_tags.contains(tag)) {
                          setDialogState(() => _tags.add(tag));
                          setState(() {});
                          controller.clear();
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final tag = controller.text.trim();
                      if (tag.isNotEmpty && !_tags.contains(tag)) {
                        setDialogState(() => _tags.add(tag));
                        setState(() {});
                        controller.clear();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (_savedNoteId != null) _saveNote(showMessage: false);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableColors.map((colorData) {
            return GestureDetector(
              onTap: () {
                setState(() => _colorHex = colorData['hex']);
                Navigator.pop(context);
                if (_savedNoteId != null) _saveNote(showMessage: false);
              },
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: colorData['color'],
                  shape: BoxShape.circle,
                  border: _colorHex == colorData['hex']
                      ? Border.all(color: Colors.black, width: 3) : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _deleteNote() async {
    if (_savedNoteId == null) {
      Navigator.of(context).pop(false);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Move this note to trash?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final repository = Provider.of<NoteRepository>(context, listen: false);
      await repository.deleteNote(_savedNoteId!);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return PlatformUtils.isIOS
          ? const CupertinoPageScaffold(
              child: Center(child: CupertinoActivityIndicator()))
          : const Scaffold(
              body: Center(child: CircularProgressIndicator()));
    }

    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.back),
            onPressed: () => _handleBack(),
          ),
          middle: Text(_isPreviewMode ? 'Preview' : 'Edit'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isPreviewMode)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Save'),
                  onPressed: () => _saveNote(),
                ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showOverflowMenu,
                child: const Icon(CupertinoIcons.ellipsis),
              ),
            ],
          ),
        ),
        child: SafeArea(child: _buildBody()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBack(),
          ),
          title: Text(_isPreviewMode ? 'Preview' : 'Edit'),
          actions: [
            if (!_isPreviewMode)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => _saveNote(),
              ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showOverflowMenu,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isPreviewMode) {
      // Preview mode: read-only Quill, double-tap to edit
      return GestureDetector(
        onDoubleTap: () {
          setState(() => _isPreviewMode = false);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_mediaAttachments.isNotEmpty)
                MediaGalleryWidget(
                  attachments: _mediaAttachments,
                  isEditing: false,
                  onAddMedia: () {},
                  onRemove: (_) {},
                  onRename: (_, _) {},
                ),
              QuillEditor.basic(
                controller: _quillController,
                config: const QuillEditorConfig(
                  showCursor: false,
                  enableInteractiveSelection: false,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Edit mode: toolbar + editable Quill
    return Column(
      children: [
        QuillSimpleToolbar(
          controller: _quillController,
          config: const QuillSimpleToolbarConfig(),
        ),
        const SizedBox(height: 4),
        // Media gallery
        MediaGalleryWidget(
          attachments: _mediaAttachments,
          isEditing: true,
          onAddMedia: _addMedia,
          onRemove: _removeMedia,
          onRename: _renameMedia,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: QuillEditor.basic(
              controller: _quillController,
              config: const QuillEditorConfig(),
            ),
          ),
        ),
      ],
    );
  }
}
