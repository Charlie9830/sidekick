import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/location_model.dart';

LocationModel? selectCableSpecificLocation(
    CableModel cable, Map<String, LocationModel> locations) {
  return locations[cable.locationId];
}
