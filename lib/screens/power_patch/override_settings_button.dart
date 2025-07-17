import 'package:flutter/material.dart';

class OverrideSettingsButton extends StatelessWidget {
  const OverrideSettingsButton({
    super.key,
    required this.hasOverrides,
    required this.onLocationSettingsButtonPressed,
  });

  final bool hasOverrides;
  final void Function() onLocationSettingsButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Badge(
      label: const Icon(Icons.check, color: Colors.black, size: 12),
      isLabelVisible: hasOverrides,
      child: FilledButton.tonalIcon(
        onPressed: onLocationSettingsButtonPressed,
        icon: const Icon(
          Icons.settings,
        ),
        label: const Text('Settings'),
      ),
    );
  }
}
