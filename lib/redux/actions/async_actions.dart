import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:sidekick/balancer/models/balancer_fixture_model.dart';
import 'package:sidekick/balancer/models/balancer_power_outlet_model.dart';
import 'package:sidekick/balancer/naive_balancer.dart';
import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/classes/folded_cable.dart';
import 'package:sidekick/classes/universe_span.dart';
import 'package:sidekick/data_selectors/select_primary_and_secondary_location_ids.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/excel/create_color_lookup_sheet.dart';
import 'package:sidekick/excel/create_custom_looms_sheet.dart';
import 'package:sidekick/excel/create_data_multi_sheet.dart';
import 'package:sidekick/excel/create_data_patch_sheet.dart';
import 'package:sidekick/excel/create_fixture_type_validation_sheet.dart';
import 'package:sidekick/excel/create_permanent_looms_sheet.dart';
import 'package:sidekick/excel/create_power_patch_sheet.dart';
import 'package:sidekick/excel/read_fixture_type_database.dart';
import 'package:sidekick/excel/read_fixtures_patch_data.dart';
import 'package:sidekick/extension_methods/queue_pop.dart';
import 'package:sidekick/file_type_groups.dart';
import 'package:sidekick/generic_dialog/show_generic_dialog.dart';
import 'package:sidekick/global_keys.dart';
import 'package:sidekick/import_merging/merge_fixtures.dart';
import 'package:sidekick/model_collection/convert_to_model_map.dart';
import 'package:sidekick/persistent_settings/fetch_persistent_settings.dart';
import 'package:sidekick/persistent_settings/init_persistent_settings_storage.dart';
import 'package:sidekick/persistent_settings/updatePersistentSettings.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/models/permanent_loom_composition.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:path/path.dart' as p;
import 'package:sidekick/screens/looms/add_spare_cables.dart';
import 'package:sidekick/screens/sequencer_dialog/sequencer_dialog.dart';
import 'package:sidekick/serialization/project_file_model.dart';
import 'package:sidekick/serialization/serialize_project_file.dart';
import 'package:sidekick/snack_bars/file_error_snack_bar.dart';
import 'package:sidekick/snack_bars/file_save_success_snack_bar.dart';
import 'package:sidekick/utils/get_uid.dart';

ThunkAction<AppState> deleteSelectedCables(BuildContext context) {
  return (Store<AppState> store) async {
    final selectedCables = store.state.navstate.selectedCableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .toList();

    final cablesEligibleForDelete = selectedCables
        .where((cable) => cable.isSpare || cable.upstreamId.isNotEmpty);

    final withSneakChildren =
        cablesEligibleForDelete.expand((cable) => cable.type == CableType.sneak
            ? [
                cable,
                ...store.state.fixtureState.cables.values
                    .where((child) => child.parentMultiId == cable.uid)
              ]
            : [cable]);

    final idsToRemove = withSneakChildren.map((cable) => cable.uid).toSet();

    store.dispatch(SetCables(
        Map<String, CableModel>.from(store.state.fixtureState.cables)
          ..removeWhere((key, value) => idsToRemove.contains(key))));
  };
}

ThunkAction<AppState> addSpareCablesToLoom(
    BuildContext context, String loomId) {
  return (Store<AppState> store) async {
    final loom = store.state.fixtureState.looms[loomId];

    if (loom == null) {
      return;
    }

    final result = await showModalBottomSheet(
        context: context, builder: (context) => const AddSpareCables());

    if (result == null) {
      return;
    }

    if (result is AddSpareCablesResult) {
      final qty = result.qty;
      final type = result.type;

      final existingCablesOfType = store.state.fixtureState.cables.values
          .where((cable) => cable.loomId == loomId && cable.type == type)
          .toList();
      final existingSpareCablesOfType =
          existingCablesOfType.where((cable) => cable.isSpare == true).toList();

      final newSpareCables = List<CableModel>.generate(qty, (index) {
        return CableModel(
          uid: getUid(),
          locationId: loom.secondaryLocationIds.first,
          type: type,
          isSpare: true,
          length: existingSpareCablesOfType.isNotEmpty
              ? existingSpareCablesOfType.first.length
              : existingCablesOfType.isNotEmpty
                  ? existingCablesOfType.first.length
                  : 0,
          loomId: loomId,
          spareIndex: existingSpareCablesOfType.length + index + 1,
        );
      });

      store.dispatch(SetCables(
          Map<String, CableModel>.from(store.state.fixtureState.cables)
            ..addAll(convertToModelMap(newSpareCables))));
    }
  };
}

ThunkAction<AppState> splitSneakIntoDmx(
    BuildContext context, Set<String> cableIds) {
  return (Store<AppState> store) async {
    final validCables = cableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .where((cable) => cable.type == CableType.sneak)
        .toList();

    if (validCables.isEmpty) {
      return;
    }

    final locationIds = validCables.map((cable) => cable.locationId).toSet();

    if (locationIds.length > 1) {
      await showGenericDialog(
          context: context,
          title: "Woops",
          message: "Can't split cables from different locations.. yet",
          affirmativeText: "Okay");
      return;
    }

    final loomIds = validCables.map((cable) => cable.loomId).toSet();

    if (loomIds.length > 1) {
      await showGenericDialog(
          context: context,
          title: "Woops",
          message: "Can't Split cables from different Looms.. yet",
          affirmativeText: "Okay");
      return;
    }

    final locationId = locationIds.first;
    final location = store.state.fixtureState.locations[locationId];

    if (location == null) {
      return;
    }

    final dataMultiIdsToRemove = validCables
        .map(
            (cable) => store.state.fixtureState.dataMultis[cable.outletId]?.uid)
        .nonNulls
        .toSet();

    final associatedCables = validCables
        .map((cable) => store.state.fixtureState.cables.values
            .where((item) => item.parentMultiId == cable.uid))
        .flattened
        .toList();

    final spareCableIdsToRemove = associatedCables
        .where((cable) => cable.isSpare)
        .map((cable) => cable.uid)
        .toSet();

    final sneakCableIdsToRemove = validCables.map((cable) => cable.uid).toSet();

    final updatedDataMultis =
        Map<String, DataMultiModel>.from(store.state.fixtureState.dataMultis)
          ..removeWhere((key, value) => dataMultiIdsToRemove.contains(key));

    final updatedCables = Map<String, CableModel>.from(
        store.state.fixtureState.cables)
      ..addAll(convertToModelMap(
          associatedCables.map((cable) => cable.copyWith(parentMultiId: ''))))
      ..removeWhere((key, value) =>
          spareCableIdsToRemove.contains(key) ||
          sneakCableIdsToRemove.contains(key));

    store.dispatch(SetCables(updatedCables));
    store.dispatch(SetDataMultis(updatedDataMultis));
  };
}

