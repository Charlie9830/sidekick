import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';

class DataPatchListItem extends StatelessWidget {
  final DataPatchModel patch;
  const DataPatchListItem({
    required this.patch,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Icon(Icons.trending_flat,
            color: patch.isSpare ? Colors.pinkAccent : Colors.grey),
        const SizedBox(width: 8),
        Text(
          patch.name,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (patch.isSpare == false) ...[
          const SizedBox(width: 64),
          const Icon(Icons.lightbulb, color: Colors.grey, size: 20),
          Text(patch.fixtureIds.length.toString()),
          const SizedBox(width: 64),
          Text('#${patch.startsAtFixtureId}'),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_right,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Text('#${patch.endsAtFixtureId}'),
        ],
      ],
    );
  }
}