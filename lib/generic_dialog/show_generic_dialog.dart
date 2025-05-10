import 'package:flutter/material.dart';

Future<bool?> showGenericDialog(
    {required BuildContext context,
    required String title,
    required String message,
    required String affirmativeText,
    bool scrollable = false,
    String? declineText}) async {
  if (declineText != null && declineText.trim().isEmpty) {
    assert(false,
        '[declineText] must not be an empty String, it must also contain non white-space characters.');
  }

  return await showDialog<bool>(
      context: context,
      builder: (innerContext) {
        return AlertDialog(
          scrollable: scrollable,
          title: Text(title),
          content: Text(message),
          actions: [
            if (declineText != null)
              TextButton(
                child: Text(declineText),
                onPressed: () => Navigator.of(innerContext).pop(false),
              ),
            TextButton(
              child: Text(affirmativeText),
              onPressed: () => Navigator.of(innerContext).pop(true),
            ),
          ],
        );
      });
}
