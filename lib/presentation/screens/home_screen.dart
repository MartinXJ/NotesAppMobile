import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../core/utils/platform_utils.dart';
import '../../domain/services/theme_service.dart';
import '../../domain/services/search_service.dart';
import '../../domain/services/filter_service.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../data/models/sermon_note.dart';
import '../../data/models/journal_note.dart';
import '../../data/models/enums.dart';
import '../widgets/note_card.dart';
import '../widgets/filter_panel.dart';
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
  NoteFilter _advancedFilter = NoteFilter();
  final FilterService _filterService = FilterService();
  List<String> _availableTags = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final repository = Provider.of<NotesRepository>(context, listen: false);
    final tags = await repository.getAllTags();
    if (mounted) setState(() => _availableTags = tags);
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
      _advancedFilter = NoteFilter(type: filter);
    });
    _loadNotes();
  }

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: FilterPanel(
            currentFilter: _advancedFilter,
            availableTags: _availableTags,
            onFilterChanged: (filter) {
              setState(() {
                _advancedFilter = filter;
                _selectedFilter = filter.type;
              });
              _loadNotesWithFilter(filter);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _loadNotesWithFilter(NoteFilter filter) async {
    setState(() => _isLoading = true);
    final results = await _filterService.applyFilters(filter);
    if (mounted) {
      setState(() {
        _allNotes = results;
        _isLoading = false;
      });
    }
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
          title: const Text('Add Note'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _navigateToEditor(noteType: NoteType.journal, isSermon: false);
              },
              child: const Text('Journal Note'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _navigateToEditor(noteType: NoteType.sermon, isSermon: true);
              },
              child: const Text('Sermon Note'),
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
          title: const Text('Add Note'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _navigateToEditor(noteType: NoteType.journal, isSermon: false);
              },
              child: const Text('Journal Note'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _navigateToEditor(noteType: NoteType.sermon, isSermon: true);
              },
              child: const Text('Sermon Note'),
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
            _buildCupertinoFilterChip('Journal', _selectedFilter == NoteType.journal),
            const SizedBox(width: 8),
            _buildCupertinoFilterChip('Sermons', _selectedFilter == NoteType.sermon),
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
            label: const Text('Journal'),
            selected: _selectedFilter == NoteType.journal,
            onSelected: (_) => _onFilterChanged(NoteType.journal),
          ),
          FilterChip(
            label: const Text('Sermons'),
            selected: _selectedFilter == NoteType.sermon,
            onSelected: (_) => _onFilterChanged(NoteType.sermon),
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
        } else if (label == 'Journal') {
          _onFilterChanged(NoteType.journal);
        } else if (label == 'Sermons') {
          _onFilterChanged(NoteType.sermon);
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
                              
                              if (note is FilterResult) {
                                return NoteCard(
                                  id: note.id,
                                  title: note.title,
                                  preview: _getPreview(note.content),
                                  modifiedAt: note.modifiedAt,
                                  sermonDate: note.sermonDate,
                                  colorHex: note.colorHex,
                                  tags: note.tags,
                                  noteType: note.isSermon ? NoteType.sermon : NoteType.journal,
                                  onTap: () => _navigateToEditor(
                                    noteId: note.id,
                                    noteType: note.isSermon ? NoteType.sermon : NoteType.journal,
                                    isSermon: note.isSermon,
                                  ),
                                );
                              } else if (note is SermonNote) {
                                return NoteCard(
                                  id: note.id,
                                  title: note.title,
                                  preview: _getPreview(note.content),
                                  modifiedAt: note.modifiedAt,
                                  sermonDate: note.sermonDate,
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
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _advancedFilter.tags != null || _advancedFilter.color != null || _advancedFilter.startDate != null,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterPanel,
          ),
        ],
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
                          
                          if (note is FilterResult) {
                            return NoteCard(
                              id: note.id,
                              title: note.title,
                              preview: _getPreview(note.content),
                              modifiedAt: note.modifiedAt,
                              sermonDate: note.sermonDate,
                              colorHex: note.colorHex,
                              tags: note.tags,
                              noteType: note.isSermon ? NoteType.sermon : NoteType.journal,
                              onTap: () => _navigateToEditor(
                                noteId: note.id,
                                noteType: note.isSermon ? NoteType.sermon : NoteType.journal,
                                isSermon: note.isSermon,
                              ),
                            );
                          } else if (note is SermonNote) {
                            return NoteCard(
                              id: note.id,
                              title: note.title,
                              preview: _getPreview(note.content),
                              modifiedAt: note.modifiedAt,
                              sermonDate: note.sermonDate,
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

/// Search view with real-time search and result highlighting
class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _searchController = TextEditingController();
  final _searchService = SearchService();
  List<SearchResult> _results = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _searchService.search(query);
    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  Widget _highlightText(String text, String query, TextStyle? baseStyle) {
    if (query.isEmpty) return Text(text, style: baseStyle, maxLines: 2, overflow: TextOverflow.ellipsis);
    
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: baseStyle));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: baseStyle?.copyWith(
          backgroundColor: Colors.yellow.withValues(alpha: 0.4),
          fontWeight: FontWeight.bold,
        ) ?? const TextStyle(backgroundColor: Colors.yellow, fontWeight: FontWeight.bold),
      ));
      start = index + query.length;
    }

    return RichText(text: TextSpan(children: spans), maxLines: 2, overflow: TextOverflow.ellipsis);
  }

  void _navigateToNote(SearchResult result) {
    Navigator.of(context).push(
      PlatformUtils.isIOS
          ? CupertinoPageRoute(
              builder: (context) => NoteEditorScreen(
                noteId: result.id,
                initialNoteType: result.isSermon ? NoteType.sermon : NoteType.journal,
                isSermon: result.isSermon,
              ),
            )
          : MaterialPageRoute(
              builder: (context) => NoteEditorScreen(
                noteId: result.id,
                initialNoteType: result.isSermon ? NoteType.sermon : NoteType.journal,
                isSermon: result.isSermon,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Search'),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  placeholder: 'Search notes...',
                ),
              ),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search notes...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: false,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
      body: _buildResults(),
    );
  }

  Widget _buildResults() {
    final query = _searchController.text;

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('Search your notes', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('No results found', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        final preview = result.content.length > 120 ? '${result.content.substring(0, 120)}...' : result.content;

        return ListTile(
          leading: Icon(result.isSermon ? Icons.book : Icons.note),
          title: _highlightText(result.title.isEmpty ? 'Untitled' : result.title, query, Theme.of(context).textTheme.titleMedium),
          subtitle: _highlightText(preview, query, Theme.of(context).textTheme.bodySmall),
          trailing: Text(DateFormat('MMM d').format(result.modifiedAt), style: Theme.of(context).textTheme.bodySmall),
          onTap: () => _navigateToNote(result),
        );
      },
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
