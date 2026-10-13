import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../errors/app_failure.dart';

/// Shows a failure as a floating snackbar. Messages are already user-facing.
void showFailure(BuildContext context, AppFailure failure) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(failure.message)));
}

/// Asks before a destructive action. Resolves to true only on confirmation.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showAdaptiveDialog<bool>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(message),
      actions: [
        adaptiveAction(
          context: context,
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        adaptiveAction(
          context: context,
          destructive: true,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Widget adaptiveAction({
  required BuildContext context,
  required VoidCallback onPressed,
  required Widget child,
  bool destructive = false,
}) {
  final theme = Theme.of(context);
  return switch (theme.platform) {
    TargetPlatform.iOS || TargetPlatform.macOS => CupertinoDialogAction(
      onPressed: onPressed,
      isDestructiveAction: destructive,
      child: child,
    ),
    _ => TextButton(
      onPressed: onPressed,
      style: destructive
          ? TextButton.styleFrom(foregroundColor: theme.colorScheme.error)
          : null,
      child: child,
    ),
  };
}
