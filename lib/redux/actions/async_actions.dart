import 'dart:collection';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:sidekick/balancer/naive_balancer.dart';
import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/classes/universe_span.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/excel/create_color_lookup_sheet.dart';
import 'package:sidekick/excel/create_data_multi_sheet.dart';
import 'package:sidekick/excel/create_data_patch_sheet.dart';
import 'package:sidekick/excel/create_fixture_type_validation_sheet.dart';
import 'package:sidekick/excel/create_power_patch_sheet.dart';
import 'package:sidekick/excel/read_fixture_type_test_data.dart';
import 'package:sidekick/excel/read_fixtures_test_data.dart';
import 'package:sidekick/file_type_groups.dart';
import 'package:sidekick/generic_dialog/show_generic_dialog.dart';
import 'package:sidekick/global_keys.dart';
import 'package:sidekick/import_merging/merge_fixtures.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/import_settings_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:path/path.dart' as p;
import 'package:sidekick/screens/sequencer_dialog/sequencer_dialog.dart';
import 'package:sidekick/serialization/project_file_model.dart';
import 'package:sidekick/serialization/serialize_project_file.dart';
import 'package:sidekick/snack_bars/file_save_success_snack_bar.dart';
import 'package:sidekick/utils/get_uid.dart';

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

    final fixtureTypes = await readFixtureTypeTestData(filePath);

    final (fixtures, locations) =
        await readFixturesTestData(path: filePath, fixtureTypes: fixtureTypes);

    if (settings.mergeWithExisting == false) {
      store.dispatch(ResetFixtureState());
      store.dispatch(SetFixtures(fixtures));
      store.dispatch(SetLocations(locations));
    } else {
      store.dispatch(SetFixtures(mergeFixtures(
          existing: store.state.fixtureState.fixtures,
          incoming: fixtures,
          settings: settings)));
    }
  };
}

String getTestDataPath() {
  const String testDataDirectory = './test_data/';
  const String testFileName = 'fixtures.xlsx';
  final String testDataPath = p.join(testDataDirectory, testFileName);
  return testDataPath;
}

ThunkAction<AppState> generateLooms() {
  return (Store<AppState> store) async {
    final powerOnlyLooms = generatePowerOnlyLooms(
        locations: store.state.fixtureState.locations.values,
        powerMultis: store.state.fixtureState.powerMultiOutlets.values);

    final withDataCables = appendDataCables(
        existing: powerOnlyLooms,
        dataMultis: store.state.fixtureState.dataMultis.values,
        dataPatches: store.state.fixtureState.dataPatches.values);

    store.dispatch(SetLooms(Map<String, LoomModel>.fromEntries(
        withDataCables.map((loom) => MapEntry(loom.uid, loom)))));
  };
}

List<LoomModel> appendDataCables(
    {required List<LoomModel> existing,
    required Iterable<DataMultiModel> dataMultis,
    required Iterable<DataPatchModel> dataPatches}) {
  return existing.map((loom) {
    final associatedDataMultis =
        dataMultis.where((multi) => multi.locationId == loom.locationId);
    final associatedDataPatches = dataPatches.where((patch) =>
        patch.multiId.isEmpty && patch.locationId == loom.locationId);

    return loom.copyWith(children: [
      ...loom.children,
      ...associatedDataMultis.map((multi) => CableModel(
            uid: getUid(),
            type: CableType.sneak,
            label: multi.name,
            parentId: multi.uid,
          )),
      ...associatedDataPatches.map((patch) => CableModel(
            uid: getUid(),
            type: CableType.dmx,
            label: patch.name,
            parentId: patch.uid,
          )),
    ]);
  }).toList();
}

List<LoomModel> generatePowerOnlyLooms(
    {required Iterable<LocationModel> locations,
    required Iterable<PowerMultiOutletModel> powerMultis}) {
  return locations
      .map((location) {
        final associatedMultis =
            powerMultis.where((multi) => multi.locationId == location.uid);

        return associatedMultis.slices(5).map((slice) {
          return LoomModel(
            uid: getUid(),
            locationId: location.uid,
            children: [
              ...associatedMultis.map((multi) => CableModel(
                    uid: getUid(),
                    type: CableType.socapex,
                    parentId: multi.uid,
                  )),
            ],
          );
        });
      })
      .flattened
      .toList();
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
    updateAssociatedDataMultis(store, locationId, updatedLocation);
  };
}

ThunkAction<AppState> rangeSelectFixtures(String startUid, String endUid) {
  return (Store<AppState> store) async {
    final fixtures = store.state.fixtureState.fixtures.values.toList();
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

    store.dispatch(SetSelectedFixtureIds(ids));
  };
}

