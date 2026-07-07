import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/redux/models/location_model.dart';

class RemoveLocation {
  final LocationModel location;

  RemoveLocation({required this.location});
}

class SetLocations {
  final Map<String, LocationModel> locations;
  SetLocations(this.locations);
}

class UpdateLocationDelimiter {
  final String locationId;
  final String newValue;

  UpdateLocationDelimiter(this.locationId, this.newValue);
}

class UpdateLocationColor {
  final String locationId;
  final LabelColorModel newValue;

  UpdateLocationColor(this.locationId, this.newValue);
}
