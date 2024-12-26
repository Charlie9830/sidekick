import 'package:flutter/material.dart';
import 'package:sidekick/generic_dialog/show_generic_dialog.dart';

SnackBar genericErrorSnackBar(
    {required BuildContext context,
    required String message,
    String extendedMessage = ''}) {
  return SnackBar(
    backgroundColor: Colors.red.shade900,
    action: extendedMessage.isNotEmpty
        ? SnackBarAction(
            label: 'Show more',
            onPressed: () => showGenericDialog(
                context: context,
                title: 'Details',
                message: extendedMessage,
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
