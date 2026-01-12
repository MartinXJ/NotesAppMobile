import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/cupertino_theme.dart';
import 'core/utils/platform_utils.dart';
import 'presentation/screens/home_screen.dart';
import 'data/database/isar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Isar database
  await IsarService.getInstance();
  
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Cupertino app for iOS, Material app for Android
    if (PlatformUtils.isIOS) {
      return CupertinoApp(
        title: 'Notes App',
        theme: AppCupertinoTheme.lightTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    // Material Design for Android
    return MaterialApp(
      title: 'Notes App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
