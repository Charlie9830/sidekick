import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:sidekick/extension_methods/queue_pop.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_rack_model.dart';
import 'package:sidekick/redux/models/power_rack_template_model.dart';
import 'package:sidekick/redux/models/power_system_model.dart';
import 'package:sidekick/utils/get_uid.dart';

Map<String, PowerRackModel> performPowerRackPatch({
  required Map<String, PowerRackModel> existingRacks,
  required Map<String, PowerMultiOutletModel> powerMultis,
  required Map<String, PowerSystemModel> powerSystems,
  required Map<String, LocationModel> locations,
}) {
  final racks = existingRacks.values.toList();

  // If No racks have yet been created, initialize default racks.
  if (racks.isEmpty) {
    racks.addAll(_generateDefaultRacks(powerMultis));

    return racks.toModelMap();
  }

  final existingClearedRacks =
      racks.map((rack) => rack.withClearedOutlets()).toList();

  // Group the PowerMultiOutlets by their assigned Power System Id.
  final multisBySystem = powerMultis.values.groupListsBy((multi) {
    final powerSystemId = _lookupPowerSystemId(multi, locations);
    if (powerSystemId == null) {
      throw 'PowerSystemId returned null. Unable to continue with Rack Patch';
    }

    return powerSystemId;
  });

  final existingRacksBySystemId =
      existingClearedRacks.groupListsBy((rack) => rack.parentSystemId);

  List<PowerRackModel> updatedRacks = [];

  for (final entry in multisBySystem.entries) {
    final systemId = entry.key;
    final Queue<PowerMultiOutletModel> multisQueue = Queue.from(entry.value);
    final Queue<PowerRackModel> existingRacksInSystemQueue =
        Queue.from(existingRacksBySystemId[systemId]!);

    while (multisQueue.isNotEmpty) {
      final currentRack = existingRacksInSystemQueue.isNotEmpty
          ? existingRacksInSystemQueue.removeFirst()
          : _createDefaultRack();

      final updatedRack = currentRack.withOutlets(
        multisQueue
            .pop(currentRack.outletSlots.qty - currentRack.desiredSpareOutlets)
            .map((multi) => multi.uid)
            .toList(),
      );

      updatedRacks.add(updatedRack);
    }

    // Add any now Empty Racks.
    updatedRacks.addAll(existingRacksInSystemQueue);
  }

  return updatedRacks.toModelMap();
}

String? _lookupPowerSystemId(
    PowerMultiOutletModel multi, Map<String, LocationModel> locations) {
  return locations[multi.locationId]?.powerSystemId;
}

List<PowerRackModel> _generateDefaultRacks(
    Map<String, PowerMultiOutletModel> powerMultis) {
  final powerMultiSlices =
      powerMultis.values.slices(16); // 1x PRG 96way accepts 16 Multi outlets.

  return powerMultiSlices.mapIndexed((index, slice) {
    return _createDefaultRack()
      ..copyWith(
          name: '96way ${index + 1}',
          outletSlots: OutletCollection.fromIds(
              qty: 16, outletIds: slice.map((outlet) => outlet.uid).toList()));
  }).toList();
}

PowerRackModel _createDefaultRack() {
  return PowerRackModel.fromTemplate(
          PowerRackTemplateModel(uid: getUid(), name: '96way', ways: 96))
      .copyWith(
    parentSystemId: const PowerSystemModel.defaultSystem().uid,
  );
}
