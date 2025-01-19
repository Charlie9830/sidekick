import 'package:flutter/material.dart';

class FullScreenDialogHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final void Function() onClosed;
  const FullScreenDialogHeader({
    super.key,
    this.title = '',
    this.trailing,
    required this.onClosed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (trailing != null) trailing!,
              const SizedBox(width: 16),
              IconButton(onPressed: onClosed, icon: const Icon(Icons.close)),
            ],
          ),
        ],
      ),
    );
  }
}
