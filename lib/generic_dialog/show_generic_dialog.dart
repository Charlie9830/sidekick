import 'package:flutter/material.dart';

Future<bool?> showGenericDialog(
    {required BuildContext context,
    required String title,
    required String message,
    required String affirmativeText,
    String? declineText}) async {
  assert(declineText != null && declineText.trim().isEmpty,
      "[declineText] must not be an empty String, it must also contain non white-space characters");

  return await showDialog<bool>(
      context: context,
      builder: (innerContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: Text(affirmativeText),
              onPressed: () => Navigator.of(innerContext).pop(true),
            ),
            if (declineText != null)
              TextButton(
                child: Text(declineText),
                onPressed: () => Navigator.of(innerContext).pop(false),
              )
          ],
        );
      });
}
