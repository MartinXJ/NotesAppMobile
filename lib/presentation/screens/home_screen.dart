import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../core/utils/platform_utils.dart';
import '../../core/utils/note_utils.dart';
import '../../domain/services/theme_service.dart';
import '../../domain/services/search_service.dart';
import '../../domain/services/filter_service.dart';
import '../../domain/repositories/note_repository.dart';
import '../../data/models/note.dart';
import '../../data/models/note_template.dart';
import '../../data/models/enums.dart';
import '../widgets/note_card.dart';
import '../widgets/filter_panel.dart';
import 'note_editor_screen.dart';
import 'task_list_screen.dart';

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
    const TaskListScreen(),
    const SettingsView(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          items: const [
            BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.doc_text), label: 'Notes'),
            BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.search), label: 'Search'),
            BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.checkmark_square), label: 'Tasks'),
            BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.settings), label: 'Settings'),
          ],
        ),
        tabBuilder: (context, index) =>
            CupertinoTabView(builder: (context) => _screens[index]),
      );
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.note), label: 'Notes'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

/// Notes list view with unified Note model
class NotesListView extends StatefulWidget {
  const NotesListView({super.key});

  @override
  State<NotesListView> createState() => _NotesListViewState();
}

class _NotesListViewState extends State<NotesListView> {
  List<Note> _notes = [];
  bool _isLoading = true;
  NoteFilter _advancedFilter = NoteFilter();
  final FilterService _filterService = FilterService();
  List<String> _availableTags = [];
  List<String> _selectedTagFilters = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final repository = Provider.of<NoteRepository>(context, listen: false);
    final tags = await repository.getAllTags();
    if (mounted) setState(() => _availableTags = tags);
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final repository = Provider.of<NoteRepository>(context, listen: false);

    List<Note> notes;
    if (_selectedTagFilters.isEmpty &&
        _advancedFilter.color == null &&
        _advancedFilter.startDate == null) {
      notes = await repository.getAllNotes();
    } else {
      notes = await _filterService.applyFilters(NoteFilter(
        tags: _selectedTagFilters.isEmpty ? null : _selectedTagFilters,
        color: _advancedFilter.color,
        startDate: _advancedFilter.startDate,
        endDate: _advancedFilter.endDate,
        dateFilterType: _advancedFilter.dateFilterType,
      ));
    }

    if (mounted) {
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    }
  }

  void _onTagFilterChanged(String tag) {
    setState(() {
      if (_selectedTagFilters.contains(tag)) {
        _selectedTagFilters.remove(tag);
      } else {
        _selectedTagFilters.add(tag);
      }
    });
    _loadNotes();
  }

  void _clearTagFilters() {
    setState(() => _selectedTagFilters.clear());
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
                _selectedTagFilters = List.from(filter.tags ?? []);
              });
              _loadNotes();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToEditor({int? noteId, NoteTemplate? template}) async {
    final result = await Navigator.of(context).push(
      PlatformUtils.isIOS
          ? CupertinoPageRoute(
              builder: (context) => NoteEditorScreen(
                  noteId: noteId, template: template))
          : MaterialPageRoute(
              builder: (context) => NoteEditorScreen(
                  noteId: noteId, template: template)),
    );
    if (result == true) {
      _loadNotes();
      _loadTags();
    }
  }

  void _showTemplatePicker() {
    final repository = Provider.of<NoteRepository>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (context) => FutureBuilder<List<NoteTemplate>>(
        future: repository.getAllTemplates(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()));
          }
          final templates = snapshot.data!;
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Choose Template',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                ...templates.map((t) => ListTile(
                      leading: const Icon(Icons.description),
                      title: Text(t.name),
                      subtitle: Text(t.defaultTags.isEmpty
                          ? 'No default tags'
                          : t.defaultTags.join(', ')),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToEditor(template: t);
                      },
                    )),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTagFilterChips() {
    if (_availableTags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _selectedTagFilters.isEmpty,
              onSelected: (_) => _clearTagFilters(),
            ),
            const SizedBox(width: 8),
            ..._availableTags.map((tag) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tag),
                    selected: _selectedTagFilters.contains(tag),
                    onSelected: (_) => _onTagFilterChanged(tag),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Notes')),
        child: SafeArea(
          child: Column(
            children: [
              _buildTagFilterChips(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : _notes.isEmpty
                        ? _buildEmptyState()
                        : _buildNotesList(),
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
              isLabelVisible: _advancedFilter.tags != null ||
                  _advancedFilter.color != null ||
                  _advancedFilter.startDate != null,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterPanel,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTagFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? _buildEmptyState()
                    : _buildNotesList(),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onLongPress: _showTemplatePicker,
        child: FloatingActionButton(
          onPressed: () => _navigateToEditor(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note, size: 64,
              color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('No notes yet',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        final preview = note.plainTextContent.length > 100
            ? '${note.plainTextContent.substring(0, 100)}...'
            : note.plainTextContent;

        return NoteCard(
          id: note.id,
          displayTitle: getDisplayTitle(note),
          preview: preview.isEmpty ? 'No content' : preview,
          modifiedAt: note.modifiedAt,
          date: note.date,
          colorHex: note.colorHex,
          tags: note.tags,
          onTap: () => _navigateToEditor(noteId: note.id),
        );
      },
    );
  }
}

/// Search view with real-time search
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
      setState(() { _results = []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    final results = await _searchService.search(query);
    if (mounted) {
      setState(() { _results = results; _isSearching = false; });
    }
  }

  Widget _highlightText(String text, String query, TextStyle? baseStyle) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle, maxLines: 2,
          overflow: TextOverflow.ellipsis);
    }
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
        spans.add(TextSpan(
            text: text.substring(start, index), style: baseStyle));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: baseStyle?.copyWith(
          backgroundColor: Colors.yellow.withValues(alpha: 0.4),
          fontWeight: FontWeight.bold,
        ),
      ));
      start = index + query.length;
    }

    return RichText(
        text: TextSpan(children: spans),
        maxLines: 2, overflow: TextOverflow.ellipsis);
  }

  void _navigateToNote(SearchResult result) {
    Navigator.of(context).push(
      PlatformUtils.isIOS
          ? CupertinoPageRoute(
              builder: (context) => NoteEditorScreen(noteId: result.id))
          : MaterialPageRoute(
              builder: (context) => NoteEditorScreen(noteId: result.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Search')),
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
            Icon(Icons.search, size: 64,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('Search your notes',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('No results found',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return ListTile(
          leading: const Icon(Icons.note),
          title: _highlightText(result.displayTitle, query,
              Theme.of(context).textTheme.titleMedium),
          subtitle: _highlightText(result.contentPreview, query,
              Theme.of(context).textTheme.bodySmall),
          trailing: Text(DateFormat('MMM d').format(result.modifiedAt),
              style: Theme.of(context).textTheme.bodySmall),
          onTap: () => _navigateToNote(result),
        );
      },
    );
  }
}

/// Settings view
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Settings')),
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
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
            onTap: () {},
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
