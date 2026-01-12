import '../../data/models/app_settings.dart';
import '../../data/models/enums.dart';

/// Repository interface for app settings management
abstract class SettingsRepository {
  /// Get app settings (creates default if not exists)
  Future<AppSettings> getSettings();
  
  /// Update theme mode
  Future<void> updateThemeMode(AppThemeMode themeMode);
  
  /// Update auto-sync setting
  Future<void> updateAutoSync(bool enabled);
  
  /// Update sync interval
  Future<void> updateSyncInterval(int minutes);
  
  /// Update last sync time
  Future<void> updateLastSyncTime(DateTime time);
  
  /// Update default note color
  Future<void> updateDefaultNoteColor(String colorHex);
  
  /// Update font size
  Future<void> updateFontSize(double size);
  
  /// Update Google account info
  Future<void> updateGoogleAccount(String? email, String? accountId);
  
  /// Reset settings to default
  Future<void> resetToDefaults();
}
