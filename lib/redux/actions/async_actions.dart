import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:sidekick/balancer/models/balancer_fixture_model.dart';
import 'package:sidekick/balancer/models/balancer_power_outlet_model.dart';
import 'package:sidekick/balancer/naive_balancer.dart';
import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/classes/cable_family.dart';
import 'package:sidekick/classes/export_file_paths.dart';
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
import 'package:sidekick/serialization/deserialize_project_file.dart';
import 'package:sidekick/serialization/project_file_model.dart';
import 'package:sidekick/serialization/serialize_project_file.dart';
import 'package:sidekick/snack_bars/composition_repair_error_snack_bar.dart';
import 'package:sidekick/snack_bars/export_success_snack_bar.dart';
import 'package:sidekick/snack_bars/file_error_snack_bar.dart';
import 'package:sidekick/snack_bars/file_save_success_snack_bar.dart';
import 'package:sidekick/snack_bars/generic_error_snack_bar.dart';
import 'package:sidekick/utils/get_uid.dart';
import 'package:url_launcher/url_launcher.dart';

ThunkAction<AppState> chooseExportDirectory(BuildContext context) {
  return (Store<AppState> store) async {
    final lastUsedExportDirectory =
        store.state.fileState.projectMetadata.lastUsedExportDirectory.isNotEmpty
            ? store.state.fileState.projectMetadata.lastUsedExportDirectory
            : store.state.fileState.lastUsedProjectDirectory;

    final lastUsedExportDirectoryExists =
        await Directory(lastUsedExportDirectory).exists();

    final pathResult = await getDirectoryPath(
        initialDirectory:
            lastUsedExportDirectoryExists && lastUsedExportDirectory.isNotEmpty
                ? lastUsedExportDirectory
                : null);

    if (pathResult == null) {
      return;
    }

    store.dispatch(SetLastUsedExportDirectory(pathResult));
  };
}

ThunkAction<AppState> changeExistingPowerMultisToDefault(BuildContext context) {
  return (Store<AppState> store) async {
    final targetValue = store.state.fixtureState.defaultPowerMulti;
    final existingValue = targetValue == CableType.socapex
        ? CableType.wieland6way
        : CableType.socapex;

    final updatedCables =
        Map<String, CableModel>.from(store.state.fixtureState.cables)
          ..updateAll((_, existingCable) => existingCable.type == existingValue
              ? existingCable.copyWith(type: targetValue)
              : existingCable);

    String permanentCompositionNameSwitcher(String value) =>
        targetValue == CableType.socapex
            ? value.replaceAll(kWielandSlug, kSocaSlug)
            : value.replaceAll(kSocaSlug, kWielandSlug);

    final keyword =
        existingValue == CableType.socapex ? kSocaSlug : kWielandSlug;
    final updatedLooms =
        Map<String, LoomModel>.from(store.state.fixtureState.looms)
          ..updateAll(
            (_, existingLoom) => existingLoom.type.permanentComposition
                    .contains(keyword)
                ? existingLoom.copyWith(
                    type: existingLoom.type.copyWith(
                        permanentComposition: permanentCompositionNameSwitcher(
                            existingLoom.type.permanentComposition)))
                : existingLoom,
          );

    store.dispatch(SetCablesAndLooms(
      updatedCables,
      updatedLooms,
    ));
  };
}