ThunkAction<AppState> combineDmxCablesIntoSneak(
    BuildContext context, Set<String> cableIds) {
  return (Store<AppState> store) async {
    final validCables = cableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .where((cable) =>
            cable.parentMultiId.isEmpty && cable.type == CableType.dmx)
        .toList();

    if (validCables.isEmpty) {
      return;
    }

    final locationIds = validCables.map((cable) => cable.locationId).toSet();

    if (validCables.length > 4) {
      await showGenericDialog(
          context: context,
          title: "Woops",
          message: "Can't combine more than 4 cables into Sneak.. yet",
          affirmativeText: "Okay");
      return;
    }

    final locationId = locationIds.first;
    final location = store.state.fixtureState.locations[locationId];
    final loomId = validCables.first.loomId;

    if (location == null) {
      return;
    }

    final newMultiOutlet = DataMultiModel(
      uid: getUid(),
      locationId: locationId,
      // Name and Number properties will be asserted later.
    );

    final newSneak = CableModel(
      uid: getUid(),
      type: CableType.sneak,
      locationId: locationId,
      loomId: loomId,
      length: validCables
          .map((cable) => cable.length)
          .sorted((a, b) => a.round() - b.round())
          .first,
      outletId: newMultiOutlet.uid,
    );

    final updatedCables = [
      ...validCables.map((cable) =>
          cable.copyWith(parentMultiId: newSneak.uid, loomId: loomId)),

      // Generate Spares if required.
      ...List<CableModel>.generate(
        4 - validCables.length,
        (index) => CableModel(
          uid: getUid(),
          locationId: locationId,
          isSpare: true,
          spareIndex: index + 1,
          loomId: loomId,
          parentMultiId: newSneak.uid,
          type: CableType.dmx,
        ),
      ),
      newSneak,
    ];

    final dataMultisWithNewEntry =
        Map<String, DataMultiModel>.from(store.state.fixtureState.dataMultis)
          ..addAll(convertToModelMap([newMultiOutlet]));

    // Assert correct Labeling of all Data Multis in this location, now that we have updated them.
    final dataMultisInLocation = dataMultisWithNewEntry.values
        .where((multi) => multi.locationId == locationId)
        .toList();

    final updatedDataMultis = Map<String, DataMultiModel>.from(
        dataMultisWithNewEntry)
      ..addEntries(dataMultisInLocation.mapIndexed((index, multi) => MapEntry(
          multi.uid,
          multi.copyWith(
            name: location.getPrefixedDataMultiPatch(
                dataMultisInLocation.length > 1 ? index + 1 : null),
            number: index + 1,
          ))));

    store.dispatch(UpdateCablesAndDataMultis(
        Map<String, CableModel>.from(store.state.fixtureState.cables)
          ..addAll(convertToModelMap(updatedCables)),
        updatedDataMultis));
  };
}

ThunkAction<AppState> addSelectedCablesToLoom(
    BuildContext context, String loomId, Set<String> cableIds) {
  return (Store<AppState> store) async {
    final cables = cableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .toList();

    if (cables.isEmpty) {
      return;
    }

    final loom = store.state.fixtureState.looms[loomId];

    if (loom == null) {
      return;
    }

    final validCables = cables.where((cable) =>
        cable.loomId != loomId &&
        cable.isSpare == false &&
        loom.secondaryLocationIds.contains(cable.locationId));

    if (validCables.isEmpty) {
      return;
    }

    // If its a Custom Loom we can just add the new cables.
    if (loom.type.type == LoomType.custom) {
      addCablesToCustomLoom(validCables, loom, store);
      return;
    }

    // Its a permanent loom. So we need to ensure we follow composition policies here.
    final candidateChildren = [
      ...store.state.fixtureState.cables.values
          .where((cable) => cable.loomId == loomId)
          .nonNulls
          .where((cable) => cable.isSpare == false),
      ...validCables,
    ];

    final permanentComps =
        PermanentLoomComposition.matchToPermanents(candidateChildren);

    final loomAndChildrenTuples = _mapCablesToPermanentLooms(
        candidateChildren,
        store.state.fixtureState.cables,
        permanentComps,
        store.state.fixtureState.locations,
        recyclableLoomIds: [loomId]);

    final (updatedCables, updatedLooms) =
        _applyPermanentLoomChangesToCollection(store.state.fixtureState.cables,
            store.state.fixtureState.looms, loomAndChildrenTuples);

    store.dispatch(SetCablesAndLooms(
      updatedCables,
      updatedLooms,
    ));
  };
}

ThunkAction<AppState> switchLoomType(
    BuildContext context, String loomId, List<CableModel> children) {
  return (Store<AppState> store) async {
    final loom = store.state.fixtureState.looms[loomId];

    if (loom == null) {
      return;
    }

    if (loom.type.type == LoomType.permanent) {
      // Super easy to go from Permanent to Custom.
      final updatedLooms =
          Map<String, LoomModel>.from(store.state.fixtureState.looms)
            ..update(
              loom.uid,
              (existing) => existing.copyWith(
                type: LoomTypeModel(
                  length: existing.type.length,
                  type: LoomType.custom,
                ),
              ),
            );

      // Ensure the Child cables all adopt the original Permanent Looms Length.
      final updatedChildCables = convertToModelMap(store
          .state.fixtureState.cables.values
          .where((cable) => cable.loomId == loomId)
          .nonNulls
          .map((cable) => cable.copyWith(
                length: loom.type.length,
              )));

      store.dispatch(SetCablesAndLooms(
          Map<String, CableModel>.from(store.state.fixtureState.cables)
            ..addAll(updatedChildCables),
          updatedLooms));

      return;
    }

    // We need to do a little bit more work to convert to a Permanent.
    // Remove the existing Custom Loom from the collection.
    final children = store.state.fixtureState.cables.values
        .where((cable) => cable.loomId == loomId)
        .nonNulls
        .toList();
    // Attempt to generate new permanent looms from it's children.
    final (updatedCables, updatedLooms, error) = buildNewPermanentLooms(
        existingCables: store.state.fixtureState.cables,
        existingLooms: store.state.fixtureState.looms,
        cables: children,
        allLocations: store.state.fixtureState.locations);

    if (error != null) {
      await showGenericDialog(
          context: context,
          title: 'Woops',
          message: error,
          affirmativeText: 'Okay');
      return;
    }

    store.dispatch(SetCablesAndLooms(updatedCables,
        Map<String, LoomModel>.from(updatedLooms)..remove(loomId)));
  };
}

ThunkAction<AppState> deleteLoom(BuildContext context, String uid) {
  return (Store<AppState> store) async {
    if (uid.isEmpty) {
      return;
    }

    final loom = store.state.fixtureState.looms[uid];

    if (loom == null) {
      return;
    }

    final allChildCables = store.state.fixtureState.cables.values
        .where((cable) => cable.loomId == loom.uid)
        .toList();

    final cablesToBeDeleted =
        allChildCables.where((cable) => cable.upstreamId.isNotEmpty);

    final cablesToBeFreed =
        allChildCables.where((cable) => cable.upstreamId.isEmpty).toList();

    // Delete only the loom and break the cables free if the cables are not extensions, otherwise. Delete the cables as well.
    final updatedLooms =
        Map<String, LoomModel>.from(store.state.fixtureState.looms)
          ..remove(uid);

    final updatedCables =
        Map<String, CableModel>.from(store.state.fixtureState.cables);

    // Delete the cables that need to be deleted.
    final deleteIds = cablesToBeDeleted.map((cable) => cable.uid).toSet();
    updatedCables.removeWhere((key, value) => deleteIds.contains(key));

    // If any of the cables we are deleting have downstream affiliated cables. We should repair the references on those downstream cables,
    // Essentially we are bring those cables up the line.
    updatedCables.updateAll((key, cable) {
      if (deleteIds.contains(cable.upstreamId)) {
        final deletedCable = cablesToBeDeleted
            .firstWhereOrNull((item) => item.uid == cable.upstreamId);

        if (deletedCable == null) {
          return cable;
        }

        return cable.copyWith(
          upstreamId: deletedCable.upstreamId,
        );
      }

      return cable;
    });

    // Now remove any references to the Loom we just deleted.
    for (final cable in cablesToBeFreed) {
      final targetCable = updatedCables[cable.uid];

      if (targetCable == null) {
        continue;
      }

      updatedCables[cable.uid] = targetCable.copyWith(loomId: '');
    }

    store.dispatch(SetSelectedCableIds({}));
    store.dispatch(SetCablesAndLooms(updatedCables, updatedLooms));
  };
}

