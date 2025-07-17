import 'package:flutter/material.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/screens/power_patch/override_settings_button.dart';

class LocationHeaderTrailer extends StatelessWidget {
  final PropertyDeltaSet? deltas;
  final void Function() onLocationSettingsButtonPressed;
  final bool hasOverrides;

  const LocationHeaderTrailer({
    super.key,
    required this.multiCount,
    required this.onLocationSettingsButtonPressed,
    this.hasOverrides = false,
    this.deltas,
  });

  final int multiCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OverrideSettingsButton(
          hasOverrides: hasOverrides,
          onLocationSettingsButtonPressed: onLocationSettingsButtonPressed,
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
