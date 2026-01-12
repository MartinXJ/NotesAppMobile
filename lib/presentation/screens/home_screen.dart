import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/utils/platform_utils.dart';
import '../../domain/services/theme_service.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../data/models/sermon_note.dart';
import '../../data/models/journal_note.dart';
import '../../data/models/enums.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';

/// Home screen displaying the notes list
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const NotesListView(),
    const SearchView(),
    const SettingsView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.doc_text),
              label: 'Notes',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.settings),
              label: 'Settings',
            ),
          ],
        ),
        tabBuilder: (context, index) {
          return CupertinoTabView(
            builder: (context) => _screens[index],
          );
        },
      );
    }

    // Android Material Design
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.note),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Notes list view with real data
class NotesListView extends StatefulWidget {
  const NotesListView({super.key});

  @override
  State<NotesListView> createState() => _NotesListViewState();
}

class _NotesListViewState extends State<NotesListView> {
  List<dynamic> _allNotes = [];
  bool _isLoading = true;
  NoteType? _selectedFilter; // null = all, NoteType.sermon, NoteType.journal

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    
    final repository = Provider.of<NotesRepository>(context, listen: false);
    
    // Fetch notes based on filter
    List<dynamic> allNotes;
    
    if (_selectedFilter == NoteType.sermon) {
      allNotes = await repository.getAllSermonNotes();
    } else if (_selectedFilter == NoteType.journal) {
      allNotes = await repository.getAllJournalNotes();
    } else {
      // Fetch both sermon and journal notes
      final sermonNotes = await repository.getAllSermonNotes();
      final journalNotes = await repository.getAllJournalNotes();
      allNotes = <dynamic>[...sermonNotes, ...journalNotes];
    }
    
    // Sort by modified date (most recent first)
    allNotes.sort((a, b) {
      final aDate = a is SermonNote ? a.modifiedAt : (a as JournalNote).modifiedAt;
      final bDate = b is SermonNote ? b.modifiedAt : (b as JournalNote).modifiedAt;
      return bDate.compareTo(aDate);
    });
    
