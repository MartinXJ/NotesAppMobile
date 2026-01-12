import 'package:flutter/cupertino.dart';

/// Cupertino theme configuration for iOS
class AppCupertinoTheme {
  // Private constructor to prevent instantiation
  AppCupertinoTheme._();

  // Cupertino Light Theme
  static CupertinoThemeData get lightTheme {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: CupertinoColors.systemPurple,
    );
  }

  // Cupertino Dark Theme
  static CupertinoThemeData get darkTheme {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: CupertinoColors.systemPurple,
    );
  }
}
