import 'package:shadcn_flutter/shadcn_flutter.dart';

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
    final button = OutlineButton(
      onPressed: onPressed,
      leading: const Icon(
        Icons.settings,
      ),
      child: const Text('Settings'),
    );

    if (hasOverrides == false) {
      return button;
    }

    return SecondaryBadge(
        trailing: const Icon(Icons.check, color: Colors.black, size: 12),
        child: button);
  }
}
