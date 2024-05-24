import 'package:flutter/material.dart';

class LocationHeaderTrailer extends StatelessWidget {
  const LocationHeaderTrailer({
    super.key,
    required this.multiCount,
  });

  final int multiCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.electric_bolt, color: Colors.grey),
        const SizedBox(width: 8.0),
        Text(multiCount.toString(),
            style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}
