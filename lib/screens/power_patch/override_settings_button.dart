import 'package:flutter/material.dart';

class OverrideSettingsButton extends StatelessWidget {
  const OverrideSettingsButton({
    super.key,
    required this.hasOverrides,
    required this.onPressed,
  });

  final bool hasOverrides;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Badge(
      label: const Icon(Icons.check, color: Colors.black, size: 12),
      isLabelVisible: hasOverrides,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.settings,
        ),
        label: const Text('Settings'),
      ),
    );
  }
}
