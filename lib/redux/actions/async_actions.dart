import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:sidekick/balancer/naive_balancer.dart';
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

ThunkAction<AppState> copyPowerPatchToClipboard(BuildContext context) {
  return (Store<AppState> store) async {
    final String tab = String.fromCharCode(9);

    final buffer = StringBuffer();

    // Header Row
    buffer.writeln('LoomID${tab}CHL${tab}Fixture${tab}Fix. No.${tab}Location');

    FlutterClipboard.copy(buffer.toString());
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
  final balancedMultiOutlets =
      unbalancedMultiOutlets.map((multiOutlet, outlets) {
    final result = balancer.balanceOutlets(
      outlets,
      balanceTolerance: balanceTolerance,
    );

    return MapEntry(multiOutlet, result.outlets);
  });
  return balancedMultiOutlets;
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