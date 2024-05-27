import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/location_model.dart';

class LocationHeaderRow extends StatelessWidget {
  final LocationModel location;
  final Widget trailing;

  const LocationHeaderRow(
      {Key? key,
      required this.location,
      this.trailing = const SizedBox(width: 0)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 24.0, left: 8.0, top: 24, right: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(location.name, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}
