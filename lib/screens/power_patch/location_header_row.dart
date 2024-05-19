import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/location_model.dart';

class LocationHeaderRow extends StatelessWidget {
  final LocationModel location;
  const LocationHeaderRow({Key? key, required this.location}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 8.0, top: 16, right: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.grey,),
              const SizedBox(width: 8),
              Text(location.name,
                  style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ],
      ),
    );
  }
}
