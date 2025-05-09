import 'package:flutter/material.dart';
import 'package:sidekick/generic_dialog/show_generic_dialog.dart';

SnackBar genericErrorSnackBar({
  required BuildContext context,
  required String message,
  String extendedMessage = '',
  Object? error,
}) {
  return SnackBar(
    duration: const Duration(seconds: 8),
    backgroundColor: Theme.of(context).colorScheme.errorContainer,
    action: extendedMessage.isNotEmpty || error != null
        ? SnackBarAction(
            textColor: Theme.of(context).colorScheme.onErrorContainer,
            label: 'Show more',
            onPressed: () => showGenericDialog(
                context: context,
                scrollable: true,
                title: 'Details',
                message: '$extendedMessage\n${_parseError(error)}',
                affirmativeText: 'Okay'),
          )
        : null,
    content: Row(
      children: [
        const Icon(Icons.sentiment_dissatisfied, color: Colors.white),
        const SizedBox(width: 8),
        Text(message,
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: Colors.white)),
      ],
    ),
  );
}

String _parseError(Object? error) {
  if (error == null) {
    return '';
  }

  if (error is Error) {
    return '${error.toString()}\nStacktrace\n${error.stackTrace}';
  }

  return 'Error Type: ${error.runtimeType}';
}
