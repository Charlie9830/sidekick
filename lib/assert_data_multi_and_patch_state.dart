import 'package:collection/collection.dart';
import 'package:sidekick/assert_outlet_name_and_number.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/location_model.dart';

Map<String, DataMultiModel> assertDataMultiState(
    Map<String, DataMultiModel> multiOutlets,
    Map<String, LocationModel> locations) {
  final outletsByLocationId =
      multiOutlets.values.groupListsBy((item) => item.locationId);

  final sortedOutlets = locations.values
      .map((location) => (outletsByLocationId[location.uid] ?? [])
          .sorted((a, b) => b.number - a.number))
      .flattened;

  return assertOutletNameAndNumbers<DataMultiModel>(sortedOutlets, locations)
      .toModelMap();
}

Map<String, DataPatchModel> assertDataPatchState(
    Map<String, DataPatchModel> dataPatches,
    Map<String, LocationModel> locations) {
  final patchesByLocationId =
      dataPatches.values.groupListsBy((item) => item.locationId);

  final sortedPatches = locations.values
      .map((location) => (patchesByLocationId[location.uid] ?? []).sorted())
      .flattened;

  return assertOutletNameAndNumbers<DataPatchModel>(sortedPatches, locations)
      .toModelMap();
}
