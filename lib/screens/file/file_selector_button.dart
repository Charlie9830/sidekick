import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class FileSelectorButton extends StatelessWidget {
  final String path;
  final void Function() onPressed;

  const FileSelectorButton({
    super.key,
    required this.path,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        switch (path) {
          "" => const Text('No file selected'),
          String s =>
            Tooltip(message: p.canonicalize(s), child: Text(p.basename(s))),
        },
        const SizedBox(
          height: 16,
        ),
        OutlinedButton(
          onPressed: onPressed,
          child: const Text('Choose'),
        ),
      ],
    );
  }
}