ThunkAction<AppState> repairLoomComposition(
    LoomModel loom, BuildContext context) {
  return (Store<AppState> store) async {
    final parentCables = store.state.fixtureState.cables.values
        .where(
            (cable) => cable.loomId == loom.uid && cable.parentMultiId.isEmpty)
        .toList();

    // Attempt a simple repair first.
    final firstRunComposition =
        PermanentLoomComposition.matchSuitablePermanent(parentCables);

    if (firstRunComposition != null) {
      store.dispatch(
        SetCablesAndLooms(
          // Cables
          Map<String, CableModel>.from(store.state.fixtureState.cables)
            ..addAll(convertToModelMap(_generateSpareCablesToMeetComposition(
                loom, parentCables, firstRunComposition))),
          // Looms
          Map<String, LoomModel>.from(store.state.fixtureState.looms)
            ..update(
              loom.uid,
              (_) => loom.copyWith(
                type: loom.type
                    .copyWith(permanentComposition: firstRunComposition.name),
              ),
            ),
        ),
      );
      return;
    }

    if (homeScaffoldKey.currentContext != null &&
        homeScaffoldKey.currentContext!.mounted) {
      ScaffoldMessenger.of(homeScaffoldKey.currentContext!).showSnackBar(
          compositionRepairSnackBar(context,
              'Unable to auto repair composition. Try combining DMX into Sneak or convert to a custom loom'));
    }
  };
}

List<CableModel> _generateSpareCablesToMeetComposition(
    LoomModel existingLoom,
    List<CableModel> existingParentCablesInLoom,
    PermanentLoomComposition targetComposition) {
  // Create any Spare cables if we have to in order to reach the desired composition.
  final cablesByType =
      existingParentCablesInLoom.groupListsBy((cable) => cable.type);
  final neededSocaWays = targetComposition.socaWays -
      (cablesByType[CableType.socapex]?.length ?? 0).clamp(0, 100);
  final neededWielandWays = targetComposition.wieland6Ways -
      (cablesByType[CableType.wieland6way]?.length ?? 0).clamp(0, 100);
  final neededSneakWays = targetComposition.sneakWays -
      (cablesByType[CableType.sneak]?.length ?? 0).clamp(0, 100);
  final neededDmxWays = targetComposition.dmxWays -
      (cablesByType[CableType.dmx]?.length ?? 0).clamp(0, 100);

  final existingSpareCablesByType = cablesByType.map((key, value) =>
      MapEntry(key, value.where((cable) => cable.isSpare == true).toList()));

  List<CableModel> generateSpares(int qty, CableType type) =>
      List<CableModel>.generate(
          qty,
          (index) => CableModel(
                uid: getUid(),
                locationId: existingLoom.locationId,
                loomId: existingLoom.uid,
                type: type,
                length: existingLoom.type.length,
                isSpare: true,
                spareIndex: (index + 1) +
                    (existingSpareCablesByType[type]?.length ?? 0),
              ));

  return [
    ...generateSpares(neededSocaWays, CableType.socapex),
    ...generateSpares(neededWielandWays, CableType.wieland6way),
    ...generateSpares(neededSneakWays, CableType.sneak),
    ...generateSpares(neededDmxWays, CableType.dmx),
  ];
}

ThunkAction<AppState> removeSelectedCablesFromLoom(BuildContext context) {
  return (Store<AppState> store) async {
    final cables = store.state.navstate.selectedCableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .toList();

    if (cables.isEmpty) {
      return;
    }

    store.dispatch(SetCables(
        Map<String, CableModel>.from(store.state.fixtureState.cables)
          ..addAll(convertToModelMap(
              cables.map((cable) => cable.copyWith(loomId: ''))))));
  };
}

ThunkAction<AppState> setSelectedCableIds(Set<String> ids) {
  return (Store<AppState> store) async {
    final cables =
        ids.map((id) => store.state.fixtureState.cables[id]).nonNulls.toList();

    // If we have selected any Parent Multi cable, select all it's children as well.
    final withChildCables = cables.expand((cable) => cable.isMultiCable
        ? [
            // Parent Multi Cable
            cable,

            // It's Children.
            ...store.state.fixtureState.cables.values
                .where((child) => child.parentMultiId == cable.uid)
          ]
        : [cable]);

    store.dispatch(
        SetSelectedCableIds(withChildCables.map((cable) => cable.uid).toSet()));
  };
}

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
          locationId: loom.locationId,
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

    final validCables = cables
        .where((cable) => cable.loomId != loomId && cable.isSpare == false);

    if (validCables.isEmpty) {
      return;
    }

    // Just add the Cables to the Loom, if it screws up the composition of a permanent loom, it will be indicated to the user anyway.
    _addCablesToLoom(validCables, loom, store);
    return;
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
  return (Store<AppState> store) async {
    print(store.state.fileState.projectMetadata.projectName);
  };
}