ThunkAction<AppState> debugButtonPressed() {
  return (Store<AppState> store) async {};
}

ThunkAction<AppState> createExtensionFromSelection(
    BuildContext context, Set<String> cableIds) {
  return (Store<AppState> store) async {
    final upstreamParentCables = cableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        // If cable is a Sneak, place it into a Tuple with it's children, otherwise return just the tuple with an empty list.
        .map((cable) => cable.type == CableType.sneak
            ? FoldedCable(
                cable,
                store.state.fixtureState.cables.values
                    .where((item) => item.parentMultiId == cable.uid)
                    .toList())
            : FoldedCable(cable, const []))
        .toList();

    if (upstreamParentCables.isEmpty) {
      return;
    }

    // Create new Extension cables templated off of existing upstream cables. We have to be careful with Sneaks though in order to correctly
    // grab their children. We do this in multiple passes of .map to keep things readable.
    final extensionTuples = upstreamParentCables
        // Create new Parent Cables. Dont try and reparent the children yet.
        .map(
          (tuple) => tuple.copyWith(
              // Parent Cable
              cable: tuple.cable.copyWith(
                uid: getUid(),
                upstreamId: tuple.cable.uid,
              ),

              // Children..
              children: tuple.children
                  .map((cable) =>
                      cable.copyWith(uid: getUid(), upstreamId: cable.uid))
                  .toList()),
        )
        // Now reparent any child cables.
        .map((tuple) =>
            tuple.cable.type == CableType.sneak && tuple.children.isNotEmpty
                ? tuple.copyWith(
                    children: tuple.children
                        .map((cable) =>
                            cable.copyWith(parentMultiId: tuple.cable.uid))
                        .toList())
                : tuple)
        // Now Destructure the elements out of the Tuple.
        .expand((tuple) => [tuple.cable, ...tuple.children]);

    if (upstreamParentCables.every((tuple) => tuple.cable.loomId.isEmpty)) {
      // No cables were part of any loom. So we only need to modify the cables collection.
      store.dispatch(SetCables(
          Map<String, CableModel>.from(store.state.fixtureState.cables)
            ..addAll(convertToModelMap(extensionTuples))));
      return;
    }

    // Upstream cables belong to 1 or multiple Looms.
    // Break up the extension cables by Loom Id. Then process each Loom one by one
    final extensionCablesByLoomId =
        extensionTuples.groupListsBy((cable) => cable.loomId);

    final (updatedCables, updatedLooms) = extensionCablesByLoomId.entries
        .fold((store.state.fixtureState.cables, store.state.fixtureState.looms),
            (accum, entry) {
      if (entry.key.isEmpty) {
        // If the key is empty, it means that cable didn't belong to a Loom. We will deal with these cables a bit later.
        return accum;
      }

      final loom = store.state.fixtureState.looms[entry.key];

      if (loom == null) {
        return accum;
      }

      final extensionCables = entry.value;

      return _createExtensionLoom(
        source: loom,
        extensionCables: extensionCables,
        existingCables: accum.$1,
        existingLooms: accum.$2,
      );
    });

    // Deal with any cables that were not part of any loom, we specifically ignored these cables in the last step.
    if (extensionCablesByLoomId.containsKey('')) {
      final orphanExtensionCables = extensionCablesByLoomId['']!;
      updatedCables.addAll(convertToModelMap(orphanExtensionCables));
    }

    store.dispatch(SetCablesAndLooms(updatedCables, updatedLooms));
    return;
  };
}

(Map<String, CableModel> updatedCables, Map<String, LoomModel> updatedLooms)
    _createExtensionLoom(
        {required LoomModel source,
        required List<CableModel> extensionCables,
        required Map<String, CableModel> existingCables,
        required Map<String, LoomModel> existingLooms}) {
  final existingLoom = source;
  final newLoom = existingLoom.copyWith(
    uid: getUid(),
    loomClass: LoomClass.extension,
    secondaryLocationIds: extensionCables
        .map((cable) => cable.locationId)
        .where((id) => id != existingLoom.locationId)
        .toSet(),
  );

  final updatedLooms = Map<String, LoomModel>.from(existingLooms)
    ..addAll({newLoom.uid: newLoom});

  final updatedCables = Map<String, CableModel>.from(existingCables)
    ..addAll(convertToModelMap(
        extensionCables.map((cable) => cable.copyWith(loomId: newLoom.uid))));

  return (updatedCables, updatedLooms);
}

ThunkAction<AppState> combineCablesIntoNewLoom(
  BuildContext context,
  Set<String> cableIds,
  LoomType type,
) {
  return (Store<AppState> store) async {
    final cables = cableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .toList();

    if (cables.isEmpty) {
      return;
    }

    if (type == LoomType.custom) {
      final (String primaryLocationId, Set<String> secondaryLocationIds) =
          selectPrimaryAndSecondaryLocationIds(cables);

      final (updatedCables, updatedLooms) = buildNewCustomLooms(
          store: store,
          primaryLocationId: primaryLocationId,
          secondaryLocationIds: secondaryLocationIds,
          cableIds: cableIds);
      store.dispatch(SetCablesAndLooms(updatedCables, updatedLooms));

      return;
    }

    if (type == LoomType.permanent) {
      final (updatedCables, updatedLooms, error) = buildNewPermanentLooms(
          existingCables: store.state.fixtureState.cables,
          existingLooms: store.state.fixtureState.looms,
          allLocations: store.state.fixtureState.locations,
          cables: cableIds
              .map((id) => store.state.fixtureState.cables[id])
              .nonNulls
              .toList());

      if (error != null) {
        await showGenericDialog(
            context: context,
            title: 'Oops',
            message: error,
            affirmativeText: 'Okay');
        return;
      }

      store.dispatch(SetCablesAndLooms(updatedCables, updatedLooms));
    }
  };
}

(
  Map<String, CableModel> updatedCables,
  Map<String, LoomModel> updatedLooms,
  String? error
) buildNewPermanentLooms({
  required Map<String, CableModel> existingCables,
  required Map<String, LoomModel> existingLooms,
  required List<CableModel> cables,
  required Map<String, LocationModel> allLocations,
}) {
  final permanentComps = PermanentLoomComposition.matchToPermanents(cables);

  if (permanentComps.isEmpty) {
    return ({}, {}, 'No suitable Permanent loom compositions found.');
  }

  final loomsWithChildrenTuples = _mapCablesToPermanentLooms(
      cables, existingCables, permanentComps, allLocations);

  final (updatedCables, updatedLooms) = _applyPermanentLoomChangesToCollection(
      existingCables, existingLooms, loomsWithChildrenTuples);

  return (updatedCables, updatedLooms, null);
}

