import 'package:flutter/material.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

class LocationHeaderTrailer extends StatelessWidget {
  final PropertyDeltaSet? deltas;
  final void Function() onLocationSettingsButtonPressed;

  const LocationHeaderTrailer({
    super.key,
    required this.multiCount,
    required this.onLocationSettingsButtonPressed,
    this.deltas,
  });

  final int multiCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FilledButton.tonalIcon(
          onPressed: onLocationSettingsButtonPressed,
          icon: const Icon(Icons.settings),
          label: const Text('Settings'),
        ),
        const SizedBox(width: 24),
        DiffStateOverlay(
          diff: deltas?.lookup(PropertyDeltaName.multiCount),
          child: Row(
            children: [
              const Icon(Icons.electric_bolt, color: Colors.grey),
              const SizedBox(width: 8.0),
              Text(multiCount.toString(),
                  style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ],
    );
  }
}
