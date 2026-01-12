import '../../domain/repositories/settings_repository.dart';
import '../database/isar_service.dart';
import '../models/app_settings.dart';
import '../models/enums.dart';

/// Implementation of SettingsRepository using Isar
class SettingsRepositoryImpl implements SettingsRepository {
  /// Get app settings (creates default if not exists)
  @override
  Future<AppSettings> getSettings() async {
    final isar = await IsarService.getInstance();
    var settings = await isar.appSettings.get(1);
    
    if (settings == null) {
      // Create default settings
      settings = AppSettings()
        ..id = 1
        ..themeMode = AppThemeMode.system
        ..autoSync = true
        ..syncIntervalMinutes = 15
        ..defaultNoteColor = '#FFFFFF'
        ..fontSize = 16.0;
      
      await isar.writeTxn(() async {
        await isar.appSettings.put(settings!);
      });
    }
    
    return settings;
  }

  /// Update theme mode
  @override
  Future<void> updateThemeMode(AppThemeMode themeMode) async {
    final isar = await IsarService.getInstance();
    final settings = await getSettings();
    settings.themeMode = themeMode;
    
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
  }

  /// Update auto-sync setting
  @override
  Future<void> updateAutoSync(bool enabled) async {
    final isar = await IsarService.getInstance();
    final settings = await getSettings();
    settings.autoSync = enabled;
    
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
  }

  /// Update sync interval
  @override
  Future<void> updateSyncInterval(int minutes) async {
    final isar = await IsarService.getInstance();
    final settings = await getSettings();
    settings.syncIntervalMinutes = minutes;
    
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
  }

  /// Update last sync time
  @override
  Future<void> updateLastSyncTime(DateTime time) async {
    final isar = await IsarService.getInstance();
    final settings = await getSettings();
    settings.lastSyncTime = time;
    
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
  }

  /// Update default note color
  @override
  Future<void> updateDefaultNoteColor(String colorHex) async {
    final isar = await IsarService.getInstance();
    final settings = await getSettings();
    settings.defaultNoteColor = colorHex;
    
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
  }

  /// Update font size
  @override
  Future<void> updateFontSize(double size) async {
    final isar = await IsarService.getInstance();
    final settings = await getSettings();
    settings.fontSize = size;
    
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
  }

  /// Update Google account info
  @override
  Future<void> updateGoogleAccount(String? email, String? accountId) async {
    final isar = await IsarService.getInstance();
    final settings = await getSettings();
    settings.googleAccountEmail = email;
    settings.googleAccountId = accountId;
    
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
  }

  /// Reset settings to default
  @override
  Future<void> resetToDefaults() async {
    final isar = await IsarService.getInstance();
    final settings = AppSettings()
      ..id = 1
      ..themeMode = AppThemeMode.system
      ..autoSync = true
      ..syncIntervalMinutes = 15
      ..defaultNoteColor = '#FFFFFF'
      ..fontSize = 16.0;
    
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
  }
}
