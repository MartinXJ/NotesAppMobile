import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/utils/platform_utils.dart';

/// Platform-aware button widget
class AdaptiveButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;

  const AdaptiveButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoButton(
        color: isPrimary ? CupertinoColors.activeBlue : null,
        onPressed: onPressed,
        child: Text(text),
      );
    }

    return isPrimary
        ? ElevatedButton(
            onPressed: onPressed,
            child: Text(text),
          )
        : TextButton(
            onPressed: onPressed,
            child: Text(text),
          );
  }
}
