import 'package:flutter/material.dart';

import '../core/errors.dart';

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Runs a service call and reports the outcome in plain language. Returns true
/// on success. Field errors are returned through [onFieldErrors] when given.
Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
  void Function(Map<String, String> errors)? onFieldErrors,
}) async {
  try {
    await action();
    if (success != null && context.mounted) showMessage(context, success);
    return true;
  } on ValidationException catch (e) {
    if (onFieldErrors != null) {
      onFieldErrors(e.fieldErrors);
    } else if (context.mounted) {
      showMessage(context, e.fieldErrors.values.first);
    }
  } on AppException catch (e) {
    if (context.mounted) showMessage(context, e.message);
  }
  return false;
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Asks for one line of text, e.g. a rejection reason (FR-BOR-04).
Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String label,
  required String action,
  String initial = '',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 1,
        maxLines: 4,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(action)),
      ],
    ),
  );
}
