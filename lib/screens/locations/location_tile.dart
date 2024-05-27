import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/screens/locations/color_chit.dart';
import 'package:sidekick/widgets/property_field.dart';

class LocationTile extends StatelessWidget {
  final LocationModel location;
  final int powerMultiCount;
  final int dataMultiCount;
  final int dataPatchCount;
  final void Function(String newValue) onPrefixChanged;

  const LocationTile({
    Key? key,
    required this.location,
    required this.onPrefixChanged,
    this.powerMultiCount = 0,
    this.dataMultiCount = 0,
    this.dataPatchCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ColorChit(
                color: location.color,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(location.name,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(width: 32),
              SizedBox(
                width: 120,
                child: PropertyField(
                  label: 'Loom Prefix',
                  value: location.multiPrefix,
                  onBlur: onPrefixChanged,
                ),
              ),
            ],
          )
        ],
      ),
    ));
  }
}
