import 'package:collection/collection.dart';
import 'package:sidekick/excel/new/raw_row_data.dart';
import 'package:sidekick/excel/patch_data_item_error.dart';
import 'package:sidekick/redux/models/location_model.dart';

List<RawRowData> attachLocations(
    List<RawRowData> rawRows, Map<String, LocationModel> locations) {
  final locationsByName =
      locations.values.groupListsBy((element) => element.name);

  return rawRows.map((row) {
    if (locationsByName.containsKey(row.location)) {
      return row.copyWith(
          attachedLocationId: locationsByName[row.location]!.first.uid);
    } else {
      return row.copyWithError(NoMatchingLocationError(row.location));
    }
  }).toList();
}
