import 'dart:io';

/// Utility class for platform detection
class PlatformUtils {
  // Private constructor to prevent instantiation
  PlatformUtils._();

  /// Check if the current platform is iOS
  static bool get isIOS => Platform.isIOS;

  /// Check if the current platform is Android
  static bool get isAndroid => Platform.isAndroid;

  /// Check if the current platform is mobile (iOS or Android)
  static bool get isMobile => isIOS || isAndroid;
}
