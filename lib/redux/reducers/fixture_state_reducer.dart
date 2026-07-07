import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/redux/reducers/fixture_state/file_reducer.dart';
import 'package:sidekick/redux/reducers/fixture_state/fixture_reducer.dart';
import 'package:sidekick/redux/reducers/fixture_state/hoist_reducer.dart';
import 'package:sidekick/redux/reducers/fixture_state/location_reducer.dart';
import 'package:sidekick/redux/reducers/fixture_state/loom_reducer.dart';
import 'package:sidekick/redux/reducers/fixture_state/outlet_reducer.dart';
import 'package:sidekick/redux/reducers/fixture_state/rack_reducer.dart';

FixtureState fixtureStateReducer(FixtureState state, dynamic a) {
  return reduceFileActions(state, a) ??
      reduceFixtureActions(state, a) ??
      reduceHoistActions(state, a) ??
      reduceLocationActions(state, a) ??
      reduceLoomActions(state, a) ??
      reduceOutletActions(state, a) ??
      reduceRackActions(state, a) ??
      state;
}
