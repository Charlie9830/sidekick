import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/show_dialog.dart';

/// The action the user chose when prompted about unsaved changes.
enum CloseRequestResult { save, discard, cancel }

/// Asks whether to save, discard or keep the current project before closing.
///
/// Returns `null` if the dialog is dismissed by the barrier or Escape, which
/// callers should treat the same as [CloseRequestResult.cancel].
Future<CloseRequestResult?> showSaveBeforeClosingDialog({
  required BuildContext context,
}) {
  return showDialog<CloseRequestResult>(
    context: context,
    builder: (innerContext) => AlertDialog(
      title: const Text('Unsaved Changes'),
      content: const Text(
        'Would you like to save the changes to your project before closing?',
      ),
      actions: [
        Button(
          style: const ButtonStyle.text(),
          onPressed: () =>
              Navigator.of(innerContext).pop(CloseRequestResult.cancel),
          child: const Text('Cancel'),
        ),
        Button(
          style: const ButtonStyle.destructive(),
          onPressed: () =>
              Navigator.of(innerContext).pop(CloseRequestResult.discard),
          child: const Text('Discard'),
        ),
        Button(
          style: const ButtonStyle.primary(),
          onPressed: () =>
              Navigator.of(innerContext).pop(CloseRequestResult.save),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
