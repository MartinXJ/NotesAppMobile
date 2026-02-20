import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/cupertino_theme.dart';
import 'core/utils/platform_utils.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/task_editor_screen.dart';
import 'data/database/isar_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/migration_service.dart';
import 'domain/services/theme_service.dart';
import 'domain/services/task_service.dart';
import 'domain/repositories/note_repository.dart';
import 'domain/repositories/task_repository.dart';
import 'data/repositories/note_repository_impl.dart';
import 'data/repositories/task_repository_impl.dart';

/// Global navigator key for deep linking from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar database
  await IsarService.getInstance();

  // Run migration from SermonNote/JournalNote to unified Note
  await MigrationService.migrateIfNeeded();

  // Initialize notifications
  await NotificationService.initialize();

  final taskRepository = TaskRepositoryImpl();
  final taskService = TaskService(taskRepository);
  final noteRepository = NoteRepositoryImpl();

  // Seed default templates
  await noteRepository.seedDefaultTemplates();

  // Load tasks and reschedule notifications on startup
  await taskService.loadTasks();
  await NotificationService.rescheduleAll(taskService.tasks);

  // Wire notification tap to navigate to task editor
  NotificationService.onNotificationTap = (taskId) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => TaskEditorScreen(taskId: taskId),
      ),
    );
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        Provider<NoteRepository>(create: (_) => noteRepository),
        Provider<TaskRepository>(create: (_) => taskRepository),
        ChangeNotifierProvider.value(value: taskService),
      ],
      child: const NotesApp(),
    ),
  );
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    if (PlatformUtils.isIOS) {
      return CupertinoApp(
        title: 'SoloNotes',
        theme: AppCupertinoTheme.lightTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
      );
    }

    return MaterialApp(
      title: 'SoloNotes',
      theme: themeService.resolveTheme(
        MediaQuery.platformBrightnessOf(context),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
    );
  }
}
