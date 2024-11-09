import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';

String selectLoomName(List<LoomModel> loomsInLocation, LocationModel location,
    LoomModel current, List<LocationModel> secondaryLocations) {
  final locationLeader = secondaryLocations.isEmpty
      ? location.name
      : [location.name, ...secondaryLocations.map((item) => item.name)]
          .join(', ');

  final currentLoomIndex = loomsInLocation.indexOf(current);

  if (currentLoomIndex == -1) {
    return 'Unknown';
  }

  final preceedingLooms = loomsInLocation.getRange(0, currentLoomIndex);

  // Determine Type.
  final String type;
  final String preceedingNumber;
  if (current.isDrop) {
    type = 'Drop';
  } else {
    type = switch (current.loomClass) {
      LoomClass.feeder => 'Feeder',
      LoomClass.extension => 'Extension'
    };
  }

  // Determine Current Feeder Count.
  final preceedingCount = current.isDrop
      ? preceedingLooms.where((loom) => loom.isDrop == true).length
      : preceedingLooms
          .where((loom) => loom.loomClass == current.loomClass)
          .length;
  preceedingNumber = preceedingCount == 0 ? '' : '${preceedingCount + 1}';

  return '$locationLeader $type $preceedingNumber';
}
