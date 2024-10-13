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
import 'package:sidekick/classes/universe_span.dart';
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
import 'package:sidekick/screens/sequencer_dialog/sequencer_dialog.dart';
import 'package:sidekick/serialization/project_file_model.dart';
import 'package:sidekick/serialization/serialize_project_file.dart';
import 'package:sidekick/snack_bars/file_error_snack_bar.dart';
import 'package:sidekick/snack_bars/file_save_success_snack_bar.dart';
import 'package:sidekick/utils/get_uid.dart';

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
        loom.locationIds.contains(cable.locationId));

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
      ...loom.childrenIds
          .map((id) => store.state.fixtureState.cables[id])
          .nonNulls,
      ...validCables,
    ];

    final permanentComps =
        PermanentLoomComposition.matchToPermanents(candidateChildren);

    final loomAndSpareCableTuples = _mapCablesToPermanentLooms(
        cables, permanentComps, store.state.fixtureState.locations,
        recyclableLoomIds: [loomId]);

    final (updatedCables, updatedLooms) =
        _applyPermanentLoomChangesToCollection(store.state.fixtureState.cables,
            store.state.fixtureState.looms, loomAndSpareCableTuples);

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
      final updatedChildCables = convertToModelMap(loom.childrenIds
          .map((id) => store.state.fixtureState.cables[id])
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
    final children = loom.childrenIds
        .map((id) => store.state.fixtureState.cables[id])
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

    final allChildCables = loom.childrenIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
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
    final upstreamCables = cableIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls
        .toList();

    if (upstreamCables.isEmpty) {
      return;
    }

    final extensionCables = upstreamCables.map((upstream) => upstream.copyWith(
          uid: getUid(),
          upstreamId: upstream.uid,
        ));

    if (upstreamCables.every((cable) => cable.loomId.isEmpty)) {
      // No cables were part of any loom. So we only need to modify the cables collection.
      store.dispatch(SetCables(
          Map<String, CableModel>.from(store.state.fixtureState.cables)
            ..addAll(convertToModelMap(extensionCables))));
      return;
    }

    // Upstream cables belong to 1 or multiple Looms.
    // Break up the extension cables by Loom Id. Then process each Loom one by one
    final extensionCablesByLoomId =
        extensionCables.groupListsBy((cable) => cable.loomId);

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
    name: '${existingLoom.name} Extension',
    childrenIds: extensionCables.map((cable) => cable.uid).toList(),
    locationIds: extensionCables.map((cable) => cable.locationId).toSet(),
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
    final cables =
        cableIds.map((id) => store.state.fixtureState.cables[id]).nonNulls;

    if (cables.isEmpty) {
      return;
    }

    final locationIds = cables.map((cable) => cable.locationId).toSet();

    if (type == LoomType.custom) {
      final (updatedCables, updatedLooms) = buildNewCustomLooms(
          store: store, locationIds: locationIds, cableIds: cableIds);
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

  final loomsWithNewSpareCableTuples =
      _mapCablesToPermanentLooms(cables, permanentComps, allLocations);

  final (updatedCables, updatedLooms) = _applyPermanentLoomChangesToCollection(
      existingCables, existingLooms, loomsWithNewSpareCableTuples);

  return (updatedCables, updatedLooms, null);
}

(Map<String, CableModel>, Map<String, LoomModel>)
    _applyPermanentLoomChangesToCollection(
        Map<String, CableModel> existingCables,
        Map<String, LoomModel> existingLooms,
        List<(LoomModel, List<CableModel>)> loomsWithNewSpareCableTuples) {
  final updatedCables = Map<String, CableModel>.from(existingCables);
  final updatedLooms = Map<String, LoomModel>.from(existingLooms);

  for (final (newLoom, spareCables) in loomsWithNewSpareCableTuples) {
    // Add the New Loom.
    updatedLooms[newLoom.uid] = newLoom;

    // Update the loomId property of it's children in their collection.
    for (final cableId in newLoom.childrenIds) {
      if (updatedCables.containsKey(cableId)) {
        updatedCables.update(
            cableId, (existing) => existing.copyWith(loomId: newLoom.uid));
      }
    }

    // Append any Spare Cables that were created to Gap Fill.
    updatedCables.addAll(Map<String, CableModel>.fromEntries(
        spareCables.map((cable) => MapEntry(cable.uid, cable))));
  }

  return (updatedCables, updatedLooms);
}

List<
        (
          LoomModel loomModel,
          List<CableModel> spareCables,
        )>
    _mapCablesToPermanentLooms(
        List<CableModel> cables,
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
    final powerCables = powerQueue.pop(comp.powerWays).toList();
    final dmxWays = dmxQueue.pop(comp.dmxWays).toList();

    final sneakWays = sneakQueue.pop(comp.sneakWays).toList();

    final newLoomId = recyclableLoomIdsQueue.isNotEmpty
        ? recyclableLoomIdsQueue.removeFirst()
        : getUid();

    final newCableLocationId = cables.first.locationId;
    final newLoomLength =
        LoomModel.matchLength(allLocations[newCableLocationId]);

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
              locationId: newCableLocationId,
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
              locationId: newCableLocationId,
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
              locationId: newCableLocationId,
              spareIndex: index + 1,
              loomId: newLoomId,
            ));

    final allChildren = [
      ...powerCables,
      ...sparePowerCables,
      ...dmxWays,
      ...spareDmxCables,
      ...sneakWays,
      ...spareSneakCables
    ];

    return (
      LoomModel(
        uid: newLoomId,
        locationIds: allChildren.map((cable) => cable.locationId).toSet(),
        name: 'Untitled Loom',
        type: LoomTypeModel(
          length: newLoomLength,
          type: LoomType.permanent,
          permanentComposition: comp.name,
        ),
        childrenIds: allChildren.map((cable) => cable.uid).toList(),
      ),
      [
        ...sparePowerCables,
        ...spareDmxCables,
        ...spareSneakCables,
      ]
    );
  }).toList();
}

