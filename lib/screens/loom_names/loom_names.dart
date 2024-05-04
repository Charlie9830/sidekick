import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/screens/loom_names/location_tile.dart';
import 'package:sidekick/view_models/loom_names_view_model.dart';

class LoomNames extends StatelessWidget {
  final LoomNamesViewModel vm;
  const LoomNames({Key? key, required this.vm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final multiOutletsByLocation = _consolidateLocations(vm.outlets);

    return ListView(
        children: vm.locations.entries.map((entry) {
      final location = entry.value;
      final powerMultiCount =
          multiOutletsByLocation[location.name]?.length ?? 0;

      return LocationTile(
        location: location,
        powerMultiCount: powerMultiCount,
        onPrefixChanged: (newValue) =>
            vm.onMultiPrefixChanged(location.name, newValue),
        onCommitPowerPressed: () => vm.onCommitPowerPressed(location),
      );
    }).toList());
  }

  Map<String, List<int>> _consolidateLocations(List<PowerOutletModel> outlets) {
    final outletsByMulti = outlets.groupListsBy((outlet) => outlet.multiOutlet);

    final result = <String, List<int>>{};

    outletsByMulti.forEach((location, childOutlets) {
      final consolidatedLocationNames = _consolidateLocationNames(childOutlets);

      result[consolidatedLocationNames] = {
        if (result.containsKey(consolidatedLocationNames))
          ...result[consolidatedLocationNames]!,
        ...childOutlets.map((outlet) => outlet.multiOutlet),
      }.toList();
    });

    return result;
  }

  String _consolidateLocationNames(List<PowerOutletModel> outlets) {
    final locationNames = outlets
        .map((outlet) => outlet.getAssociatedLocations())
        .where((location) => location.trim().isNotEmpty)
        .toSet();

    if (locationNames.length == 1) {
      return locationNames.first;
    }

    return locationNames.join(", ");
  }
}
