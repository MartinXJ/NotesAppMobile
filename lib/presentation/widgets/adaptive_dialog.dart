import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/utils/platform_utils.dart';

/// Platform-aware dialog
class AdaptiveDialog {
  /// Show an alert dialog
  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
  }) async {
    if (PlatformUtils.isIOS) {
      return showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(confirmText ?? 'OK'),
            ),
          ],
        ),
      );
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(confirmText ?? 'OK'),
          ),
        ],
      ),
    );
  }

  /// Show a confirmation dialog
  static Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
  }) async {
    if (PlatformUtils.isIOS) {
      return await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelText ?? 'Cancel'),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmText ?? 'Confirm'),
                ),
              ],
            ),
          ) ??
          false;
    }

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmText ?? 'Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
