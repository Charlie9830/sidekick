import 'package:collection/collection.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/utils/get_uid.dart';

/// [cables] Represents cables which have been modified by this operation, including new the Parent Sneak Cables.
/// [location] may be an untouched existing location, or a new location.
/// [newDataMultis] Represent the new Multi outlets that have been created to back the Sneaks.
class CombineDmxIntoSneakResult {
  final List<CableModel> cables;
  final LocationModel location;
  final List<DataMultiModel> newDataMultis;

  CombineDmxIntoSneakResult({
    required this.cables,
    required this.location,
    required this.newDataMultis,
  });
}

CombineDmxIntoSneakResult combineDmxIntoSneak(
  List<CableModel> cables,
  Map<String, Outlet> outlets,
  Map<String, LocationModel> existingLocations,
) {
  final validCables =
      cables.where((cable) => cable.type == CableType.dmx).toList();

  // Find the Outlets associated with these cables.
  final associatedOutlets =
      validCables.map((cable) => outlets[cable.outletId]).nonNulls.toList();

  // Group the cables by their Loom ID.
  final cablesByLoomId = validCables.groupListsBy((cable) => cable.loomId);

  // Determine the Target Location for cables, this could be an existing location, or a newly created hybrid location representing two or more locations.
  // Similiar in nature to an SQL Join table.
  final targetLocationModel = _resolveTargetLocation(
    associatedOutlets.map((outlet) => outlet.locationId).toSet(),
    existingLocations,
  );

  // Map through the Cables by Loom collection, returning a conjunction of the Sneak, its new outlet and the children to be assigned to it.
  final List<
          (CableModel sneak, DataMultiModel outlet, List<CableModel> children)>
      newSneaksWithOutletsAndChildren = cablesByLoomId.entries
          .map((entry) {
            final loomId = entry.key;
            final cablesInLoom = entry.value;
            final inheritedLength =
                cablesInLoom.isNotEmpty ? cablesInLoom.first.length : 0.0;

            final childSlices = cablesInLoom.slices(4);
            return childSlices.map((slice) {
              if (slice.every((child) => child.isSpare)) {
                throw 'Unable to combine into Sneak. Every child in this slice of at least 4 is a spare, meaning it does not have a parent outletId. Without that we cannot query for a locationId';
              }

              final newMultiOutlet = DataMultiModel(
                uid: getUid(),
                locationId: targetLocationModel.uid,
              );

              final newSneak = CableModel(
                uid: getUid(),
                type: CableType.sneak,
                length: inheritedLength,
                loomId: loomId,
                outletId: newMultiOutlet.uid,
              );

              final updatedChildren = slice
                  .map((child) => child.copyWith(parentMultiId: newSneak.uid))
                  .toList();

              final withSparesFilled = [
                ...updatedChildren,
                ...List<CableModel>.generate(
                    4 - updatedChildren.length,
                    (index) => CableModel(
                          uid: getUid(),
                          type: CableType.dmx,
                          isSpare: true,
                          spareIndex: index,
                          parentMultiId: newSneak.uid,
                          loomId: loomId,
                          length: inheritedLength,
                        ))
              ];

              return (newSneak, newMultiOutlet, withSparesFilled);
            });
          })
          .flattened
          .toList();

  // Destructure each Sneak, Outlet and children collections.
  final newSneaks = newSneaksWithOutletsAndChildren.map((item) => item.$1);
  final newMultiOutlets =
      newSneaksWithOutletsAndChildren.map((item) => item.$2);
  final updatedChildren =
      newSneaksWithOutletsAndChildren.map((item) => item.$3).flattened.toList();

  return CombineDmxIntoSneakResult(
      cables: [...newSneaks, ...updatedChildren],
      location: targetLocationModel,
      newDataMultis: newMultiOutlets.toList());
}

/// Will return the matching Location from [existingLocations], if one cannot be found a new one will be created.
LocationModel _resolveTargetLocation(
    Set<String> locationIds, Map<String, LocationModel> existingLocations) {
  if (locationIds.length == 1) {
    return existingLocations[locationIds.first]!;
  }

  // Check if we already have a matching Hybrid Location, otherwise create a new one.
  return existingLocations.values.firstWhere(
      (location) =>
          location.isHybrid && location.matchesHybridLocation(locationIds),
      orElse: () => LocationModel(
          uid: getUid(),
          color: LabelColorModel.combine(
            locationIds
                .map((id) => existingLocations[id]?.color)
                .nonNulls
                .toList(),
          ),
          hybridIds: locationIds,
          name: locationIds
              .map((id) => existingLocations[id]?.name ?? '')
              .join(', ')));
}
