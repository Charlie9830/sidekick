import 'package:sidekick/redux/models/location_model.dart';

String selectLocationLabel(
    {required Set<String> locationIds,
    required Map<String, LocationModel> locations}) {
  if (locationIds.isEmpty) {
    return '';
  }

  final relatedLocations =
      locationIds.map((id) => locations[id]).nonNulls.toList();

  return relatedLocations.map((location) => location.name).join(' / ');
}