(Map<String, CableModel> updatedCables, Map<String, LoomModel> updatedLooms)
    buildNewCustomLooms({
  required Store<AppState> store,
  required Set<String> locationIds,
  required Set<String> cableIds,
}) {
  final newLoom = LoomModel(
    uid: getUid(),
    locationIds: locationIds,
    name: 'Untitled Loom',
    type: LoomTypeModel(length: 0, type: LoomType.custom),
    childrenIds: cableIds.toList(),
  );

  final updatedCables =
      Map<String, CableModel>.from(store.state.fixtureState.cables)
        ..updateAll((key, value) => newLoom.childrenIds.contains(key)
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

    // Save the updated MEtadata.
    store.dispatch(SetProjectFileMetadata(newMetadata));
    store.dispatch(SetLastUsedProjectDirectory(p.dirname(targetFilePath)));

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

    final singleDataCables = store.state.fixtureState.dataPatches.values
        .where((patch) => patch.multiId.isEmpty)
        .map((patch) => CableModel(
              type: CableType.dmx,
              uid: getUid(),
              locationId: patch.locationId,
              outletId: patch.uid,
            ));

    final multiDataCables =
        store.state.fixtureState.dataMultis.values.map((multi) => CableModel(
              type: CableType.sneak,
              uid: getUid(),
              locationId: multi.locationId,
              outletId: multi.uid,
            ));

    final sortedByLocation = store.state.fixtureState.locations.keys
        .map((locationId) => [
              ...powerCables.where((cable) => cable.locationId == locationId),
              ...singleDataCables
                  .where((cable) => cable.locationId == locationId),
              ...multiDataCables
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

      final associatedMultiPatch =
          store.state.fixtureState.dataMultis[associatedDataPatch.multiId];

      return MapEntry(
          uid,
          fixture.copyWith(
            dataMulti: associatedMultiPatch?.name ?? '',
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
    final List<DataMultiModel> multis = [];

    for (final entry in spansByLocationId.entries) {
      final locationId = entry.key;
      final spans = entry.value;

      final Queue<String> existingPatchIds = Queue<String>.from(store
          .state.fixtureState.dataPatches.values
          .where((patch) => patch.locationId == locationId)
          .map((patch) => patch.uid));

      final Queue<String> existingMultiIds = Queue<String>.from(store
          .state.fixtureState.dataMultis.values
          .where((multi) => multi.locationId == locationId)
          .map((multi) => multi.uid));

      /// TODO:
      /// Finish Implementing the queues above, calls to getUID below should first check if their is a relevant id to reuse.

      final location = store.state.fixtureState.locations[locationId];

      if (spans.length <= 2) {
        // Can be 2 singles.
        patches.addAll(
          spans.mapIndexed(
            (index, span) {
              final wayNumber = index + 1;
              return DataPatchModel(
                uid: existingPatchIds.isNotEmpty
                    ? existingPatchIds.removeFirst()
                    : getUid(),
                locationId: locationId,
                number: wayNumber,
                multiId: '',
                universe: span.universe,
                name: location?.getPrefixedDataPatch(
                        spans.length > 1 ? wayNumber : null) ??
                    '',
                startsAtFixtureId: span.startsAt.fid,
                endsAtFixtureId: span.endsAt?.fid ?? 0,
                fixtureIds: span.fixtureIds,
              );
            },
          ),
        );
      } else {
        final slices = spans.slices(4).toList();

        for (final (index, slice) in slices.indexed) {
          final wayNumber = index + 1;
          final parentMulti = DataMultiModel(
            uid: existingMultiIds.isNotEmpty
                ? existingMultiIds.removeFirst()
                : getUid(),
            locationId: locationId,
            name: location?.getPrefixedDataMultiPatch(
                    slices.length > 1 ? wayNumber : null) ??
                '',
            number: wayNumber,
          );

          multis.add(parentMulti);

          patches.addAll(
            slice.mapIndexed(
              (index, span) {
                final wayNumber = index + 1;
                return DataPatchModel(
                  uid: existingPatchIds.isNotEmpty
                      ? existingPatchIds.removeFirst()
                      : getUid(),
                  locationId: locationId,
                  number: wayNumber,
                  multiId: parentMulti.uid,
                  universe: span.universe,
                  startsAtFixtureId: span.startsAt.fid,
                  endsAtFixtureId: span.endsAt?.fid ?? 0,
                  name: location?.getPrefixedDataPatch(wayNumber,
                          parentMultiName: parentMulti.name) ??
                      '',
                  fixtureIds: span.fixtureIds,
                );
              },
            ),
          );

          // Add Spares if needed
          if (slice.length < 4) {
            final int diff = 4 - slice.length;
            patches.addAll(
              List<DataPatchModel>.generate(
                diff,
                (index) {
                  final wayNumber = index + 1;
                  return DataPatchModel(
                    uid: existingPatchIds.isNotEmpty
                        ? existingPatchIds.removeFirst()
                        : getUid(),
                    locationId: locationId,
                    multiId: parentMulti.uid,
                    number: wayNumber,
                    universe: 0,
                    name: 'SP $wayNumber',
                    startsAtFixtureId: 0,
                    endsAtFixtureId: 0,
                    isSpare: true,
                    fixtureIds: [],
                  );
                },
              ),
            );
          }
        }
      }
    }

    store.dispatch(SetDataMultis(Map<String, DataMultiModel>.fromEntries(
        multis.map((multi) => MapEntry(multi.uid, multi)))));
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
    );

    createDataMultiSheet(
      excel: excel,
      dataOutlets: store.state.fixtureState.dataPatches.values,
      dataMultis: store.state.fixtureState.dataMultis,
      locations: store.state.fixtureState.locations,
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
            parentMultiName: existing.multiId.isNotEmpty
                ? store.state.fixtureState.dataMultis[existing.multiId]?.name
                : null));
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
  final children = [
    ...loom.childrenIds
        .map((id) => store.state.fixtureState.cables[id])
        .nonNulls,
    ...rehomedCables,
  ];

  final updatedLoom =
      loom.copyWith(childrenIds: children.map((cable) => cable.uid).toList());

  final updatedCables =
      Map<String, CableModel>.from(store.state.fixtureState.cables)
        ..addAll(
          convertToModelMap(rehomedCables),
        );

  final updatedLooms = Map<String, LoomModel>.from(
    store.state.fixtureState.looms
      ..addEntries(
        [MapEntry(updatedLoom.uid, updatedLoom)],
      ),
  );

  store.dispatch(
    SetCablesAndLooms(updatedCables, updatedLooms),
  );
}
