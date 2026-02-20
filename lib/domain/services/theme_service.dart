import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
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

  AppThemeMode get themeMode => _themeMode;

  /// Whether the current mode delegates to system brightness
  bool get isSystemMode =>
      _themeMode == AppThemeMode.system;

  /// Get the resolved ThemeData for the current mode + platform brightness
  ThemeData resolveTheme(Brightness platformBrightness) {
    return AppTheme.getTheme(_themeMode, platformBrightness: platformBrightness);
  }

  Future<void> _loadThemeMode() async {
    final settings = await _settingsRepository.getSettings();
    _themeMode = settings.themeMode;
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _settingsRepository.updateThemeMode(mode);
    notifyListeners();
  }
}
