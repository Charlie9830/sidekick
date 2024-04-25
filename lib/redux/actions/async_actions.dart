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
  };
}

ThunkAction<AppState> generatePatch() {
  return (Store<AppState> store) async {
    final fixtures = store.state.fixtureState.fixtures.values.toList();
    final balancer = NaiveBalancer();
    final powerPatches =
        balancer.generatePatches(fixtures: fixtures, maxAmpsPerCircuit: 16);

    final initialOutlets = List<PowerOutletModel>.generate(
        96,
        (index) => PowerOutletModel(
              uid: getUid(),
              phase: getPhaseFromIndex(index),
              child: PowerPatchModel.empty(),
            ));

    final outlets = balancer.assignToOutlets(powerPatches, initialOutlets);

    store.dispatch(SetPowerOutlets(outlets));
  };
}
