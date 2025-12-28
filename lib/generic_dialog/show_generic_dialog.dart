import 'package:shadcn_flutter/shadcn_flutter.dart';

Future<bool?> showGenericDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String affirmativeText,
  bool scrollable = false,
  String? declineText,
  bool destructiveDecline = false,
  bool destructiveAffirmative = false,
}) async {
  if (declineText != null && declineText.trim().isEmpty) {
    assert(false,
        '[declineText] must not be an empty String, it must also contain non white-space characters.');
  }

  Widget wrapScrollView(Widget child) =>
      scrollable ? SingleChildScrollView(child: child) : child;

  return await showDialog<bool>(
      context: context,
      builder: (innerContext) {
        return AlertDialog(
          title: Text(title),
          content: wrapScrollView(Text(message)),
          actions: [
            if (declineText != null)
              Button(
                style: destructiveDecline
                    ? const ButtonStyle.destructive()
                    : const ButtonStyle.text(),
                child: Text(declineText),
                onPressed: () => Navigator.of(innerContext).pop(false),
              ),
            Button(
              style: destructiveAffirmative
                  ? const ButtonStyle.destructive()
                  : const ButtonStyle.text(),
              child: Text(affirmativeText),
              onPressed: () => Navigator.of(innerContext).pop(true),
            ),
          ],
        );
      });
}
