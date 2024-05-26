import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/widgets/property_field.dart';

class LocationTile extends StatelessWidget {
  final LocationModel location;
  final void Function(String newValue) onPrefixChanged;

  const LocationTile({
    Key? key,
    required this.location,
    required this.onPrefixChanged,
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
              Expanded(
                child: Text(location.name,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              SizedBox(
                width: 120,
                child: PropertyField(
                  label: 'Loom Prefix',
                  value: location.multiPrefix,
                  onBlur: onPrefixChanged,
                ),
              ),
              const SizedBox(width: 24),
              _ColorChit(
                color: location.color,
              ),
            ],
          ),
        ],
      ),
    ));
  }
}

class _ColorChit extends StatelessWidget {
  final Color? color;
  const _ColorChit({
    Key? key,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