(Map<String, CableModel>, Map<String, LoomModel>)
    _applyPermanentLoomChangesToCollection(
        Map<String, CableModel> existingCables,
        Map<String, LoomModel> existingLooms,
        List<(LoomModel, List<CableModel>)> loomsAndChildrenTuples) {
  final updatedCables = Map<String, CableModel>.from(existingCables);
  final updatedLooms = Map<String, LoomModel>.from(existingLooms);

  for (final (newLoom, children) in loomsAndChildrenTuples) {
    // Add the New Loom.
    updatedLooms[newLoom.uid] = newLoom;

    // Append the children.
    updatedCables.addAll(
      Map<String, CableModel>.fromEntries(
        children.map(
          (cable) => MapEntry(cable.uid, cable),
        ),
      ),
    );
  }

  return (updatedCables, updatedLooms);
}

List<
        (
          LoomModel loomModel,
          List<CableModel> children,
        )>
    _mapCablesToPermanentLooms(
        List<CableModel> cables,
        Map<String, CableModel> allExistingCables,
        List<PermanentLoomComposition> permanentComps,
        Map<String, LocationModel> allLocations,
        {List<String> recyclableLoomIds = const []}) {
  if (cables.isEmpty) {
    return [];
  }

  final activeCables = cables.where((cable) => cable.isSpare == false).toList();
  final spareCableIdsQueue = Queue<String>.from(
      cables.where((cable) => cable.isSpare).map((cable) => cable.uid));

  final powerQueue = Queue<CableModel>.from(activeCables.where((cable) =>
      cable.type == CableType.wieland6way || cable.type == CableType.socapex));
  final dmxQueue = Queue<CableModel>.from(
      activeCables.where((cable) => cable.type == CableType.dmx));
  final sneakQueue = Queue<CableModel>.from(
      activeCables.where((cable) => cable.type == CableType.sneak));

  final recyclableLoomIdsQueue = Queue<String>.from(recyclableLoomIds);

  return permanentComps.map((comp) {
    final newLoomId = recyclableLoomIdsQueue.isNotEmpty
        ? recyclableLoomIdsQueue.removeFirst()
        : getUid();

    final powerCables = powerQueue
        .pop(comp.powerWays)
        .map((cable) => cable.copyWith(loomId: newLoomId))
        .toList();
    final dmxWays = dmxQueue
        .pop(comp.dmxWays)
        .map((cable) => cable.copyWith(loomId: newLoomId))
        .toList();
    final sneakWays = sneakQueue
        .pop(comp.sneakWays)
        .map((cable) => cable.copyWith(loomId: newLoomId))
        .toList();

    final (String primaryLocationId, Set<String> secondaryLocationIds) =
        selectPrimaryAndSecondaryLocationIds(cables);

    final newLoomLength =
        LoomModel.matchLength(allLocations[primaryLocationId]);

    final newPowerCableType = cables
            .firstWhereOrNull((cable) => cable.type == CableType.socapex)
            ?.type ??
        CableType.wieland6way;

    final sparePowerCables = List<CableModel>.generate(
        comp.powerWays - powerCables.length,
        (index) => CableModel(
              uid: spareCableIdsQueue.isNotEmpty
                  ? spareCableIdsQueue.removeFirst()
                  : getUid(),
              type: newPowerCableType,
              length: newLoomLength,
              isSpare: true,
              locationId: primaryLocationId,
              spareIndex: index + 1,
              loomId: newLoomId,
            ));

    final spareDmxCables = List<CableModel>.generate(
        comp.dmxWays - dmxWays.length,
        (index) => CableModel(
              uid: spareCableIdsQueue.isNotEmpty
                  ? spareCableIdsQueue.removeFirst()
                  : getUid(),
              isSpare: true,
              length: newLoomLength,
              type: CableType.dmx,
              locationId: primaryLocationId,
              spareIndex: index + 1,
              loomId: newLoomId,
            ));

    final spareSneakCables = List<CableModel>.generate(
        comp.sneakWays - sneakWays.length,
        (index) => CableModel(
              uid: spareCableIdsQueue.isNotEmpty
                  ? spareCableIdsQueue.removeFirst()
                  : getUid(),
              isSpare: true,
              length: newLoomLength,
              type: CableType.sneak,
              locationId: primaryLocationId,
              spareIndex: index + 1,
              loomId: newLoomId,
            ));

    final allChildren = [
      ...powerCables,
      ...sparePowerCables,
      ...dmxWays,
      ...spareDmxCables,
      ...sneakWays,
      ...spareSneakCables,

      // Ensure any children of Sneak Snakes also get their LoomId property updated.
      // Even though these get usually filtered out on the UI Side of things, we should still
      // strive to keep them up to date with loom changes.
      ...cables
          .where((cable) => cable.type == CableType.sneak)
          .map((sneak) => allExistingCables.values
              .where((cable) => cable.parentMultiId == sneak.uid))
          .flattened
          .map((cable) => cable.copyWith(loomId: newLoomId))
    ];

    return (
      LoomModel(
        uid: newLoomId,
        locationId: primaryLocationId,
        secondaryLocationIds: secondaryLocationIds,
        type: LoomTypeModel(
          length: newLoomLength,
          type: LoomType.permanent,
          permanentComposition: comp.name,
        ),
      ),
      allChildren
    );
  }).toList();
}

(Map<String, CableModel> updatedCables, Map<String, LoomModel> updatedLooms)
    buildNewCustomLooms({
  required Store<AppState> store,
  required String primaryLocationId,
  required Set<String> secondaryLocationIds,
  required Set<String> cableIds,
}) {
  final cableIdsWithSneakChildren = cableIds
      .map((id) => store.state.fixtureState.cables[id])
      .nonNulls
      .map((cable) {
        if (cable.type != CableType.sneak) {
          return [cable.uid];
        } else {
          return [
            // Sneak...
            cable.uid,

            // and it's children.
            ...store.state.fixtureState.cables.values
                .where((item) => item.parentMultiId == cable.uid)
                .map((item) => item.uid)
          ];
        }
      })
      .flattened
      .toSet();

  final newLoom = LoomModel(
    uid: getUid(),
    locationId: primaryLocationId,
    secondaryLocationIds: secondaryLocationIds,
    type: LoomTypeModel(length: 0, type: LoomType.custom),
  );

  final updatedCables =
      Map<String, CableModel>.from(store.state.fixtureState.cables)
        ..updateAll((key, value) => cableIdsWithSneakChildren.contains(key)
            ? value.copyWith(loomId: newLoom.uid)
            : value);

  final updatedLooms =
      Map<String, LoomModel>.from(store.state.fixtureState.looms)
        ..[newLoom.uid] = newLoom;

  return (updatedCables, updatedLooms);
}

