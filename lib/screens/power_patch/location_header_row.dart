import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/location_model.dart';

class LocationHeaderRow extends StatelessWidget {
  final LocationModel location;
  final int multiCount;
  const LocationHeaderRow(
      {Key? key, required this.location, required this.multiCount})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 16.0, left: 8.0, top: 16, right: 24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(location.name,
                  style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              const Icon(Icons.electric_bolt, color: Colors.grey),
              const SizedBox(width: 8.0),
              Text(multiCount.toString(), style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ],
      ),
    );
  }
}
