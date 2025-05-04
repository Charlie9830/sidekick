import 'package:flutter/material.dart';
import 'package:sidekick/snack_bars/generic_error_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;

class FileSelectButton extends StatelessWidget {
  final void Function()? onFileSelectPressed;
  final bool showOpenButton;
  final String path;
  const FileSelectButton({
    super.key,
    required this.path,
    this.onFileSelectPressed,
    this.showOpenButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onFileSelectPressed != null)
          TextButton(
            onPressed: onFileSelectPressed,
            child: Text(path.isEmpty ? 'Select' : 'Change'),
          ),
        if (showOpenButton == true && path.isNotEmpty)
          IconButton(
            onPressed: () => _handleOpenButtonPressed(context),
            icon: const Icon(Icons.open_in_new),
          ),
        const SizedBox(width: 16),
        Text(path, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  void _handleOpenButtonPressed(BuildContext context) async {
    try {
      final result =
          await launchUrl(Uri.file(path), mode: LaunchMode.externalApplication);

      if (result == false && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
            context: context,
            message: 'Unable to open file ${p.basename(path)}'));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
            context: context,
            message: "Unable to open file ${p.basename(path)}",
            extendedMessage: e.toString()));
      }
    }
  }
}