ThunkAction<AppState> initializeApp(BuildContext context) {
  return (Store<AppState> store) async {
    // Fetch Persistent Settings.
    await initPersistentSettingsStorage();
    final persistentSettings = await fetchPersistentSettings();

    // Set the Fixture Database Path value, and load the Fixture Database if we can.
    if (persistentSettings.fixtureTypeDatabasePath.isNotEmpty) {
      final fixtureTypeDatabaseResult = await readFixtureTypeDatabase(
          persistentSettings.fixtureTypeDatabasePath);
      if (fixtureTypeDatabaseResult.errorMessage == null) {
        store.dispatch(SetFixtureTypeDatabasePath(
            persistentSettings.fixtureTypeDatabasePath));
        store.dispatch(SetIsFixtureTypeDatabasePathValid(true));
        store.dispatch(SetFixtureTypes(fixtureTypeDatabaseResult.fixtureTypes));
      }
    }
  };
}

ThunkAction<AppState> selectFixtureTypeDatabaseFile(
    BuildContext context, String path) {
  return (Store<AppState> store) async {
    store.dispatch(SetFixtureTypeDatabasePath(path));

    if (await File(path).exists() == false) {
      store.dispatch(SetIsFixtureTypeDatabasePathValid(false));

      if (homeScaffoldKey.currentContext?.mounted == true) {
        ScaffoldMessenger.of(homeScaffoldKey.currentContext!).showSnackBar(
            fileErrorSnackBar(homeScaffoldKey.currentContext!,
                'Unable to find Fixture Type Database File.'));
      }
      return;
    }

    final result = await readFixtureTypeDatabase(path);

    if (result.errorMessage != null) {
      store.dispatch(SetIsFixtureTypeDatabasePathValid(false));

      if (context.mounted) {
        await showGenericDialog(
            context: context,
            title: 'Error',
            message: result.errorMessage!,
            affirmativeText: "Okay");
      }
      return;
    }

    store.dispatch(SetIsFixtureTypeDatabasePathValid(true));
    store.dispatch(SetFixtureTypes(result.fixtureTypes));

    await updatePersistentSettings(
        (existing) => existing.copyWith(fixtureTypeDatabasePath: path));
  };
}

ThunkAction<AppState> startNewProject(BuildContext context, bool saveCurrent) {
  return (Store<AppState> store) async {
    if (saveCurrent) {
      store.dispatch(saveProjectFile(context, SaveType.save));
    }

    store.dispatch(NewProject());
  };
}

ThunkAction<AppState> openProjectFile(
    BuildContext context, bool saveCurrent, String path) {
  return (Store<AppState> store) async {
    final contents = await File(path).readAsString();
    final projectFile = ProjectFileModel.fromJson(contents);

    store.dispatch(OpenProject(
      project: projectFile,
      parentDirectory: p.dirname(path),
      path: path,
    ));
  };
}

ThunkAction<AppState> saveProjectFile(BuildContext context, SaveType saveType) {
  return (Store<AppState> store) async {
    final saveAsNeeded = store.state.fileState.projectFilePath.isEmpty ||
        saveType == SaveType.saveAs;

    String targetFilePath = store.state.fileState.projectFilePath;

    // If a save as is required, collect the new File path and store it to target File Path.
    if (saveAsNeeded == true) {
      // Post a dialog to collect the new file location.
      final selectedFilePath = await getSaveLocation(
        acceptedTypeGroups: kProjectFileTypes,
        initialDirectory:
            await Directory(store.state.fileState.lastUsedProjectDirectory)
                    .exists()
                ? store.state.fileState.lastUsedProjectDirectory
                : null,
        confirmButtonText: 'Save As',
      );

      if (selectedFilePath == null || selectedFilePath.path.isEmpty) {
        return;
      }

      targetFilePath = selectedFilePath.path;
    }

    // Ensure the file path contains the correct extension.
    if (p.extension(targetFilePath).trim() != '.$kProjectFileExtension') {
      targetFilePath = '$targetFilePath.$kProjectFileExtension';
    }

    // Perform the File Operations.
    final newMetadata = await serializeProjectFile(store.state, targetFilePath);

    // Save the updated Metadata.
    store.dispatch(SetProjectFileMetadata(newMetadata));
    store.dispatch(SetLastUsedProjectDirectory(p.dirname(targetFilePath)));
    store.dispatch(SetProjectFilePath(targetFilePath));

    if (homeScaffoldKey.currentState?.mounted == true &&
        homeScaffoldKey.currentContext != null) {
      ScaffoldMessenger.of(homeScaffoldKey.currentContext!)
          .showSnackBar(fileSaveSuccessSnackBar());
    }
  };
}

ThunkAction<AppState> importPatchFile(BuildContext context) {
  return (Store<AppState> store) async {
    final filePath = store.state.fileState.fixturePatchImportPath;
    final settings = store.state.fileState.importSettings;

    if (settings.mergeWithExisting == false &&
        (store.state.fixtureState.fixtures.isNotEmpty ||
            store.state.fixtureState.locations.isNotEmpty)) {
      final dialogResult = await showGenericDialog(
          context: context,
          title: "Import file",
          message: 'If you continue any unsaved changes will be lost',
          affirmativeText: 'Continue',
          declineText: 'Go back');

      if (dialogResult == null || dialogResult == false) {
        return;
      }
    }

    final fixturesPatchDataResult = await readFixturesPatchData(
      path: filePath,
      fixtureTypes: store.state.fixtureState.fixtureTypes,
      patchSheetName: settings.patchDataSourceSheetName,
    );

    if (fixturesPatchDataResult.errorMessage != null) {
      if (context.mounted == true) {
        await showGenericDialog(
            // ignore: use_build_context_synchronously
            context: context,
            title: 'Patch Data Import Error',
            message: fixturesPatchDataResult.errorMessage!,
            affirmativeText: 'Okay');
      }

      return;
    }

    if (settings.mergeWithExisting == true) {
      store.dispatch(
        SetFixtures(
          mergeFixtures(
            existing: store.state.fixtureState.fixtures,
            incoming: fixturesPatchDataResult.fixtures,
            settings: settings,
          ),
        ),
      );
    } else {
      store.dispatch(ResetFixtureState());
      store.dispatch(SetFixtures(fixturesPatchDataResult.fixtures));
      store.dispatch(SetLocations(fixturesPatchDataResult.locations));
    }
  };
}

String getTestDataPath() {
  const String testDataDirectory = './test_data/';
  const String testFileName = 'fixtures.xlsx';
  final String testDataPath = p.join(testDataDirectory, testFileName);
  return testDataPath;
}

ThunkAction<AppState> generateCables() {
  return (Store<AppState> store) async {
    final powerCables = store.state.fixtureState.powerMultiOutlets.values
        .map((outlet) => CableModel(
              uid: getUid(),
              type: CableType.socapex,
              locationId: outlet.locationId,
              outletId: outlet.uid,
            ));

    final singleDataCables =
        store.state.fixtureState.dataPatches.values.map((patch) => CableModel(
              type: CableType.dmx,
              uid: getUid(),
              locationId: patch.locationId,
              outletId: patch.uid,
            ));

    final sortedByLocation = store.state.fixtureState.locations.keys
        .map((locationId) => [
              ...powerCables.where((cable) => cable.locationId == locationId),
              ...singleDataCables
                  .where((cable) => cable.locationId == locationId),
            ])
        .flattened
        .toList();

    store.dispatch(
      SetCables(
        convertToModelMap(sortedByLocation),
      ),
    );
  };
}

