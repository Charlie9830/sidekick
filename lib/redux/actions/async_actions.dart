import 'package:collection/collection.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:sidekick/balancer/naive_balancer.dart';
import 'package:sidekick/excel/read_fixture_type_test_data.dart';
import 'package:sidekick/excel/read_fixtures_test_data.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_patch_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/utils/get_phase_from_index.dart';
import 'package:sidekick/utils/get_uid.dart';

ThunkAction<AppState> initializeApp() {
  return (Store<AppState> store) async {
    const String testDataPath = './test_data/fixtures.xlsx';

    final fixtureTypes = await readFixtureTypeTestData(testDataPath);
    final fixtures = await readFixturesTestData(
        path: testDataPath, fixtureTypes: fixtureTypes);

    store.dispatch(SetFixtures(fixtures));
    store.dispatch(SetPowerPatches([]));
    store.dispatch(SetPowerOutlets([]));
  };
}

ThunkAction<AppState> generatePatch() {
  return (Store<AppState> store) async {
    final fixtures = store.state.fixtureState.fixtures.values.toList();
    final balancer = NaiveBalancer();
    final powerPatches = balancer.generatePatches(
        fixtures: fixtures,
        maxAmpsPerCircuit: 16,
        maxSequenceBreak: store.state.fixtureState.maxSequenceBreak);

    final initialOutlets = powerPatches
        .mapIndexed((index, patch) => PowerOutletModel(
              uid: getUid(),
              child: patch,
              phase: getPhaseFromIndex(index),
              isSpare: false,
            ))
        .toList();

    final outlets = balancer.assignToOutlets(
      patches: powerPatches,
      outlets: store.state.fixtureState.outlets.isNotEmpty
          ? store.state.fixtureState.outlets
          : initialOutlets,
      imbalanceTolerance: store.state.fixtureState.balanceTolerance,
    );

    store.dispatch(SetPowerOutlets(outlets));
  };
}

ThunkAction<AppState> addSpareOutlet(int index) {
  return (Store<AppState> store) async {
    final existingOutlets = store.state.fixtureState.outlets.toList();
    existingOutlets.insert(
        index,
        PowerOutletModel(
            uid: getUid(),
            isSpare: true,
            phase: getPhaseFromIndex(index),
            child: PowerPatchModel.empty()));

    final balancer = NaiveBalancer();

    store.dispatch(
      SetPowerOutlets(
        balancer.assignToOutlets(
          patches: store.state.fixtureState.patches,
          outlets: _reIndexOutletPhases(existingOutlets),
          imbalanceTolerance: store.state.fixtureState.balanceTolerance,
        ),
      ),
    );
  };
}

ThunkAction<AppState> deleteSpareOutlet(int index) {
  return (Store<AppState> store) async {
    final existingOutlets = store.state.fixtureState.outlets.toList();

    if (existingOutlets.elementAtOrNull(index) == null ||
        existingOutlets[index].isSpare == false) {
      return;
    }

    existingOutlets.removeAt(index);
    store.dispatch(
      SetPowerOutlets(
        NaiveBalancer().assignToOutlets(
          patches: store.state.fixtureState.patches,
          outlets: _reIndexOutletPhases(existingOutlets),
          imbalanceTolerance: store.state.fixtureState.balanceTolerance,
        ),
      ),
    );
  };
}

List<PowerOutletModel> _reIndexOutletPhases(
    Iterable<PowerOutletModel> outlets) {
  return outlets
      .mapIndexed(
          (index, outlet) => outlet.copyWith(phase: getPhaseFromIndex(index)))
      .toList();
}
