import 'package:flutter/material.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

class LocationHeaderTrailer extends StatelessWidget {
  final PropertyDeltaSet? deltas;

  const LocationHeaderTrailer({
    super.key,
    required this.multiCount,
    this.deltas,
  });

  final int multiCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
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