ThunkAction<AppState> updateLocationMultiPrefix(
    String locationId, String newValue) {
  return (Store<AppState> store) async {
    final existingLocation = store.state.fixtureState.locations[locationId];

    if (existingLocation == null) {
      return;
    }

    final updatedLocation = existingLocation.copyWith(multiPrefix: newValue);

    store.dispatch(SetLocations(
        Map<String, LocationModel>.from(store.state.fixtureState.locations)
          ..update(locationId, (_) => updatedLocation)));

    // If PowerMulti's associated to this location have already been created, update them as well.
    updateAssociatedPowerMultis(store, locationId, updatedLocation);

    // If DataMulti's assocated to this location have been created, update them as well.
    updateAssociatedDataMultis(store, locationId, updatedLocation);

    // If DataPatches associated to this location have been created, update them as well.
    updateAssociatedDataPatches(store, locationId, updatedLocation);
  };
}

ThunkAction<AppState> updateLocationMultiDelimiter(
    String locationId, String newValue) {
  return (Store<AppState> store) async {
    final existingLocation = store.state.fixtureState.locations[locationId];

    if (existingLocation == null) {
      return;
    }

    final updatedLocation =
        existingLocation.copyWith(delimiter: newValue.trim());

    store.dispatch(SetLocations(
        Map<String, LocationModel>.from(store.state.fixtureState.locations)
          ..update(locationId, (_) => updatedLocation)));

    // If PowerMulti's associated to this location have already been created, update them as well.
    updateAssociatedPowerMultis(store, locationId, updatedLocation);

    // If DataMulti's assocated to this location have been created, update them as well.
    updateAssociatedDataMultis(store, locationId, updatedLocation);

    // If DataPatches associated to this location have been created, update them as well.
    updateAssociatedDataPatches(store, locationId, updatedLocation);
  };
}

ThunkAction<AppState> rangeSelectFixtures(
    String startUid, String endUid, bool isAdditive) {
  return (Store<AppState> store) async {
    final fixtures = store.state.fixtureState.fixtures.values.toList();

    if (fixtures.isEmpty) {
      return;
    }

    if (fixtures.length == 1 || startUid == endUid) {
      store.dispatch(SetSelectedFixtureIds({startUid}));
      return;
    }

    final rawStartIndex =
        fixtures.indexWhere((fixture) => fixture.uid == startUid);
    final rawEndIndex = fixtures.indexWhere((fixture) => fixture.uid == endUid);

    if (rawStartIndex == -1 || rawEndIndex == -1) {
      return;
    }

    final (coercedStartIndex, coercedEndIndex) = rawStartIndex > rawEndIndex
        ? (rawEndIndex, rawStartIndex)
        : (rawStartIndex, rawEndIndex);

    final ids = fixtures
        .sublist(coercedStartIndex,
            coercedEndIndex + 1 <= fixtures.length ? coercedEndIndex + 1 : null)
        .map((fixture) => fixture.uid)
        .toSet();

    if (isAdditive) {
      ids.addAll(store.state.navstate.selectedFixtureIds);
    }

    // Optionally reverse the collection if the Range Selection itself was inverted.
    store.dispatch(SetSelectedFixtureIds(
        rawStartIndex > rawEndIndex ? ids.toList().reversed.toSet() : ids));
  };
}

ThunkAction<AppState> setSequenceNumbers(BuildContext context) {
  return (Store<AppState> store) async {
    final selectedFixtures = store.state.navstate.selectedFixtureIds
        .map((id) => store.state.fixtureState.fixtures[id]!)
        .toList();

    final result = await showDialog(
      context: context,
      builder: (context) => SequencerDialog(
          fixtures: selectedFixtures,
          fixtureTypes: store.state.fixtureState.fixtureTypes,
          nextAvailableSequenceNumber: _findNextAvailableSequenceNumber(
              selectedFixtures.map((fix) => fix.sequence).toList())),
    );

    if (result == null) {
      return;
    }

    if (result is Map<int, FixtureModel>) {
      final existingFixtures =
          Map<String, FixtureModel>.from(store.state.fixtureState.fixtures);

      for (final entry in result.entries) {
        final newSeqNumber = entry.key;
        final fixtureId = entry.value.uid;

        existingFixtures.update(
            fixtureId, (fixture) => fixture.copyWith(sequence: newSeqNumber));
      }

      final sortedFixtures = FixtureModel.sort(
          existingFixtures, store.state.fixtureState.locations);

      store.dispatch(SetFixtures(sortedFixtures));
    }
  };
}

ThunkAction<AppState> commitDataPatch() {
  return (Store<AppState> store) async {
    final dataPatchesByFixtureId = Map<String, DataPatchModel>.fromEntries(store
        .state.fixtureState.dataPatches.values
        .map((patch) => patch.fixtureIds.map((id) => MapEntry(id, patch)))
        .flattened);

    final updatedFixtures =
        store.state.fixtureState.fixtures.map((uid, fixture) {
      final associatedDataPatch = dataPatchesByFixtureId[uid];

      if (associatedDataPatch == null) {
        return MapEntry(uid, fixture);
      }

      // // TODO: Disabled until refactoring to Cable based Sneak children is complete.
      // final associatedMultiPatch =
      //     store.state.fixtureState.dataMultis[associatedDataPatch.multiId];

      return MapEntry(
          uid,
          fixture.copyWith(
            // dataMulti: associatedMultiPatch?.name ?? '',
            dataPatch: associatedDataPatch.name,
          ));
    });

    store.dispatch(SetFixtures(updatedFixtures));
  };
}

ThunkAction<AppState> generateDataPatch() {
  return (Store<AppState> store) async {
    final fixturesByLocationId = store.state.fixtureState.fixtures.values
        .groupListsBy((fixture) => fixture.locationId);

    final spansByLocationId = fixturesByLocationId.map(
      (locationId, fixtures) => MapEntry(
        locationId,
        store.state.fixtureState.honorDataSpans
            ? UniverseSpan.createSpans(fixtures)
            : fixtures
                .groupListsBy((fix) => fix.dmxAddress.universe)
                .entries
                .map((entry) => UniverseSpan(
                      fixtureIds:
                          entry.value.map((fixture) => fixture.uid).toList(),
                      startsAt: entry.value.first,
                      universe: entry.key,
                      endsAt: entry.value.last,
                    )),
      ),
    );

    final List<DataPatchModel> patches = [];

    for (final entry in spansByLocationId.entries) {
      final locationId = entry.key;
      final spans = entry.value;

      final Queue<DataPatchModel> existingPatches = Queue<DataPatchModel>.from(
          store.state.fixtureState.dataPatches.values
              .where((patch) => patch.locationId == locationId));

      final location = store.state.fixtureState.locations[locationId]!;

      for (final (index, span) in spans.indexed) {
        final basePatch = existingPatches.isNotEmpty
            ? existingPatches.removeFirst()
            : DataPatchModel(
                uid: getUid(),
                locationId: locationId,
              );

        patches.add(basePatch.copyWith(
          name: location.getPrefixedDataPatch(index + 1),
          number: index + 1,
          universe: span.universe,
          startsAtFixtureId: span.startsAt.fid,
          endsAtFixtureId: span.endsAt?.fid ?? 0,
          fixtureIds: span.fixtureIds,
          isSpare: false,
        ));
      }
    }

    store.dispatch(SetDataPatches(Map<String, DataPatchModel>.fromEntries(
        patches.map((patch) => MapEntry(patch.uid, patch)))));
  };
}

