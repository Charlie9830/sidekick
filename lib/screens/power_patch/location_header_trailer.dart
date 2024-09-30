import 'package:flutter/material.dart';

class LocationHeaderTrailer extends StatelessWidget {
  final void Function(bool value) onLockChanged;
  final bool isLocked;

  const LocationHeaderTrailer({
    super.key,
    required this.multiCount,
    required this.onLockChanged,
    required this.isLocked,
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
        const Icon(Icons.electric_bolt, color: Colors.grey),
        const SizedBox(width: 8.0),
        Text(multiCount.toString(),
            style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}