    setState(() {
      _allNotes = allNotes;
      _isLoading = false;
    });
  }

  void _onFilterChanged(NoteType? filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadNotes();
  }

  Future<void> _navigateToEditor({int? noteId, NoteType? noteType, bool isSermon = false}) async {
    final result = await Navigator.of(context).push(
      PlatformUtils.isIOS
          ? CupertinoPageRoute(
              builder: (context) => NoteEditorScreen(
                noteId: noteId,
                initialNoteType: noteType,
                isSermon: isSermon,
              ),
            )
          : MaterialPageRoute(
              builder: (context) => NoteEditorScreen(
                noteId: noteId,
                initialNoteType: noteType,
                isSermon: isSermon,
              ),
            ),
    );
    
    // Reload notes if a note was saved
    if (result == true) {
      _loadNotes();
    }
  }

  void _showNoteTypeDialog() {
    if (PlatformUtils.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Choose Note Type'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _navigateToEditor(noteType: NoteType.sermon, isSermon: true);
              },
              child: const Text('Sermon Note'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _navigateToEditor(noteType: NoteType.journal, isSermon: false);
              },
              child: const Text('Journal Note'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Choose Note Type'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _navigateToEditor(noteType: NoteType.sermon, isSermon: true);
              },
              child: const Text('Sermon Note'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _navigateToEditor(noteType: NoteType.journal, isSermon: false);
              },
              child: const Text('Journal Note'),
            ),
          ],
        ),
      );
    }
  }

  String _getPreview(String content) {
    // Extract plain text preview from content (first 100 chars)
    if (content.isEmpty) return 'No content';
    return content.length > 100 ? '${content.substring(0, 100)}...' : content;
  }

  Widget _buildFilterChips() {
    if (PlatformUtils.isIOS) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildCupertinoFilterChip('All', _selectedFilter == null),
            const SizedBox(width: 8),
            _buildCupertinoFilterChip('Sermons', _selectedFilter == NoteType.sermon),
            const SizedBox(width: 8),
            _buildCupertinoFilterChip('Journal', _selectedFilter == NoteType.journal),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedFilter == null,
            onSelected: (_) => _onFilterChanged(null),
          ),
          FilterChip(
            label: const Text('Sermons'),
            selected: _selectedFilter == NoteType.sermon,
            onSelected: (_) => _onFilterChanged(NoteType.sermon),
          ),
          FilterChip(
            label: const Text('Journal'),
            selected: _selectedFilter == NoteType.journal,
            onSelected: (_) => _onFilterChanged(NoteType.journal),
          ),
        ],
      ),
    );
  }

  Widget _buildCupertinoFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (label == 'All') {
          _onFilterChanged(null);
        } else if (label == 'Sermons') {
          _onFilterChanged(NoteType.sermon);
        } else if (label == 'Journal') {
          _onFilterChanged(NoteType.journal);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoColors.activeBlue
              : CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? CupertinoColors.white
                : CupertinoColors.label,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Notes'),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : _allNotes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.doc_text,
                                  size: 64,
                                  color: CupertinoColors.systemGrey,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No notes yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _allNotes.length,
                            itemBuilder: (context, index) {
                              final note = _allNotes[index];
                              
                              if (note is SermonNote) {
                                return NoteCard(
                                  id: note.id,
                                  title: note.title,
                                  preview: _getPreview(note.content),
                                  modifiedAt: note.modifiedAt,
                                  colorHex: note.colorHex,
                                  tags: note.tags,
                                  noteType: NoteType.sermon,
                                  onTap: () => _navigateToEditor(
                                    noteId: note.id,
                                    noteType: NoteType.sermon,
                                    isSermon: true,
                                  ),
                                );
                              } else if (note is JournalNote) {
                                return NoteCard(
                                  id: note.id,
                                  title: note.title,
                                  preview: _getPreview(note.content),
                                  modifiedAt: note.modifiedAt,
                                  colorHex: note.colorHex,
                                  tags: note.tags,
                                  noteType: NoteType.journal,
                                  onTap: () => _navigateToEditor(
                                    noteId: note.id,
                                    noteType: NoteType.journal,
                                    isSermon: false,
                                  ),
                                );
                              }
                              
                              return const SizedBox.shrink();
                            },
                          ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notes yet',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _allNotes.length,
                        itemBuilder: (context, index) {
                          final note = _allNotes[index];
                          
                          if (note is SermonNote) {
                            return NoteCard(
                              id: note.id,
                              title: note.title,
                              preview: _getPreview(note.content),
                              modifiedAt: note.modifiedAt,
                              colorHex: note.colorHex,
                              tags: note.tags,
                              noteType: NoteType.sermon,
                              onTap: () => _navigateToEditor(
                                noteId: note.id,
                                noteType: NoteType.sermon,
                                isSermon: true,
                              ),
                            );
                          } else if (note is JournalNote) {
                            return NoteCard(
                              id: note.id,
                              title: note.title,
                              preview: _getPreview(note.content),
                              modifiedAt: note.modifiedAt,
                              colorHex: note.colorHex,
                              tags: note.tags,
                              noteType: NoteType.journal,
                              onTap: () => _navigateToEditor(
                                noteId: note.id,
                                noteType: NoteType.journal,
                                isSermon: false,
                              ),
                            );
                          }
                          
                          return const SizedBox.shrink();
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNoteTypeDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Placeholder for search view
class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Search'),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.search,
                  size: 64,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Search your notes',
                  style: TextStyle(
                    fontSize: 18,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Search your notes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for settings view
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Settings'),
        ),
        child: SafeArea(
          child: ListView(
            children: [
              CupertinoListSection.insetGrouped(
                header: const Text('APPEARANCE'),
                children: [
                  CupertinoListTile(
                    title: const Text('Theme'),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => _showThemeDialog(context),
                  ),
                ],
              ),
              CupertinoListSection.insetGrouped(
                header: const Text('SYNC'),
                children: [
                  CupertinoListTile(
                    title: const Text('Google Account'),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      // TODO: Navigate to account settings
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: const Text('Light, Dark, or System'),
            onTap: () => _showThemeDialog(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Google Account'),
            subtitle: const Text('Sign in to sync your notes'),
            onTap: () {
              // TODO: Navigate to account settings
            },
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);

    if (PlatformUtils.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Choose Theme'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                themeService.setThemeMode(AppThemeMode.light);
                Navigator.pop(context);
              },
              child: const Text('Light'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                themeService.setThemeMode(AppThemeMode.dark);
                Navigator.pop(context);
              },
              child: const Text('Dark'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                themeService.setThemeMode(AppThemeMode.system);
                Navigator.pop(context);
              },
              child: const Text('System'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Choose Theme'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                themeService.setThemeMode(AppThemeMode.light);
                Navigator.pop(context);
              },
              child: const Text('Light'),
            ),
            SimpleDialogOption(
              onPressed: () {
                themeService.setThemeMode(AppThemeMode.dark);
                Navigator.pop(context);
              },
              child: const Text('Dark'),
            ),
            SimpleDialogOption(
              onPressed: () {
                themeService.setThemeMode(AppThemeMode.system);
                Navigator.pop(context);
              },
              child: const Text('System'),
            ),
          ],
        ),
      );
    }
  }
}
