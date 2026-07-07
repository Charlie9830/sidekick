import 'package:collection/collection.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/hoist_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

Map<String, CableModel> assertCableState({
  required Map<String, CableModel> cables,
  required Map<String, PowerMultiOutletModel> powerMultiOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, DataPatchModel> dataPatches,
  required Map<String, HoistModel> hoistOutlets,
  required Map<String, HoistMultiModel> hoistMultis,
}) {
  final cablesByOutletId = cables.values.groupListsBy((item) => item.outletId);

  final powerMultisByLocationId = powerMultiOutlets.values.groupListsBy(
    (element) => element.locationId,
  );
  final dataMultisByLocationId = dataMultis.values.groupListsBy(
    (element) => element.locationId,
  );
  final dataPatchesByLocationId = dataPatches.values.groupListsBy(
    (element) => element.locationId,
  );
  final hoistOutletsByLocationId = hoistOutlets.values.groupListsBy(
    (element) => element.locationId,
  );
  final hoistMultisByLocationId = hoistMultis.values.groupListsBy(
    (element) => element.locationId,
  );

  final orderedOutletIds = [
    ...powerMultisByLocationId.values
        .map((outletsInLocation) => outletsInLocation.sorted())
        .flattened
        .map((item) => item.uid),
    ...dataMultisByLocationId.values
        .map((outletsInLocation) => outletsInLocation.sorted())
        .flattened
        .map((item) => item.uid),
    ...dataPatchesByLocationId.values
        .map((outletsInLocation) => outletsInLocation.sorted())
        .flattened
        .map((item) => item.uid),
    ...hoistMultisByLocationId.values
        .map((outletsInLocation) => outletsInLocation.sorted())
        .flattened
        .map((item) => item.uid),
    ...hoistOutletsByLocationId.values
        .map((outletsInLocation) => outletsInLocation.sorted())
        .flattened
        .map((item) => item.uid),

    '', // Spare cables will have an empty outletId field. Therefore we need to include an empty string here, otherwise
    // the spares will get inadvertantly filltered out.
  ];

  final orderedCables = orderedOutletIds
      .map((outletId) => cablesByOutletId[outletId] ?? [])
      .flattened;

  return orderedCables.toModelMap();
}
