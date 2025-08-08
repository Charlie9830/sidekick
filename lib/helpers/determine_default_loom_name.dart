import 'package:collection/collection.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/outlet.dart';

String determineDefaultLoomName({
  required LocationModel associatedPrimaryLocation,
  required List<CableModel> children,
  required Map<String, LoomModel> existingLooms,
  required Map<String, Outlet> existingOutlets,
  required Map<String, CableModel> existingCables,
}) {
  final locationSlug = associatedPrimaryLocation.name;
  final currentLoomCableClass = _determineCableClass(children);

  final otherLoomsInLocationByCableClass =
      _sortOtherLoomsInLocationByCableClass(
          locationId: associatedPrimaryLocation.uid,
          otherLooms: existingLooms,
          existingOutlets: existingOutlets,
          otherCables: existingCables);

  final hasOtherSimiliarLoomsInLocation =
      (otherLoomsInLocationByCableClass[currentLoomCableClass]?.length ?? 0) >
          0;

  final loomNumber =
      (otherLoomsInLocationByCableClass[currentLoomCableClass]?.length ?? 0) +
          1;

  final loomCableClassSlug = _convertCableClassToString(currentLoomCableClass);

  if (currentLoomCableClass == CableClass.none) {
    // Unable to determine name, Return Default.
    return 'Untitled Loom';
  }

  final motorSlug = children.every((cable) =>
          cable.type == CableType.hoist || cable.type == CableType.hoistMulti)
      ? ' Motor'
      : '';

  return '$locationSlug$motorSlug $loomCableClassSlug ${hasOtherSimiliarLoomsInLocation ? loomNumber : ''}'
      .trim();
}

String _convertCableClassToString(CableClass cableClass) {
  return switch (cableClass) {
    CableClass.feeder => 'Feeder',
    CableClass.extension => 'Extension',
    CableClass.dropper => 'Dropper',
    CableClass.none => '',
  };
}

Map<CableClass, List<LoomModel>> _sortOtherLoomsInLocationByCableClass(
    {required String locationId,
    required Map<String, LoomModel> otherLooms,
    required Map<String, CableModel> otherCables,
    required Map<String, Outlet> existingOutlets}) {
  final cablesWithOutlets = otherCables.values
      .map((cable) => existingOutlets[cable.outletId] != null
          ? (cable, existingOutlets[cable.outletId]!)
          : null)
      .nonNulls;

  final cablesWithOutletsInLocation =
      cablesWithOutlets.where((item) => item.$2.locationId == locationId);

  final loomsWithChildrenInLocation = cablesWithOutletsInLocation
      .groupListsBy((item) => item.$1.loomId)
      .map((loomId, tuples) => MapEntry(loomId,
          (otherLooms[loomId]!, tuples.map((tuple) => tuple.$1).toList())));

  final loomsInLocationByCableClass = loomsWithChildrenInLocation.values
      .groupListsBy((tuple) => _determineCableClass(tuple.$2));

  return loomsInLocationByCableClass.map((cableClass, tuples) =>
      MapEntry(cableClass, tuples.map((tuple) => tuple.$1).toList()));
}

CableClass _determineCableClass(List<CableModel> children) {
  final classSet = children.map((cable) => cable.cableClass).toSet();

  if (classSet.length == 1) {
    return classSet.first;
  }

  return CableClass.none;
}