ThunkAction<AppState> createExtensionFromSelection(
    BuildContext context, Set<String> cableIds) {
  return (Store<AppState> store) async {
    if (cableIds.isEmpty) {
      return;
    }

    final selectedCables = cableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .toList();

    if (selectedCables.isEmpty) {
      return;
    }

    final locationId = selectedCables.first.locationId;

    // If we have any Multi Cables selected. We assume that the user is trying to create an extension of the Multi cable (and by extension it's children),
    // therefore we have to ensure that it's children get cloned and applied to the new Extension. However, if the user has only selected one or more of the
    // children of a Multi cable, we must assume that they are only extending that particular child.
    // In order to honor the above conditions, we should first 'Fold' all the selected cables into cable families. Folding any child of a multi cable into
    // it's parent cable BUT ONLY if the parent itself is selected.

    /// Child cables that have been selected individually (without having their parent also selected), need to be treated differently, almost as parent cables
    /// so we first extract a collection of these responsible child cables.
    final unsupervisedChildCables = selectedCables
        .where((cable) =>
            cable.parentMultiId.isNotEmpty &&
            cableIds.contains(cable.parentMultiId) == false)
        .toList();

    final unsupervisedChildCableIds =
        unsupervisedChildCables.map((cable) => cable.uid).toSet();

    final supervisedChildCableIds = selectedCables
        .where((cable) =>
            cable.parentMultiId.isNotEmpty &&
            cableIds.contains(cable.parentMultiId))
        .map((cable) => cable.uid)
        .toSet();

    final upstreamCableFamilies = selectedCables
        .where((cable) => supervisedChildCableIds.contains(cable.uid) == false)
        .map((cable) {
      if (cable.isMultiCable == false && cable.parentMultiId.isEmpty) {
        // Is a standard Cable.
        return CableFamily(cable, []);
      }

      if (unsupervisedChildCableIds.contains(cable.uid)) {
        // Unsupervised Child Cable. Treat it like a parent.
        return CableFamily(cable, []);
      }

      // Parent Cable, Fold it's children (if Any) into it.
      return CableFamily(
          cable,
          selectedCables
              .where((item) => item.parentMultiId == cable.uid)
              .toList());
    });

    // See if we can fit this in a Permanent Loom.
    final extensionLoomComposition =
        PermanentLoomComposition.matchSuitablePermanent(
            upstreamCableFamilies.map((family) => family.parent).toList());

    final extensionLoom = LoomModel(
        uid: getUid(),
        locationId: locationId,
        loomClass: LoomClass.extension,
        type: LoomTypeModel(
          length: 0,
          type: extensionLoomComposition == null
              ? LoomType.custom
              : LoomType.permanent,
          permanentComposition: extensionLoomComposition?.name ?? '',
        ));

    final extensionCables = upstreamCableFamilies
        .map((family) {
          final newParentId = getUid();
          return [
            // "Top Level Cable" either a legitimate parent, a normal childless cable, or an Unsupervised child.
            family.parent.copyWith(
              uid: newParentId,
              loomId: extensionLoom.uid,
              length: 0,
              upstreamId: family.parent.uid,
              parentMultiId:
                  '', // In the case of this being an unsupervised child, we need to emancipate it from it's parent.
            ),

            // Child Cables (if any)
            ...family.children.map((child) => child.copyWith(
                  uid: getUid(),
                  length: 0,
                  loomId: extensionLoom.uid,
                  upstreamId: child.uid,
                  parentMultiId: newParentId,
                ))
          ];
        })
        .flattened
        .toList();

    store.dispatch(SetCablesAndLooms(
        Map<String, CableModel>.from(store.state.fixtureState.cables)
          ..addAll(convertToModelMap(extensionCables)),
        Map<String, LoomModel>.from(store.state.fixtureState.looms)
          ..addAll(convertToModelMap([extensionLoom]))));
  };
}

