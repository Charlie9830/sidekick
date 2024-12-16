import 'package:collection/collection.dart';
import 'package:sidekick/model_collection/convert_to_model_map.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/utils/get_uid.dart';

typedef _CableCleaner = List<CableModel> Function(_CleanerParams params);

class _CleanerParams {
  final List<CableModel> cables;
  final Map<String, PowerMultiOutletModel> powerMultis;
  final Map<String, DataMultiModel> dataMultis;
  final Map<String, DataPatchModel> dataPatches;
  final CableType defaultPowerMultiType;

  _CleanerParams({
    required this.cables,
    required this.powerMultis,
    required this.dataMultis,
    required this.dataPatches,
    required this.defaultPowerMultiType,
  });

  _CleanerParams withUpdatedCables(List<CableModel> updatedCables) {
    return _CleanerParams(
      cables: updatedCables,
      powerMultis: powerMultis,
      dataMultis: dataMultis,
      dataPatches: dataPatches,
      defaultPowerMultiType: defaultPowerMultiType,
    );
  }
}

Map<String, CableModel> performCableCleanup({
  required Map<String, CableModel> cables,
  required Map<String, PowerMultiOutletModel> powerMultis,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, DataPatchModel> dataPatches,
  required CableType defaultPowerMultiType,
}) {
  final cleaners = <_CableCleaner>[
    // Remove any cables that have had their associated outlet deleted.
    _removeOrphanedCables,

    // Create any cables for outlets that don't have an existing cable assigned to them.
    _createNewCables,
  ];

  // Fold the result of each [_CableCleaner] function together to get the final clean list of cables.
  final result = cleaners.fold(
      _CleanerParams(
        cables: cables.values.toList(),
        dataMultis: dataMultis,
        powerMultis: powerMultis,
        dataPatches: dataPatches,
        defaultPowerMultiType: defaultPowerMultiType,
      ),
      (params, cleaner) => params.withUpdatedCables(cleaner(params)));

  return convertToModelMap(result.cables);
}

List<CableModel> _removeOrphanedCables(_CleanerParams params) {
  final allOutletIds = {
    ...params.powerMultis.keys,
    ...params.dataMultis.keys,
    ...params.dataPatches.keys,
  };

  return params.cables
      .where((cable) => cable.isSpare || allOutletIds.contains(cable.outletId))
      .toList();
}

List<CableModel> _createNewCables(_CleanerParams params) {
  final cablesByOutletId =
      params.cables.groupListsBy((cable) => cable.outletId);

  bool outletIdHasAssociatedCables(outletId) =>
      cablesByOutletId.containsKey(outletId);

  return [
    // Prepend existing cables as we are only creating new cables here.
    ...params.cables,

    //
    // Create new cables only if an outletId exists but has no cables associated to it.
    // If the [cablesByOutletId] map does not have a key that matches the outlet uid, then we can
    // assume that no cables are assigned to that outlet.
    //
    // Power Cables
    ...params.powerMultis.values
        .map((outlet) => outletIdHasAssociatedCables(outlet.uid)
            ? null
            : CableModel(
                uid: getUid(),
                type: params.defaultPowerMultiType,
                locationId: outlet.locationId,
                outletId: outlet.uid))
        .nonNulls,

    // Data Multis
    ...params.dataMultis.values
        .map((outlet) => outletIdHasAssociatedCables(outlet.uid)
            ? null
            : CableModel(
                uid: getUid(),
                type: CableType.sneak,
                locationId: outlet.locationId,
                outletId: outlet.uid,
              ))
        .nonNulls,

    // Data Patches
    ...params.dataPatches.values
        .map((outlet) => outletIdHasAssociatedCables(outlet.uid)
            ? null
            : CableModel(
                uid: getUid(),
                type: CableType.dmx,
                locationId: outlet.locationId,
                outletId: outlet.uid,
              ))
        .nonNulls,
  ];
}