ThunkAction<AppState> setSequenceNumbers(BuildContext context) {
  return (Store<AppState> store) async {
    final selectedFixtures = store.state.fixtureState.fixtures.values
        .where((fixture) =>
            store.state.navstate.selectedFixtureIds.contains(fixture.uid))
        .toList();

    final result = await showDialog(
      context: context,
      builder: (context) => SequencerDialog(fixtures: selectedFixtures),
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
        UniverseSpan.createSpans(fixtures),
      ),
    );

    final List<DataPatchModel> patches = [];
    final List<DataMultiModel> multis = [];

    for (final entry in spansByLocationId.entries) {
      final locationId = entry.key;
      final spans = entry.value;

      final location = store.state.fixtureState.locations[locationId];

      final powerMultiCount = store.state.fixtureState.powerMultiOutlets.values
          .where((powerMulti) => powerMulti.locationId == locationId)
          .length;

      if (spans.length <= 2 && powerMultiCount <= 2) {
        // Can be 2 Singles.
        patches.addAll(
          spans.mapIndexed(
            (index, span) {
              final wayNumber = index + 1;
              return DataPatchModel(
                uid: getUid(),
                locationId: locationId,
                number: wayNumber,
                multiId: '',
                universe: span.universe,
                name: location?.getPrefixedDataPatch(wayNumber) ?? '',
                startsAtFixtureId: span.startsAt.fid,
                endsAtFixtureId: span.endsAt?.fid ?? 0,
                fixtureIds: span.fixtureIds,
              );
            },
          ),
        );
      } else {
        final slices = spans.slices(4);

        for (final (index, slice) in slices.indexed) {
          final wayNumber = index + 1;
          final parentMulti = DataMultiModel(
            uid: getUid(),
            locationId: locationId,
            name: location?.getPrefixedDataMultiPatch(wayNumber) ?? '',
            number: wayNumber,
          );

          multis.add(parentMulti);

          patches.addAll(
            slice.mapIndexed(
              (index, span) {
                final wayNumber = index + 1;
                return DataPatchModel(
                  uid: getUid(),
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
                    uid: getUid(),
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
            .map((outlet) => outlet.child.fixtures.map(
                  (fixture) => MapEntry(fixture.uid, outlet),
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
        locations: store.state.fixtureState.locations);

    createColorLookupSheet(
      excel: excel,
      powerMultis: store.state.fixtureState.powerMultiOutlets,
      locations: store.state.fixtureState.locations,
    );

    createFixtureTypeValidationSheet(
        excel: excel, outlets: store.state.fixtureState.outlets);

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
      fixtures: fixtures,
      multiOutlets: store.state.fixtureState.powerMultiOutlets.values.toList(),
      maxSequenceBreak: store.state.fixtureState.maxSequenceBreak,
    );

    final balancedMultiOutlets = _balanceOutlets(unbalancedMultiOutlets,
        balancer, store.state.fixtureState.balanceTolerance);

    _updatePowerMultisAndOutlets(store, balancedMultiOutlets);
  };
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

Map<PowerMultiOutletModel, List<PowerOutletModel>> _balanceOutlets(
    Map<PowerMultiOutletModel, List<PowerOutletModel>> unbalancedMultiOutlets,
    NaiveBalancer balancer,
    double balanceTolerance) {
  PhaseLoad currentLoad = PhaseLoad(0, 0, 0);

  return unbalancedMultiOutlets.map((multiOutlet, outlets) {
    final result = balancer.balanceOutlets(
      outlets,
      balanceTolerance: balanceTolerance,
      initialLoad: currentLoad,
    );

    currentLoad = result.load;

    return MapEntry(multiOutlet, result.outlets);
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

      if (location != null) {
        return MapEntry(
          outlet.copyWith(name: location.getPrefixedPowerMulti(outlet.number)),
          entry.value,
        );
      }
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
    fixtures: store.state.fixtureState.fixtures.values.toList(),
    multiOutlets: existingMultiOutlets.values.toList(),
    maxSequenceBreak: store.state.fixtureState.maxSequenceBreak,
  );

  final balancedMultiOutlets = _balanceOutlets(
    unbalancedMultiOutlets,
    balancer,
    store.state.fixtureState.balanceTolerance,
  );

  _updatePowerMultisAndOutlets(store, balancedMultiOutlets);
}

void updateAssociatedPowerMultis(
    Store<AppState> store, String locationId, LocationModel updatedLocation) {
  final associatedPowerMultis = store
      .state.fixtureState.powerMultiOutlets.values
      .where((multi) => multi.locationId == locationId);

  if (associatedPowerMultis.isEmpty) {
    return;
  }

  final updatedPowerMultis = associatedPowerMultis.map((existing) => existing
      .copyWith(name: updatedLocation.getPrefixedPowerMulti(existing.number)));

  store.dispatch(SetPowerMultiOutlets(Map<String, PowerMultiOutletModel>.from(
      store.state.fixtureState.powerMultiOutlets)
    ..addEntries(
        updatedPowerMultis.map((multi) => MapEntry(multi.uid, multi)))));
}

void updateAssociatedDataMultis(
    Store<AppState> store, String locationId, LocationModel updatedLocation) {
  final associatedDataMultis = store.state.fixtureState.dataMultis.values
      .where((multi) => multi.locationId == locationId);

  if (associatedDataMultis.isEmpty) {
    return;
  }

  final updatedDataMultis = associatedDataMultis.map((existing) =>
      existing.copyWith(
          name: updatedLocation.getPrefixedDataMultiPatch(existing.number)));

  store.dispatch(SetDataMultis(
      Map<String, DataMultiModel>.from(store.state.fixtureState.dataMultis)
        ..addEntries(
            updatedDataMultis.map((multi) => MapEntry(multi.uid, multi)))));

  void updateAssociatedDataPatches(
      Store<AppState> store, String locationId, LocationModel updatedLocation) {
    final associatedDataPatches = store.state.fixtureState.dataPatches.values
        .where((multi) => multi.locationId == locationId);

    if (associatedDataPatches.isEmpty) {
      return;
    }

    final updatedDataPatches = associatedDataPatches.map((existing) => existing
        .copyWith(name: updatedLocation.getPrefixedDataPatch(existing.number)));

    store.dispatch(SetDataPatches(
        Map<String, DataPatchModel>.from(store.state.fixtureState.dataPatches)
          ..addEntries(
              updatedDataPatches.map((multi) => MapEntry(multi.uid, multi)))));
  }
}
