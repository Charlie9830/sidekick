import 'dart:io';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:sidekick/balancer/naive_balancer.dart';
import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/classes/universe_span.dart';
import 'package:sidekick/excel/create_color_lookup_sheet.dart';
import 'package:sidekick/excel/create_fixture_type_validation_sheet.dart';
import 'package:sidekick/excel/create_power_patch_sheet.dart';
import 'package:sidekick/excel/read_fixture_type_test_data.dart';
import 'package:sidekick/excel/read_fixtures_test_data.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:path/path.dart' as p;
import 'package:clipboard/clipboard.dart';
import 'package:sidekick/screens/sequencer_dialog/sequencer_dialog.dart';
import 'package:sidekick/utils/get_uid.dart';

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

ThunkAction<AppState> initializeApp() {
  return (Store<AppState> store) async {
    const String testDataDirectory = './test_data/';
    const String testFileName = 'fixtures.xlsx';
    final String testDataPath = p.join(testDataDirectory, testFileName);

    final fixtureTypes = await readFixtureTypeTestData(testDataPath);

    final (fixtures, locations) = await readFixturesTestData(
        path: testDataPath, fixtureTypes: fixtureTypes);

    store.dispatch(SetFixtures(fixtures));
    store.dispatch(SetLocations(locations));
    store.dispatch(SetPowerOutlets([]));
    store.dispatch(SetPowerMultiOutlets({}));
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
            (index, span) => DataPatchModel(
              uid: getUid(),
              locationId: locationId,
              multiId: '',
              universe: span.universe,
              name: location?.getPrefixedDataPatch(span.universe, index + 1) ??
                  '',
              startsAtFixtureId: span.startsAt.fid,
              endsAtFixtureId: span.endsAt?.fid ?? 0,
              fixtureIds: span.fixtureIds,
            ),
          ),
        );
      } else {
        final slices = spans.slices(4);

        for (final (index, slice) in slices.indexed) {
          final parentMulti = DataMultiModel(
            uid: getUid(),
            locationId: locationId,
            name: location?.getPrefixedDataMultiPatch(index + 1) ?? '',
          );

          multis.add(parentMulti);

          patches.addAll(
            slice.mapIndexed(
              (index, span) => DataPatchModel(
                uid: getUid(),
                locationId: locationId,
                multiId: parentMulti.uid,
                universe: span.universe,
                startsAtFixtureId: span.startsAt.fid,
                endsAtFixtureId: span.endsAt?.fid ?? 0,
                name: location?.getPrefixedDataPatch(span.universe, index + 1,
                        parentMultiName: parentMulti.name) ??
                    '',
                fixtureIds: span.fixtureIds,
              ),
            ),
          );

          // Add Spares if needed
          if (slice.length < 4) {
            final int diff = 4 - slice.length;
            patches.addAll(
              List<DataPatchModel>.generate(
                diff,
                (index) => DataPatchModel(
                  uid: getUid(),
                  locationId: locationId,
                  multiId: parentMulti.uid,
                  universe: 0,
                  name: 'SP ${index + 1}',
                  startsAtFixtureId: 0,
                  endsAtFixtureId: 0,
                  isSpare: true,
                  fixtureIds: [],
                ),
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
        powerMulti: multiOutlet.name,
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
    Map<String, LocationModel> locations) {
  final multiOutletsByLocationId =
      multiOutlets.groupListsBy((outlet) => outlet.locationId);

  return multiOutletsByLocationId.entries
      .map((entry) {
        final locationId = entry.key;
        final multiOutlets = entry.value;

        LocationModel? location = locations[locationId];
        return multiOutlets.mapIndexed((index, outlet) => outlet.copyWith(
            name: location?.getPrefixedPowerMulti(index + 1) ?? ''));
      })
      .flattened
      .toList();
}

void _updatePowerMultisAndOutlets(Store<AppState> store,
    Map<PowerMultiOutletModel, List<PowerOutletModel>> balancedMultiOutlets) {
  store.dispatch(
      SetPowerOutlets(balancedMultiOutlets.values.flattened.toList()));
  store.dispatch(
    SetPowerMultiOutlets(
      Map<String, PowerMultiOutletModel>.fromEntries(_updateMultiOutletNames(
              balancedMultiOutlets.keys, store.state.fixtureState.locations)
          .map((multiOutlet) => MapEntry(multiOutlet.uid, multiOutlet))),
    ),
  );
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
