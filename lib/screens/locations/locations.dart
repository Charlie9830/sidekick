import 'package:flutter/material.dart';
import 'package:sidekick/screens/locations/location_tile.dart';
import 'package:sidekick/view_models/locations_view_model.dart';

class Locations extends StatelessWidget {
  final LocationsViewModel vm;
  const Locations({Key? key, required this.vm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locations = vm.locations.values.toList();
    return ListView.separated(
        itemBuilder: (context, index) {
          final location = locations[index];
          return LocationTile(location: location, onPrefixChanged: (newValue) => vm.onMultiPrefixChanged(location.uid, newValue));
        },
        separatorBuilder: (context, index) => const Divider(height: 0),
        itemCount: locations.length);
  }
}