ThunkAction<AppState> combineCablesIntoNewLoom(
  BuildContext context,
  Set<String> cableIds,
  LoomType type,
) {
  return (Store<AppState> store) async {
    final selectedCables = cableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .toList();

    if (selectedCables.isEmpty) {
      return;
    }

    final primaryLocationId = selectedCables.first.locationId;

    if (type == LoomType.custom) {
      final (updatedCables, updatedLooms) = buildNewCustomLooms(
          store: store, locationId: primaryLocationId, cableIds: cableIds);
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
  // Find matching Permanent Loom compositions. Don't include the Children of multi cables
  final parentCables =
      cables.where((cable) => cable.parentMultiId.isEmpty).toList();
  final permanentComps =
      PermanentLoomComposition.matchToPermanents(parentCables);

  if (permanentComps.isEmpty) {
    return ({}, {}, 'No suitable Permanent loom compositions found.');
  }

  final loomsWithChildrenTuples = _mapCablesToPermanentLooms(
      parentCables: parentCables,
      multiCableChildren:
          cables.where((cable) => cable.parentMultiId.isNotEmpty).toList(),
      allExistingCables: existingCables,
      permanentComps: permanentComps,
      allLocations: allLocations);

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
        {required List<CableModel> parentCables,
        required List<CableModel> multiCableChildren,
        required Map<String, CableModel> allExistingCables,
        required List<PermanentLoomComposition> permanentComps,
        required Map<String, LocationModel> allLocations,
        List<String> recyclableLoomIds = const []}) {
  if (parentCables.isEmpty) {
    return [];
  }

  final activeCables =
      parentCables.where((cable) => cable.isSpare == false).toList();
  final spareCableIdsQueue = Queue<String>.from(
      parentCables.where((cable) => cable.isSpare).map((cable) => cable.uid));

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

    final String locationId = parentCables.first.locationId;

    final newLoomLength = LoomModel.matchLength(allLocations[locationId]);

    final newPowerCableType =
        comp.socaWays > 0 ? CableType.socapex : CableType.wieland6way;

    final sparePowerCables = List<CableModel>.generate(
        comp.powerWays - powerCables.length,
        (index) => CableModel(
              uid: spareCableIdsQueue.isNotEmpty
                  ? spareCableIdsQueue.removeFirst()
                  : getUid(),
              type: newPowerCableType,
              length: newLoomLength,
              isSpare: true,
              locationId: locationId,
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
              locationId: locationId,
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
              locationId: locationId,
              spareIndex: index + 1,
              loomId: newLoomId,
            ));

    final allChildren = [
      ...powerCables,
      ...sparePowerCables,
      ...dmxWays,
      ...spareDmxCables,
      ...sneakWays,

      // Extract any Children of Sneaks and update their [loomId] property.
      ...sneakWays
          .map((sneak) => multiCableChildren
              .where((cable) => cable.parentMultiId == sneak.uid))
          .flattened
          .map((cable) => cable.copyWith(loomId: newLoomId)),

      ...spareSneakCables,

      // Ensure any children of Sneak Snakes also get their LoomId property updated.
      // Even though these get usually filtered out on the UI Side of things, we should still
      // strive to keep them up to date with loom changes.
      ...parentCables
          .where((cable) => cable.type == CableType.sneak)
          .map((sneak) => allExistingCables.values
              .where((cable) => cable.parentMultiId == sneak.uid))
          .flattened
          .map((cable) => cable.copyWith(loomId: newLoomId))
    ];

    return (
      LoomModel(
        uid: newLoomId,
        locationId: locationId,
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
  required String locationId,
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
    locationId: locationId,
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
    final projectFile = await deserializeProjectFile(path);

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
    var newMetadata = await serializeProjectFile(store.state, targetFilePath);

    // Save the updated Metadata.
    store.dispatch(SetProjectFileMetadata(newMetadata));
    store.dispatch(SetLastUsedProjectDirectory(p.dirname(targetFilePath)));
    store.dispatch(SetProjectFilePath(targetFilePath));

    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(fileSaveSuccessSnackBar(context));
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
              type: store.state.fixtureState.defaultPowerMulti,
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
    final outputPaths = ExportFilePaths(
        directoryPath:
            store.state.fileState.projectMetadata.lastUsedExportDirectory,
        projectName: store.state.fileState.projectMetadata.projectName,
        excelFileExtension: '.xlsx');

    if (await outputPaths.parentDirectoryExists == false) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(fileErrorSnackBar(context,
            'Parent directory could not be found. Have you selected a target directory?'));
      }
      return;
    }

    final existingFileNames = await outputPaths.getAlreadyExistingFileNames();

    if (existingFileNames.isNotEmpty) {
      if (context.mounted) {
        final dialogResult = await showGenericDialog(
          context: context,
          title: 'Overwrite existing files',
          message:
              'If you proceed, the following files will be overwritten.\n${existingFileNames.join('\n')}',
          affirmativeText: 'Overwrite',
          declineText: 'Cancel',
        );

        if (dialogResult == null || dialogResult == false) {
          return;
        }
      }
    }

    final referenceDataExcel = Excel.createExcel();
    createPowerPatchSheet(
      excel: referenceDataExcel,
      outlets: store.state.fixtureState.outlets,
      powerMultis: store.state.fixtureState.powerMultiOutlets,
      locations: store.state.fixtureState.locations,
      fixtures: store.state.fixtureState.fixtures,
      fixtureTypes: store.state.fixtureState.fixtureTypes,
    );

    createColorLookupSheet(
      excel: referenceDataExcel,
      powerMultis: store.state.fixtureState.powerMultiOutlets,
      locations: store.state.fixtureState.locations,
    );

    createFixtureTypeValidationSheet(
      excel: referenceDataExcel,
      outlets: store.state.fixtureState.outlets,
      fixtures: store.state.fixtureState.fixtures,
      fixtureTypes: store.state.fixtureState.fixtureTypes,
    );

    createDataPatchSheet(
      excel: referenceDataExcel,
      dataOutlets: store.state.fixtureState.dataPatches.values,
      dataMultis: store.state.fixtureState.dataMultis,
      locations: store.state.fixtureState.locations,
      cables: store.state.fixtureState.cables,
    );

    createDataMultiSheet(
      excel: referenceDataExcel,
      dataOutlets: store.state.fixtureState.dataPatches,
      dataMultis: store.state.fixtureState.dataMultis,
      locations: store.state.fixtureState.locations,
      cables: store.state.fixtureState.cables,
    );

    referenceDataExcel.delete('Sheet1');

    final loomsExcel = Excel.createExcel();

    createPermanentLoomsSheet(
      excel: loomsExcel,
      cables: store.state.fixtureState.cables,
      looms: store.state.fixtureState.looms,
      locations: store.state.fixtureState.locations,
      dataMultis: store.state.fixtureState.dataMultis,
      dataPatches: store.state.fixtureState.dataPatches,
      powerMultiOutlets: store.state.fixtureState.powerMultiOutlets,
    );

    createCustomLoomsSheet(
      excel: loomsExcel,
      cables: store.state.fixtureState.cables,
      looms: store.state.fixtureState.looms,
      locations: store.state.fixtureState.locations,
      dataMultis: store.state.fixtureState.dataMultis,
      dataPatches: store.state.fixtureState.dataPatches,
      powerMultiOutlets: store.state.fixtureState.powerMultiOutlets,
    );

    loomsExcel.delete('Sheet1');

    final referenceDataBytes = referenceDataExcel.save();
    final loomsBytes = loomsExcel.save();
    final powerPatchTemplateBytes =
        await rootBundle.load('assets/excel/prg_power_patch.xlsx');
    final dataPatchTemplateBytes =
        await rootBundle.load('assets/excel/prg_data_patch.xlsx');

    if (referenceDataBytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(fileErrorSnackBar(
            context, 'An error occured writing reference data excel'));
      }

      return;
    }

    if (loomsBytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(fileErrorSnackBar(
            context, 'An error occured writing looms data excel'));
      }

      return;
    }

    final fileWrites = [
      File(outputPaths.referenceDataPath).writeAsBytes(referenceDataBytes),
      File(outputPaths.loomsPath).writeAsBytes(loomsBytes),
      File(outputPaths.powerPatchPath)
          .writeAsBytes(powerPatchTemplateBytes.buffer.asUint8List()),
      File(outputPaths.dataPatchPath)
          .writeAsBytes(dataPatchTemplateBytes.buffer.asUint8List())
    ];

    try {
      final writeResults = await Future.wait(fileWrites);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(fileErrorSnackBar(
            context, 'One or more files failed to write to disk'));

        return;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(exportSuccessSnackbar(context));
    }

    if (store.state.navstate.openAfterExport == true) {
      await launchUrl(Uri.file(outputPaths.powerPatchPath));
      await launchUrl(Uri.file(outputPaths.dataPatchPath));
      await launchUrl(Uri.file(outputPaths.loomsPath));
    }
  };
}

