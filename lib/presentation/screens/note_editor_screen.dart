import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../core/utils/platform_utils.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../data/models/sermon_note.dart';
import '../../data/models/journal_note.dart';
import '../../data/models/enums.dart';

/// Note editor screen for creating and editing notes
class NoteEditorScreen extends StatefulWidget {
  final int? noteId;
  final NoteType? initialNoteType;
  final bool isSermon;

  const NoteEditorScreen({
    super.key,
    this.noteId,
    this.initialNoteType,
    this.isSermon = false,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _tagController = TextEditingController();
  late QuillController _quillController;
  
  NoteType _noteType = NoteType.journal;
  String _selectedColor = '#FF9E9E9E'; // Default grey
  List<String> _tags = [];
  DateTime _sermonDate = DateTime.now(); // For sermon notes
  bool _isLoading = true;
  bool _isSaving = false;
  Timer? _autoSaveTimer;
  
  // Available colors for notes
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
    _noteType = widget.initialNoteType ?? (widget.isSermon ? NoteType.sermon : NoteType.journal);
    _quillController = QuillController.basic();
    _loadNote();
    
    // Set up auto-save
    _quillController.addListener(_onContentChanged);
    _titleController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _tagController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    // Cancel existing timer
    _autoSaveTimer?.cancel();
    
    // Start new timer for auto-save (2 seconds after last change)
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _saveNote(showMessage: false);
    });
  }

  Future<void> _loadNote() async {
    if (widget.noteId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final repository = Provider.of<NotesRepository>(context, listen: false);
    
    if (_noteType == NoteType.sermon) {
      final note = await repository.getSermonNoteById(widget.noteId!);
      if (note != null) {
        _titleController.text = note.title;
        _selectedColor = note.colorHex;
        _tags = List.from(note.tags);
        _sermonDate = note.sermonDate;
        
        // Load Quill document from JSON
        if (note.content.isNotEmpty) {
          try {
            final doc = Document.fromJson(jsonDecode(note.content));
            _quillController = QuillController(
              document: doc,
              selection: const TextSelection.collapsed(offset: 0),
            );
          } catch (e) {
            // If JSON parsing fails, treat as plain text
            _quillController.document.insert(0, note.content);
          }
        }
      }
    } else {
      final note = await repository.getJournalNoteById(widget.noteId!);
      if (note != null) {
        _titleController.text = note.title;
        _selectedColor = note.colorHex;
        _tags = List.from(note.tags);
        
        // Load Quill document from JSON
        if (note.content.isNotEmpty) {
          try {
            final doc = Document.fromJson(jsonDecode(note.content));
            _quillController = QuillController(
              document: doc,
              selection: const TextSelection.collapsed(offset: 0),
            );
          } catch (e) {
            // If JSON parsing fails, treat as plain text
            _quillController.document.insert(0, note.content);
          }
        }
      }
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveNote({bool showMessage = true}) async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    final repository = Provider.of<NotesRepository>(context, listen: false);
    final content = jsonEncode(_quillController.document.toDelta().toJson());
    final plainText = _quillController.document.toPlainText();
    
    try {
      if (_noteType == NoteType.sermon) {
        if (widget.noteId == null) {
          // Create new sermon note
          final note = SermonNote()
            ..title = _titleController.text.trim()
            ..content = content
            ..plainTextContent = plainText
            ..colorHex = _selectedColor
            ..tags = _tags
            ..sermonDate = _sermonDate
            ..createdAt = DateTime.now()
            ..modifiedAt = DateTime.now()
            ..deviceId = ''
            ..version = 1
            ..isSynced = false
            ..isDeleted = false;
          
          await repository.createSermonNote(note);
          
          if (showMessage && mounted) {
            _showSaveMessage('Note saved');
          }
          
          // Navigate back with the new note ID
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } else {
          // Update existing sermon note
          final note = await repository.getSermonNoteById(widget.noteId!);
          if (note != null) {
            note.title = _titleController.text.trim();
            note.content = content;
            note.plainTextContent = plainText;
            note.colorHex = _selectedColor;
            note.tags = _tags;
            
            await repository.updateSermonNote(note);
            
            if (showMessage && mounted) {
              _showSaveMessage('Note saved');
            }
          }
        }
      } else {
        if (widget.noteId == null) {
          // Create new journal note
          final note = JournalNote()
            ..title = _titleController.text.trim()
            ..content = content
            ..plainTextContent = plainText
            ..colorHex = _selectedColor
            ..tags = _tags
            ..createdAt = DateTime.now()
            ..modifiedAt = DateTime.now()
            ..deviceId = ''
            ..version = 1
            ..isSynced = false
            ..isDeleted = false;
          
          await repository.createJournalNote(note);
          
          if (showMessage && mounted) {
            _showSaveMessage('Note saved');
          }
          
          // Navigate back with the new note ID
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } else {
          // Update existing journal note
          final note = await repository.getJournalNoteById(widget.noteId!);
          if (note != null) {
            note.title = _titleController.text.trim();
            note.content = content;
            note.plainTextContent = plainText;
            note.colorHex = _selectedColor;
            note.tags = _tags;
            
            await repository.updateJournalNote(note);
            
            if (showMessage && mounted) {
              _showSaveMessage('Note saved');
            }
          }
        }
      }
    } catch (e) {
      if (showMessage && mounted) {
        _showSaveMessage('Error saving note: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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

  void _showColorPicker() {
    if (PlatformUtils.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Choose Color'),
          actions: _availableColors.map((colorData) {
            return CupertinoActionSheetAction(
              onPressed: () {
                setState(() => _selectedColor = colorData['hex']);
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorData['color'],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(colorData['name']),
                ],
              ),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
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
                  setState(() => _selectedColor = colorData['hex']);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorData['color'],
                    shape: BoxShape.circle,
                    border: _selectedColor == colorData['hex']
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Widget _buildSermonDatePicker() {
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(_sermonDate);
    
    if (PlatformUtils.isIOS) {
      return GestureDetector(
        onTap: _showSermonDatePicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.calendar, size: 20, color: CupertinoColors.activeBlue),
              const SizedBox(width: 8),
              const Text('Sermon Date', style: TextStyle(fontSize: 14, color: CupertinoColors.secondaryLabel)),
              const Spacer(),
              Text(dateStr, style: const TextStyle(fontSize: 14, color: CupertinoColors.activeBlue)),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: _showSermonDatePicker,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('Sermon Date', style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            Text(dateStr, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
    );
  }

  Future<void> _showSermonDatePicker() async {
    if (PlatformUtils.isIOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: 260,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
                  CupertinoButton(child: const Text('Done'), onPressed: () => Navigator.pop(context)),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _sermonDate,
                  onDateTimeChanged: (date) => setState(() => _sermonDate = date),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _sermonDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        setState(() => _sermonDate = picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return PlatformUtils.isIOS
          ? const CupertinoPageScaffold(
              child: Center(child: CupertinoActivityIndicator()),
            )
          : const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
    }

    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.noteId == null ? 'New Note' : 'Edit Note'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text('Save'),
            onPressed: () => _saveNote(),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildEditorContent(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveNote(),
          ),
        ],
      ),
      body: _buildEditorContent(),
    );
  }

  Widget _buildEditorContent() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Note Title',
                border: PlatformUtils.isIOS ? null : const OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Note type and color selector
            Row(
              children: [
                // Note type chip
                if (PlatformUtils.isIOS)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _noteType == NoteType.sermon ? 'Sermon' : 'Journal',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )
                else
                  Chip(
                    label: Text(_noteType == NoteType.sermon ? 'Sermon' : 'Journal'),
                  ),
                const SizedBox(width: 8),
                
                // Color picker button
                GestureDetector(
                  onTap: _showColorPicker,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(int.parse(_selectedColor.replaceFirst('#', '0x'))),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sermon date picker (only for sermon notes)
            if (_noteType == NoteType.sermon) ...[
              _buildSermonDatePicker(),
              const SizedBox(height: 16),
            ],
            
            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._tags.map((tag) => PlatformUtils.isIOS
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey5,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tag, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _removeTag(tag),
                              child: const Icon(CupertinoIcons.xmark_circle_fill, size: 16),
                            ),
                          ],
                        ),
                      )
                    : Chip(
                        label: Text(tag),
                        onDeleted: () => _removeTag(tag),
                      ),
                ),
                // Add tag button
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: 'Add tag',
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addTag,
                      ),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Quill toolbar
            QuillSimpleToolbar(
              controller: _quillController,
              config: const QuillSimpleToolbarConfig(),
            ),
            const SizedBox(height: 8),
            
            // Quill editor
            Container(
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QuillEditor.basic(
                controller: _quillController,
                config: const QuillEditorConfig(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