ThunkAction<AppState> updateMultiPrefix(String locationId, String newValue) {
  return (Store<AppState> store) async {
    final location = store.state.fixtureState.locations[locationId];

    if (location == null) {
      return;
    }

    // Update the Location.
    final updatedLocation = location.copyWith(multiPrefix: newValue);
    store.dispatch(
      SetLocations(
        Map<String, LocationModel>.from(store.state.fixtureState.locations)
          ..update(locationId, (_) => updatedLocation),
      ),
    );
  };
}

ThunkAction<AppState> commitPowerPatch(BuildContext context) {
  return (Store<AppState> store) async {
    // Map FixtureIds to their associated Power Outlet
    final fixtureLookupMap = Map<String, PowerOutletModel>.fromEntries(
        store.state.fixtureState.outlets
            .map((outlet) => outlet.fixtureIds.map(
                  (id) => MapEntry(id, outlet),
                ))
            .flattened);

    final existingFixtures =
        Map<String, FixtureModel>.from(store.state.fixtureState.fixtures);

    existingFixtures.updateAll((uid, fixture) {
      final outlet = fixtureLookupMap[uid]!;
      final multiOutlet =
          store.state.fixtureState.powerMultiOutlets[outlet.multiOutletId]!;

      return fixture.copyWith(
        powerMultiId: multiOutlet.uid,
        powerPatch: outlet.multiPatch,
      );
    });

    store.dispatch(SetFixtures(existingFixtures));
  };
}

ThunkAction<AppState> export(BuildContext context) {
  return (Store<AppState> store) async {
    final excel = Excel.createExcel();

    createPowerPatchSheet(
      excel: excel,
      outlets: store.state.fixtureState.outlets,
      powerMultis: store.state.fixtureState.powerMultiOutlets,
      locations: store.state.fixtureState.locations,
      fixtures: store.state.fixtureState.fixtures,
      fixtureTypes: store.state.fixtureState.fixtureTypes,
    );

    createColorLookupSheet(
      excel: excel,
      powerMultis: store.state.fixtureState.powerMultiOutlets,
      locations: store.state.fixtureState.locations,
    );

    createFixtureTypeValidationSheet(
      excel: excel,
      outlets: store.state.fixtureState.outlets,
      fixtures: store.state.fixtureState.fixtures,
      fixtureTypes: store.state.fixtureState.fixtureTypes,
    );

    createDataPatchSheet(
      excel: excel,
      dataOutlets: store.state.fixtureState.dataPatches.values,
      dataMultis: store.state.fixtureState.dataMultis,
      locations: store.state.fixtureState.locations,
      cables: store.state.fixtureState.cables,
    );

    createDataMultiSheet(
      excel: excel,
      dataOutlets: store.state.fixtureState.dataPatches,
      dataMultis: store.state.fixtureState.dataMultis,
      locations: store.state.fixtureState.locations,
      cables: store.state.fixtureState.cables,
    );

    createPermanentLoomsSheet(
      excel: excel,
      cables: store.state.fixtureState.cables,
      looms: store.state.fixtureState.looms,
      locations: store.state.fixtureState.locations,
      dataMultis: store.state.fixtureState.dataMultis,
      dataPatches: store.state.fixtureState.dataPatches,
      powerMultiOutlets: store.state.fixtureState.powerMultiOutlets,
    );

    createCustomLoomsSheet(
      excel: excel,
      cables: store.state.fixtureState.cables,
      looms: store.state.fixtureState.looms,
      locations: store.state.fixtureState.locations,
      dataMultis: store.state.fixtureState.dataMultis,
      dataPatches: store.state.fixtureState.dataPatches,
      powerMultiOutlets: store.state.fixtureState.powerMultiOutlets,
    );

    excel.delete('Sheet1');

    final fileBytes = excel.save();

    if (fileBytes == null) {
      print("File Bytes were null");
      return;
    }

    await File('./output/rack_patch.xlsx').writeAsBytes(fileBytes);
  };
}

ThunkAction<AppState> generatePatch() {
  return (Store<AppState> store) async {
    final fixtures = store.state.fixtureState.fixtures.values.toList();
    final balancer = NaiveBalancer();

    final unbalancedMultiOutlets = balancer.assignToOutlets(
      fixtures: fixtures
          .map((fixture) => BalancerFixtureModel.fromFixture(
              fixture: fixture,
              type: store.state.fixtureState.fixtureTypes[fixture.typeId]!))
          .toList(),
      multiOutlets: store.state.fixtureState.powerMultiOutlets.values.toList(),
      maxSequenceBreak: store.state.fixtureState.maxSequenceBreak,
    );

    final balancedMultiOutlets = _balanceOutlets(
      unbalancedMultiOutlets: unbalancedMultiOutlets,
      balancer: balancer,
      balanceTolerance: store.state.fixtureState.balanceTolerance,
    );

    _updatePowerMultisAndOutlets(store, balancedMultiOutlets);
  };
}

Map<PowerMultiOutletModel, List<BalancerPowerOutletModel>>
    _withLockedMultiLocationsRemoved(
        Map<PowerMultiOutletModel, List<BalancerPowerOutletModel>>
            unbalancedMultiOutlets,
        Map<String, LocationModel> locations) {
  final lockedLocationIds = locations.values
      .where((location) => location.isPowerPatchLocked)
      .map((location) => location.uid)
      .toSet();

  return Map<PowerMultiOutletModel, List<BalancerPowerOutletModel>>.from(
      unbalancedMultiOutlets)
    ..removeWhere((key, value) => lockedLocationIds.contains(key.locationId));
}

ThunkAction<AppState> addSpareOutlet(String uid) {
  return (Store<AppState> store) async {
    final multiOutlet = store.state.fixtureState.powerMultiOutlets[uid];

    if (multiOutlet == null) {
      return;
    }

    if (multiOutlet.desiredSpareCircuits >= 6) {
      return;
    }

    _updatePowerMultiSpareCircuitCount(
        store, uid, multiOutlet.desiredSpareCircuits + 1);
  };
}

ThunkAction<AppState> deleteSpareOutlet(String uid) {
  return (Store<AppState> store) async {
    final multiOutlet = store.state.fixtureState.powerMultiOutlets[uid];

    if (multiOutlet == null) {
      return;
    }

    if (multiOutlet.desiredSpareCircuits <= 0) {
      return;
    }

    _updatePowerMultiSpareCircuitCount(
        store, uid, multiOutlet.desiredSpareCircuits - 1);
  };
}

Map<PowerMultiOutletModel, List<PowerOutletModel>> _balanceOutlets({
  required Map<PowerMultiOutletModel, List<BalancerPowerOutletModel>>
      unbalancedMultiOutlets,
  required NaiveBalancer balancer,
  required double balanceTolerance,
}) {
  PhaseLoad currentLoad = PhaseLoad(0, 0, 0);

  return unbalancedMultiOutlets.map((multiOutlet, outlets) {
    final result = balancer.balanceOutlets(
      outlets,
      balanceTolerance: balanceTolerance,
      initialLoad: currentLoad,
    );

    currentLoad = result.load;

    return MapEntry(
        multiOutlet,
        result.outlets
            .map((balancerOutlet) => PowerOutletModel(
                phase: balancerOutlet.phase,
                multiOutletId: multiOutlet.uid,
                multiPatch: balancerOutlet.multiPatch,
                locationId: balancerOutlet.locationId,
                fixtureIds: balancerOutlet.child.fixtures
                    .map((fixture) => fixture.uid)
                    .toList(),
                load: balancerOutlet.child.amps))
            .toList());
  });
}