ThunkAction<AppState> generatePatch(BuildContext context) {
  return (Store<AppState> store) async {
    final fixtures = store.state.fixtureState.fixtures.values.toList();
    final balancer = NaiveBalancer();

    try {
      final unbalancedMultiOutlets = balancer.assignToOutlets(
        fixtures: fixtures
            .map((fixture) => BalancerFixtureModel.fromFixture(
                fixture: fixture,
                type: store.state.fixtureState.fixtureTypes[fixture.typeId]!))
            .toList(),
        multiOutlets:
            store.state.fixtureState.powerMultiOutlets.values.toList(),
        maxSequenceBreak: store.state.fixtureState.maxSequenceBreak,
      );

      final balancedMultiOutlets = _balanceOutlets(
        unbalancedMultiOutlets: unbalancedMultiOutlets,
        balancer: balancer,
        balanceTolerance: store.state.fixtureState.balanceTolerance,
      );

      _updatePowerMultisAndOutlets(store, balancedMultiOutlets);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
          context: context,
          message: 'A balancing error occurred',
          extendedMessage: e.toString()));
      rethrow;
    }
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

void _updatePowerMultisAndOutlets(Store<AppState> store,
    Map<PowerMultiOutletModel, List<PowerOutletModel>> balancedMultiOutlets) {
  final balancedAndDefaultNamedOutlets =
      _applyDefaultMultiOutletNames(balancedMultiOutlets, store);

  // Power Outlets
  store.dispatch(SetPowerOutlets(
      balancedAndDefaultNamedOutlets.values.flattened.toList()));

  // Power Multis.
  store.dispatch(
    SetPowerMultiOutlets(
      Map<String, PowerMultiOutletModel>.from(
          convertToModelMap(balancedAndDefaultNamedOutlets.keys)),
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

    final location = store.state.fixtureState.locations[outlet.locationId];

    if (location == null) {
      return entry;
    }

    final multisInLocation = balancedMultiOutlets.keys
        .where((multi) => multi.locationId == location.uid)
        .toList();

    final outletName = location.getPrefixedPowerMulti(
        multisInLocation.length > 1 ? outlet.number : null);

    return MapEntry(
      outlet.copyWith(name: outletName),
      entry.value,
    );
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

void _addCablesToLoom(Iterable<CableModel> incomingCables, LoomModel loom,
    Store<AppState> store) {
  final rehomedCables =
      incomingCables.map((cable) => cable.copyWith(loomId: loom.uid));

  final updatedCables =
      Map<String, CableModel>.from(store.state.fixtureState.cables)
        ..addAll(
          convertToModelMap(rehomedCables),
        );

  store.dispatch(SetCables(updatedCables));
}
