import 'package:desktop_drop/desktop_drop.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/toasts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;

class FileSelectButton extends StatefulWidget {
  final void Function()? onFileSelectPressed;
  final void Function(String path)? onFileDropped;
  final bool showOpenButton;
  final String path;
  final String? hintText;
  final String? dropTargetName;

  const FileSelectButton({
    super.key,
    required this.path,
    this.onFileSelectPressed,
    this.showOpenButton = false,
    this.hintText,
    this.dropTargetName,
    this.onFileDropped,
  });

  @override
  State<FileSelectButton> createState() => _FileSelectButtonState();
}

class _FileSelectButtonState extends State<FileSelectButton> {
  bool _dropHovering = false;

  @override
  Widget build(BuildContext context) {
    return _wrapDropTarget(
        name: widget.dropTargetName,
        child: Row(
          children: [
            if (widget.onFileSelectPressed != null)
              TextButton(
                onPressed: widget.onFileSelectPressed,
                child: Text(widget.path.isEmpty ? 'Select' : 'Change'),
              ),
            if (widget.showOpenButton == true && widget.path.isNotEmpty)
              IconButton.ghost(
                onPressed: () => _handleOpenButtonPressed(context),
                icon: const Icon(Icons.open_in_new),
              ),
            const SizedBox(width: 16),
            if (widget.path.isNotEmpty)
              Text(widget.path, style: Theme.of(context).typography.xSmall),
            if (widget.path.isEmpty && widget.hintText != null)
              Text(widget.hintText!,
                  style: Theme.of(context)
                      .typography
                      .xSmall
                      .copyWith(color: Theme.of(context).colorScheme.muted))
          ],
        ));
  }

  Widget _wrapDropTarget({required String? name, required Widget child}) {
    if (name == null) {
      return child;
    }

    return DropTarget(
      onDragEntered: (details) => setState(() => _dropHovering = true),
      onDragExited: (details) => setState(() => _dropHovering = false),
      onDragDone: (details) {
        setState(() => _dropHovering = false);

        widget.onFileDropped?.call(details.files.first.path);
      },
      child: _dropHovering ? _Hovering(hoveringName: name) : child,
    );
  }

  void _handleOpenButtonPressed(BuildContext context) async {
    try {
      final result = await launchUrl(Uri.file(widget.path),
          mode: LaunchMode.externalApplication);

      if (result == false && context.mounted) {
        showGenericErrorToast(
          context: context,
          title: "Unable to open file",
          subtitle: p.basename(widget.path),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showGenericErrorToast(
          context: context,
          title: "Unable to open file",
          subtitle: p.basename(widget.path),
          extendedMessage: e.toString(),
        );
      }
    }
  }
}

class _Hovering extends StatelessWidget {
  final String hoveringName;
  const _Hovering({
    required this.hoveringName,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 16,
        children: [
          const SizedBox(width: 8),
          Icon(Icons.file_download,
              color: Theme.of(context).colorScheme.primary),
          Text(hoveringName,
              style: Theme.of(context)
                  .typography
                  .large
                  .copyWith(color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }
}