List<PowerMultiOutletModel> _updateMultiOutletNames(
  Iterable<PowerMultiOutletModel> multiOutlets,
) {
  final multiOutletsByLocationId =
      multiOutlets.groupListsBy((outlet) => outlet.locationId);

  return multiOutletsByLocationId.entries
      .map((entry) {
        final multiOutlets = entry.value;

        return multiOutlets
            .mapIndexed((index, outlet) => outlet.copyWith(number: index + 1));
      })
      .flattened
      .toList();
}

void _updatePowerMultisAndOutlets(Store<AppState> store,
    Map<PowerMultiOutletModel, List<PowerOutletModel>> balancedMultiOutlets) {
  final balancedAndDefaultNamedOutlets =
      _applyDefaultMultiOutletNames(balancedMultiOutlets, store);

  store.dispatch(SetPowerOutlets(
      balancedAndDefaultNamedOutlets.values.flattened.toList()));
  store.dispatch(
    SetPowerMultiOutlets(
      Map<String, PowerMultiOutletModel>.fromEntries(
          _updateMultiOutletNames(balancedAndDefaultNamedOutlets.keys)
              .map((multiOutlet) => MapEntry(multiOutlet.uid, multiOutlet))),
    ),
  );
}

/// Looks up the default Multi Outlet names for outlets that have not been assigned a name.
Map<PowerMultiOutletModel, List<PowerOutletModel>>
    _applyDefaultMultiOutletNames(
        Map<PowerMultiOutletModel, List<PowerOutletModel>> balancedMultiOutlets,
        Store<AppState> store) {
  return Map<PowerMultiOutletModel, List<PowerOutletModel>>.fromEntries(
      balancedMultiOutlets.entries.map((entry) {
    final outlet = entry.key;

    if (outlet.name.isEmpty) {
      final location = store.state.fixtureState.locations[outlet.locationId];

      if (location == null) {
        return entry;
      }

      final multisInLocation = balancedMultiOutlets.keys
          .where((multi) => multi.locationId == location.uid)
          .toList();

      return MapEntry(
        outlet.copyWith(
            name: location.getPrefixedPowerMulti(
                multisInLocation.length > 1 ? outlet.number : null)),
        entry.value,
      );
    }

    return entry;
  }));
}

void _updatePowerMultiSpareCircuitCount(
    Store<AppState> store, String uid, int desiredCount) {
  final existingMultiOutlets = store.state.fixtureState.powerMultiOutlets;

  existingMultiOutlets.update(
      uid, (existing) => existing.copyWith(desiredSpareCircuits: desiredCount));

  final balancer = NaiveBalancer();

  final unbalancedMultiOutlets = balancer.assignToOutlets(
    fixtures: store.state.fixtureState.fixtures.values
        .map((fixture) => BalancerFixtureModel.fromFixture(
            fixture: fixture,
            type: store.state.fixtureState.fixtureTypes[fixture.typeId]!))
        .toList(),
    multiOutlets: existingMultiOutlets.values.toList(),
    maxSequenceBreak: store.state.fixtureState.maxSequenceBreak,
  );

  final balancedMultiOutlets = _balanceOutlets(
    unbalancedMultiOutlets: unbalancedMultiOutlets,
    balancer: balancer,
    balanceTolerance: store.state.fixtureState.balanceTolerance,
  );

  _updatePowerMultisAndOutlets(store, balancedMultiOutlets);
}

void updateAssociatedPowerMultis(
    Store<AppState> store, String locationId, LocationModel updatedLocation) {
  final associatedPowerMultis = store
      .state.fixtureState.powerMultiOutlets.values
      .where((multi) => multi.locationId == locationId)
      .toList();

  if (associatedPowerMultis.isEmpty) {
    return;
  }

  final updatedPowerMultis = associatedPowerMultis.map((existing) =>
      existing.copyWith(
          name: updatedLocation.getPrefixedPowerMulti(
              associatedPowerMultis.length == 1 ? null : existing.number)));

  store.dispatch(SetPowerMultiOutlets(Map<String, PowerMultiOutletModel>.from(
      store.state.fixtureState.powerMultiOutlets)
    ..addEntries(
        updatedPowerMultis.map((multi) => MapEntry(multi.uid, multi)))));
}

void updateAssociatedDataMultis(
    Store<AppState> store, String locationId, LocationModel updatedLocation) {
  final associatedDataMultis = store.state.fixtureState.dataMultis.values
      .where((multi) => multi.locationId == locationId)
      .toList();

  if (associatedDataMultis.isEmpty) {
    return;
  }

  final updatedDataMultis = associatedDataMultis.map((existing) =>
      existing.copyWith(
          name: updatedLocation.getPrefixedDataMultiPatch(
              associatedDataMultis.length == 1 ? null : existing.number)));

  store.dispatch(SetDataMultis(
      Map<String, DataMultiModel>.from(store.state.fixtureState.dataMultis)
        ..addEntries(
            updatedDataMultis.map((multi) => MapEntry(multi.uid, multi)))));
}

void updateAssociatedDataPatches(
    Store<AppState> store, String locationId, LocationModel updatedLocation) {
  final associatedDataPatches = store.state.fixtureState.dataPatches.values
      .where((multi) => multi.locationId == locationId)
      .toList();

  if (associatedDataPatches.isEmpty) {
    return;
  }

  final updatedDataPatches = associatedDataPatches.map((existing) {
    return existing.copyWith(
        name: updatedLocation.getPrefixedDataPatch(
      associatedDataPatches.length == 1 ? null : existing.number,
    ));
  });

  store.dispatch(SetDataPatches(
      Map<String, DataPatchModel>.from(store.state.fixtureState.dataPatches)
        ..addEntries(
            updatedDataPatches.map((multi) => MapEntry(multi.uid, multi)))));
}

int _findNextAvailableSequenceNumber(List<int> sequenceNumbers) {
  if (sequenceNumbers.isEmpty) {
    return 1;
  }

  if (sequenceNumbers.length == 1) {
    return sequenceNumbers.first + 1;
  }

  final sortedSequenceNumbers = sequenceNumbers.sorted((a, b) => a - b);

  for (final (index, seq) in sortedSequenceNumbers.indexed) {
    if (index + 1 < sortedSequenceNumbers.length) {
      final nextSeq = sortedSequenceNumbers[index + 1];

      if (seq + 1 != nextSeq) {
        return seq + 1;
      }
    }
  }

  return sortedSequenceNumbers.last + 1;
}

void addCablesToCustomLoom(Iterable<CableModel> incomingCables, LoomModel loom,
    Store<AppState> store) {
  final rehomedCables =
      incomingCables.map((cable) => cable.copyWith(loomId: loom.uid));

  final updatedCables =
      Map<String, CableModel>.from(store.state.fixtureState.cables)
        ..addAll(
          convertToModelMap(rehomedCables),
        );

  store.dispatch(
    SetCables(updatedCables),
  );
}
