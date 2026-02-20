import 'package:flutter/material.dart';
import '../../data/models/enums.dart';

/// All app themes — default + 7 creative themes
class AppTheme {
  AppTheme._();

  // Shared card & FAB styling
  static const _cardTheme = CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );
  static const _fabTheme = FloatingActionButtonThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );
  static const _appBarTheme = AppBarTheme(centerTitle: true, elevation: 0);

  /// Build a ThemeData from a ColorScheme
  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: _appBarTheme.copyWith(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: _cardTheme,
      floatingActionButtonTheme: _fabTheme,
      scaffoldBackgroundColor: scheme.surface,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
      ),
    );
  }

  // ── Default Light ──
  static ThemeData get lightTheme => _build(
        ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      );

  // ── Default Dark ──
  static ThemeData get darkTheme => _build(
        ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      );

  // ── Matte ── warm muted tones, soft contrast
  static ThemeData get matteTheme => _build(
        const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFBFA98E),
          onPrimary: Color(0xFF2C2418),
          primaryContainer: Color(0xFF4A3C2E),
          onPrimaryContainer: Color(0xFFE8D5BF),
          secondary: Color(0xFFA89B8C),
          onSecondary: Color(0xFF2A2520),
          secondaryContainer: Color(0xFF3E3830),
          onSecondaryContainer: Color(0xFFD4C8BA),
          tertiary: Color(0xFFC4A882),
          onTertiary: Color(0xFF2E2214),
          tertiaryContainer: Color(0xFF4D3D2A),
          onTertiaryContainer: Color(0xFFEAD6BC),
          error: Color(0xFFCF6679),
          onError: Color(0xFF1E1214),
          errorContainer: Color(0xFF442C30),
          onErrorContainer: Color(0xFFE8B4BC),
          surface: Color(0xFF2A2622),
          onSurface: Color(0xFFD8CCBE),
          surfaceContainerHighest: Color(0xFF3A3530),
          outline: Color(0xFF6B6158),
          outlineVariant: Color(0xFF4A4540),
          surfaceContainer: Color(0xFF322E28),
        ),
      );

  // ── Panda ── black & white with soft grays 🐼
  static ThemeData get pandaTheme => _build(
        const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFE8E8E8),
          onPrimary: Color(0xFF1A1A1A),
          primaryContainer: Color(0xFF3A3A3A),
          onPrimaryContainer: Color(0xFFF0F0F0),
          secondary: Color(0xFFB0B0B0),
          onSecondary: Color(0xFF1A1A1A),
          secondaryContainer: Color(0xFF2E2E2E),
          onSecondaryContainer: Color(0xFFD8D8D8),
          tertiary: Color(0xFFCCCCCC),
          onTertiary: Color(0xFF1A1A1A),
          tertiaryContainer: Color(0xFF404040),
          onTertiaryContainer: Color(0xFFE8E8E8),
          error: Color(0xFFFF6B6B),
          onError: Color(0xFF1A1A1A),
          errorContainer: Color(0xFF3D2020),
          onErrorContainer: Color(0xFFFFB4B4),
          surface: Color(0xFF1A1A1A),
          onSurface: Color(0xFFE8E8E8),
          surfaceContainerHighest: Color(0xFF333333),
          outline: Color(0xFF666666),
          outlineVariant: Color(0xFF404040),
          surfaceContainer: Color(0xFF222222),
        ),
      );

  // ── Rose Pink ── warm pink tones
  static ThemeData get rosePinkTheme => _build(
        const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFFBE4B6E),
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFFFFD9E2),
          onPrimaryContainer: Color(0xFF3F0020),
          secondary: Color(0xFF9C4060),
          onSecondary: Color(0xFFFFFFFF),
          secondaryContainer: Color(0xFFFFD9E2),
          onSecondaryContainer: Color(0xFF3E001D),
          tertiary: Color(0xFFD4688A),
          onTertiary: Color(0xFFFFFFFF),
          tertiaryContainer: Color(0xFFFFE1EA),
          onTertiaryContainer: Color(0xFF3E0022),
          error: Color(0xFFBA1A1A),
          onError: Color(0xFFFFFFFF),
          errorContainer: Color(0xFFFFDAD6),
          onErrorContainer: Color(0xFF410002),
          surface: Color(0xFFFFF8F8),
          onSurface: Color(0xFF2C1520),
          surfaceContainerHighest: Color(0xFFF5DDE4),
          outline: Color(0xFF9E7D88),
          outlineVariant: Color(0xFFD4BCC4),
          surfaceContainer: Color(0xFFFCEEF2),
        ),
      );

  // ── Forest ── deep greens, earthy
  static ThemeData get forestTheme => _build(
        const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF8FBF8F),
          onPrimary: Color(0xFF0A2E0A),
          primaryContainer: Color(0xFF1E4D1E),
          onPrimaryContainer: Color(0xFFB8E0B8),
          secondary: Color(0xFF7AAA7A),
          onSecondary: Color(0xFF0D280D),
          secondaryContainer: Color(0xFF1A3F1A),
          onSecondaryContainer: Color(0xFFA8D4A8),
          tertiary: Color(0xFFA4C89A),
          onTertiary: Color(0xFF122E0E),
          tertiaryContainer: Color(0xFF264822),
          onTertiaryContainer: Color(0xFFC4E8BC),
          error: Color(0xFFCF6679),
          onError: Color(0xFF1E1214),
          errorContainer: Color(0xFF442C30),
          onErrorContainer: Color(0xFFE8B4BC),
          surface: Color(0xFF121E12),
          onSurface: Color(0xFFD0E8D0),
          surfaceContainerHighest: Color(0xFF263826),
          outline: Color(0xFF4E6E4E),
          outlineVariant: Color(0xFF2E4A2E),
          surfaceContainer: Color(0xFF1A2C1A),
        ),
      );

  // ── Crimson ── bold reds, dramatic
  static ThemeData get crimsonTheme => _build(
        const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFFF6B6B),
          onPrimary: Color(0xFF2E0A0A),
          primaryContainer: Color(0xFF5C1A1A),
          onPrimaryContainer: Color(0xFFFFB4B4),
          secondary: Color(0xFFD4605A),
          onSecondary: Color(0xFF2A0E0C),
          secondaryContainer: Color(0xFF4A1E1A),
          onSecondaryContainer: Color(0xFFEAB0AC),
          tertiary: Color(0xFFE88A78),
          onTertiary: Color(0xFF2E1410),
          tertiaryContainer: Color(0xFF522820),
          onTertiaryContainer: Color(0xFFF4C4B8),
          error: Color(0xFFFFB4AB),
          onError: Color(0xFF370001),
          errorContainer: Color(0xFF5C1010),
          onErrorContainer: Color(0xFFFFDAD6),
          surface: Color(0xFF1E1212),
          onSurface: Color(0xFFE8D0D0),
          surfaceContainerHighest: Color(0xFF382424),
          outline: Color(0xFF7A5050),
          outlineVariant: Color(0xFF4A3030),
          surfaceContainer: Color(0xFF281A1A),
        ),
      );

  // ── Midnight ── deep navy blue
  static ThemeData get midnightTheme => _build(
        const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF8AB4F8),
          onPrimary: Color(0xFF0A1E3E),
          primaryContainer: Color(0xFF1A3460),
          onPrimaryContainer: Color(0xFFB8D4FF),
          secondary: Color(0xFF6E9AD0),
          onSecondary: Color(0xFF0C1A2E),
          secondaryContainer: Color(0xFF1A2E4A),
          onSecondaryContainer: Color(0xFFA8C8E8),
          tertiary: Color(0xFFA0C0E8),
          onTertiary: Color(0xFF0E1E32),
          tertiaryContainer: Color(0xFF1E3450),
          onTertiaryContainer: Color(0xFFC0D8F4),
          error: Color(0xFFCF6679),
          onError: Color(0xFF1E1214),
          errorContainer: Color(0xFF442C30),
          onErrorContainer: Color(0xFFE8B4BC),
          surface: Color(0xFF0E1420),
          onSurface: Color(0xFFD0D8E8),
          surfaceContainerHighest: Color(0xFF1E2838),
          outline: Color(0xFF3E5070),
          outlineVariant: Color(0xFF243448),
          surfaceContainer: Color(0xFF141C2C),
        ),
      );

  // ── Sky Blue ── light airy blue
  static ThemeData get skyBlueTheme => _build(
        const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF2196F3),
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFFD4EAFF),
          onPrimaryContainer: Color(0xFF001D36),
          secondary: Color(0xFF4BA3E0),
          onSecondary: Color(0xFFFFFFFF),
          secondaryContainer: Color(0xFFD8ECFF),
          onSecondaryContainer: Color(0xFF001E30),
          tertiary: Color(0xFF64B5F6),
          onTertiary: Color(0xFFFFFFFF),
          tertiaryContainer: Color(0xFFE0F0FF),
          onTertiaryContainer: Color(0xFF002040),
          error: Color(0xFFBA1A1A),
          onError: Color(0xFFFFFFFF),
          errorContainer: Color(0xFFFFDAD6),
          onErrorContainer: Color(0xFF410002),
          surface: Color(0xFFF4F9FF),
          onSurface: Color(0xFF1A2028),
          surfaceContainerHighest: Color(0xFFD8E6F4),
          outline: Color(0xFF7090B0),
          outlineVariant: Color(0xFFB8D0E4),
          surfaceContainer: Color(0xFFEAF2FC),
        ),
      );

  /// Get ThemeData for a given AppThemeMode
  static ThemeData getTheme(AppThemeMode mode, {required Brightness platformBrightness}) {
    switch (mode) {
      case AppThemeMode.light:
        return lightTheme;
      case AppThemeMode.dark:
        return darkTheme;
      case AppThemeMode.system:
        return platformBrightness == Brightness.dark ? darkTheme : lightTheme;
      case AppThemeMode.matte:
        return matteTheme;
      case AppThemeMode.panda:
        return pandaTheme;
      case AppThemeMode.rosePink:
        return rosePinkTheme;
      case AppThemeMode.forest:
        return forestTheme;
      case AppThemeMode.crimson:
        return crimsonTheme;
      case AppThemeMode.midnight:
        return midnightTheme;
      case AppThemeMode.skyBlue:
        return skyBlueTheme;
    }
  }

  /// Theme metadata for the picker UI
  static List<ThemePreviewData> get allThemes => [
        ThemePreviewData(
          mode: AppThemeMode.system,
          name: 'System',
          description: 'Follows your device',
          icon: Icons.settings_brightness,
          previewColors: [Color(0xFFF5F5F5), Color(0xFF1C1B1F), Color(0xFF6750A4)],
        ),
        ThemePreviewData(
          mode: AppThemeMode.light,
          name: 'Light',
          description: 'Clean & bright',
          icon: Icons.light_mode,
          previewColors: [Color(0xFFFFFBFE), Color(0xFF1C1B1F), Color(0xFF6750A4)],
        ),
        ThemePreviewData(
          mode: AppThemeMode.dark,
          name: 'Dark',
          description: 'Easy on the eyes',
          icon: Icons.dark_mode,
          previewColors: [Color(0xFF1C1B1F), Color(0xFFE6E1E5), Color(0xFFD0BCFF)],
        ),
        ThemePreviewData(
          mode: AppThemeMode.matte,
          name: 'Matte',
          description: 'Warm muted tones',
          icon: Icons.blur_on,
          previewColors: [Color(0xFF2A2622), Color(0xFFD8CCBE), Color(0xFFBFA98E)],
        ),
        ThemePreviewData(
          mode: AppThemeMode.panda,
          name: 'Panda 🐼',
          description: 'Black & white minimal',
          icon: Icons.contrast,
          previewColors: [Color(0xFF1A1A1A), Color(0xFFE8E8E8), Color(0xFFB0B0B0)],
        ),
        ThemePreviewData(
          mode: AppThemeMode.rosePink,
          name: 'Rose',
          description: 'Soft pink warmth',
          icon: Icons.local_florist,
          previewColors: [Color(0xFFFFF8F8), Color(0xFF2C1520), Color(0xFFBE4B6E)],
        ),
        ThemePreviewData(
          mode: AppThemeMode.forest,
          name: 'Forest',
          description: 'Deep earthy greens',
          icon: Icons.park,
          previewColors: [Color(0xFF121E12), Color(0xFFD0E8D0), Color(0xFF8FBF8F)],
        ),
        ThemePreviewData(
          mode: AppThemeMode.crimson,
          name: 'Crimson',
          description: 'Bold & dramatic',
          icon: Icons.whatshot,
          previewColors: [Color(0xFF1E1212), Color(0xFFE8D0D0), Color(0xFFFF6B6B)],
        ),
        ThemePreviewData(
          mode: AppThemeMode.midnight,
          name: 'Midnight',
          description: 'Deep navy blue',
          icon: Icons.nightlight_round,
          previewColors: [Color(0xFF0E1420), Color(0xFFD0D8E8), Color(0xFF8AB4F8)],
        ),
        ThemePreviewData(
          mode: AppThemeMode.skyBlue,
          name: 'Sky',
          description: 'Light airy blue',
          icon: Icons.cloud,
          previewColors: [Color(0xFFF4F9FF), Color(0xFF1A2028), Color(0xFF2196F3)],
        ),
      ];
}

/// Data class for theme preview cards
class ThemePreviewData {
  final AppThemeMode mode;
  final String name;
  final String description;
  final IconData icon;
  /// [background, text, accent]
  final List<Color> previewColors;

  const ThemePreviewData({
    required this.mode,
    required this.name,
    required this.description,
    required this.icon,
    required this.previewColors,
  });
}
