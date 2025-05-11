import 'package:flutter/material.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

class LocationHeaderTrailer extends StatelessWidget {
  final void Function(bool value) onLockChanged;
  final bool isLocked;
  final PropertyDeltaSet? deltas;

  const LocationHeaderTrailer({
    super.key,
    required this.multiCount,
    required this.onLockChanged,
    required this.isLocked,
    this.deltas,
  });

  final int multiCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: isLocked
              ? const Icon(Icons.lock, color: Colors.green)
              : const Icon(Icons.lock_open),
          onPressed: () => onLockChanged(!isLocked),
        ),
        const SizedBox(width: 8),
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
