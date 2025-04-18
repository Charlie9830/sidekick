import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';

Set<LocationModel> extractLocationsFromOutlets(
    List<Outlet> outlets, Map<String, LocationModel> existingLocations) {
  final locationIds = outlets.map((outlet) => outlet.locationId).toSet();

  return locationIds.map((id) => existingLocations[id]).nonNulls.toSet();
}
