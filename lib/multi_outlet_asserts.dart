import 'package:collection/collection.dart';
import 'package:sidekick/assert_outlet_name_and_number.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';

Map<String, T> assertMultiOutletState<T extends MultiOutlet>(
    {required Map<String, T> multiOutlets,
    required Map<String, LocationModel> locations,
    required Map<String, CableModel> cables}) {
  final outletsByLocationId =
      multiOutlets.values.groupListsBy((item) => item.locationId);

  final sortedOutlets = locations.values
      .map((location) => (outletsByLocationId[location.uid] ?? [])
          .sorted((a, b) => b.number - a.number))
      .flattened;

  final withAssertedNameAndNumbers =
      assertOutletNameAndNumbers<T>(sortedOutlets, locations).toModelMap();

  // Extract and set the isRoot flag.
  final detachedMultiIds =
      _extractDetachedMultiIds(cables, withAssertedNameAndNumbers);

  return withAssertedNameAndNumbers.values
      .map((multi) => multi.copyWith(
            isDetached: detachedMultiIds.contains(multi.uid),
          ) as T)
      .toModelMap();
}

///
/// Extracts a Set of Ids which correspond to DataMulti's which are detached. A detached multi is one that does not directly plug into a rack. most commonly
/// an extension Sneak that is combining two or more other sneaks together.
///
Set<String> _extractDetachedMultiIds(
    Map<String, CableModel> cables, Map<String, MultiOutlet> multiOutlets) {
  // Collect some helper maps
  final multiCablesByMultiId = cables.values
      .where((cable) => cable.type == CableType.sneak)
      .groupListsBy((cable) => cable.outletId);
  final childrenByParentMultiId = cables.values
      .where((cable) => cable.type == CableType.dmx)
      .groupListsBy((cable) => cable.parentMultiId);

  // Iterrate through the dataMultis and extract the associated sneaks and all of the children associated with those sneaks.
  return multiOutlets.values
      .where((multi) {
        final associatedMultiCables = multiCablesByMultiId[multi.uid];

        if (associatedMultiCables == null || associatedMultiCables.isEmpty) {
          return false;
        }

        final allAssociatedChildCables = associatedMultiCables
            .map((parent) => childrenByParentMultiId[parent.uid] ?? [])
            .flattened
            .toList();

        // Check if all assoicated child cables are either an extension, or a spare.
        return allAssociatedChildCables
            .every((cable) => cable.isExtension || cable.isSpare);
      })
      .map((multi) => multi.uid)
      .toSet();
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
