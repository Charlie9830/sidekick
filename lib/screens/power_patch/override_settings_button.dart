import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/simple_tooltip.dart';

class OverrideSettingsButton extends StatelessWidget {
  const OverrideSettingsButton({
    super.key,
    required this.hasOverrides,
    required this.onPressed,
  });

  final bool hasOverrides;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return SimpleTooltip(
      message: hasOverrides
          ? 'Global settings have been overridden for this location'
          : null,
      child: OutlineBadge(
          style: const ButtonStyle.outline(),
          trailing: hasOverrides
              ? const Icon(Icons.check_circle, color: Colors.teal)
              : null,
          onPressed: onPressed,
          child: const Text('Settings')),
    );
  }
}
