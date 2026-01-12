import 'package:flutter/material.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';

/// Service for managing app theme
class ThemeService extends ChangeNotifier {
  final SettingsRepository _settingsRepository = SettingsRepositoryImpl();
  AppThemeMode _themeMode = AppThemeMode.system;

  ThemeService() {
    _loadThemeMode();
  }

  /// Get current theme mode
  AppThemeMode get themeMode => _themeMode;

  /// Get Flutter ThemeMode from AppThemeMode
  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Load theme mode from settings
  Future<void> _loadThemeMode() async {
    final settings = await _settingsRepository.getSettings();
    _themeMode = settings.themeMode;
    notifyListeners();
  }

  /// Set theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _settingsRepository.updateThemeMode(mode);
    notifyListeners();
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = _themeMode == AppThemeMode.light
        ? AppThemeMode.dark
        : AppThemeMode.light;
    await setThemeMode(newMode);
  }
}
