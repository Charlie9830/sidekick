import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:sidekick/balancer/naive_balancer.dart';
import 'package:sidekick/excel/read_fixture_type_test_data.dart';
import 'package:sidekick/excel/read_fixtures_test_data.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/utils/get_multi_outlet_from_index.dart';
import 'package:sidekick/utils/get_multi_patch_from_index.dart';
import 'package:sidekick/utils/get_phase_from_index.dart';
import 'package:sidekick/utils/get_uid.dart';
import 'package:sidekick/utils/round_up_outlets_to_multi_break.dart';
import 'package:path/path.dart' as p;
import 'package:clipboard/clipboard.dart';

ThunkAction<AppState> copyPowerPatchToClipboard(BuildContext context) {
  return (Store<AppState> store) async {
    final String tab = String.fromCharCode(9);

    final buffer = StringBuffer();

    // Header Row
    buffer.writeln('LoomID${tab}CHL${tab}Fixture${tab}Fix. No.${tab}Location');

    FlutterClipboard.copy(buffer.toString());
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
    store.dispatch(SetPowerPatches([]));
    store.dispatch(SetPowerOutlets([]));
  };
}

ThunkAction<AppState> generatePatch() {
  return (Store<AppState> store) async {
    final fixtures = store.state.fixtureState.fixtures.values.toList();
    final balancer = NaiveBalancer();

    final powerPatchesByLocationId = balancer.generatePatches(
      fixtures: fixtures,
      maxAmpsPerCircuit: 16,
      maxSequenceBreak: store.state.fixtureState.maxSequenceBreak,
    );

    final multiOutlets = store.state.fixtureState.powerMultiOutlets.isNotEmpty
        ? store.state.fixtureState.powerMultiOutlets.values
        : powerPatchesByLocationId.entries.mapIndexed((index, entry) {
            final locationId = entry.key;
            final patchQty = entry.value.length;

            if (patchQty % 6 != 0) {
              throw "Something has gone wrong. PatchQty should be a multiple of 6, as we should have gap filled patches to a multiple of 6 by now.";
            }

            final desiredMultiQty = patchQty ~/ 6;

            final multiOutlets = List<PowerMultiOutletModel>.generate(
                desiredMultiQty,
                (multiIndex) => PowerMultiOutletModel(
                    uid: getUid(),
                    locationId: locationId,
                    name: PowerMultiOutletModel.getName(
                      location: store.state.fixtureState.locations[locationId]!,
                      multiNumber: multiIndex + 1,
                    )));

            return multiOutlets;
          }).flattened;

    final multiOutletsByLocationId =
        multiOutlets.groupListsBy((multiOutlet) => multiOutlet.locationId);

    final initialOutlets = powerPatchesByLocationId.entries
        .mapIndexed((index, entry) {
          final locationId = entry.key;
          final patches = entry.value;

          return patches.mapIndexed((index, patch) {
            return PowerOutletModel(
              uid: getUid(),
              child: patch,
              multiOutletId: multiOutletsByLocationId[locationId]!
                      .elementAtOrNull(((index + 1) / 6).floor())
                      ?.uid ??
                  '',
              multiPatch: getMultiPatchFromIndex(index),
              phase: getPhaseFromIndex(index),
              isSpare: false,
            );
          });
        })
        .flattened
        .toList();

    final outlets = balancer.assignToOutlets(
      patchesByLocationId: powerPatchesByLocationId,
      outlets: store.state.fixtureState.outlets.isNotEmpty
          ? store.state.fixtureState.outlets
          : initialOutlets,
      imbalanceTolerance: store.state.fixtureState.balanceTolerance,
    );

    store.dispatch(SetPowerOutlets(outlets.values.flattened.toList()));
    store.dispatch(
      SetPowerMultiOutlets(
        Map<String, PowerMultiOutletModel>.fromEntries(
          multiOutlets.map(
            (multiOutlet) => MapEntry(multiOutlet.uid, multiOutlet),
          ),
        ),
      ),
    );
  };
}

ThunkAction<AppState> addSpareOutlet(int index) {
  return (Store<AppState> store) async {
    final existingOutlets = store.state.fixtureState.outlets.toList();

    final selectedOutlet =
        store.state.fixtureState.outlets.elementAtOrNull(index);

    if (selectedOutlet == null) {
      return;
    }

    existingOutlets.insert(
        index,
        PowerOutletModel(
            uid: getUid(),
            isSpare: true,
            multiOutletId: selectedOutlet.multiOutletId,
            multiPatch: getMultiPatchFromIndex(index),
            phase: getPhaseFromIndex(index),
            child: PowerPatchModel.empty()));

    final balancer = NaiveBalancer();

    final patchesByLocationId = PowerOutletModel.getPatchesByLocationId(
        outlets: store.state.fixtureState.outlets,
        powerMultiOutlets: store.state.fixtureState.powerMultiOutlets);

    store.dispatch(
      SetPowerOutlets(
        balancer
            .assignToOutlets(
              patchesByLocationId: patchesByLocationId,
              outlets: _reIndexOutletPhases(
                  roundUpOutletsToNearestMultiBreak(existingOutlets)),
              imbalanceTolerance: store.state.fixtureState.balanceTolerance,
            )
            .values
            .flattened
            .toList(),
      ),
    );
  };
}

ThunkAction<AppState> deleteSpareOutlet(int index) {
  return (Store<AppState> store) async {
    final existingOutlets = store.state.fixtureState.outlets.toList();

    final outlet = existingOutlets.elementAtOrNull(index);

    if (outlet == null || outlet.isSpare == false) {
      return;
    }

    existingOutlets[index] = outlet.copyWith(isSpare: false);

    final patchesByLocationId = PowerOutletModel.getPatchesByLocationId(
        outlets: store.state.fixtureState.outlets,
        powerMultiOutlets: store.state.fixtureState.powerMultiOutlets);

    store.dispatch(
      SetPowerOutlets(
        NaiveBalancer()
            .assignToOutlets(
              patchesByLocationId: patchesByLocationId,
              outlets: _reIndexOutletPhases(
                // Heal the list back to the nearest upper multi break.
                roundUpOutletsToNearestMultiBreak(
                  // Trim off any empty outlets on the end of the list.
                  _trimTrailingEmptyOutlets(existingOutlets),
                ),
              ),
              imbalanceTolerance: store.state.fixtureState.balanceTolerance,
            )
            .values
            .flattened
            .toList(),
      ),
    );
  };
}

List<PowerOutletModel> _reIndexOutletPhases(
    Iterable<PowerOutletModel> outlets) {
  return outlets
      .mapIndexed((index, outlet) => outlet.copyWith(
          multiPatch: getMultiPatchFromIndex(index),
          phase: getPhaseFromIndex(index)))
      .toList();
}

List<PowerOutletModel> _trimTrailingEmptyOutlets(
    List<PowerOutletModel> existing) {
  final lastUsedOutlet =
      existing.lastWhereOrNull((element) => element.child.isNotEmpty);

  if (lastUsedOutlet == null) {
    return existing.toList();
  }

  final lastUsedIndex = existing.indexOf(lastUsedOutlet);

  return existing.sublist(0, lastUsedIndex + 1);
}
