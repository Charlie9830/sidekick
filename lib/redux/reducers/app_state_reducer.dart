import 'package:sidekick/redux/reducers/fixture_state_reducer.dart';
import 'package:sidekick/redux/reducers/navigation_state_reducer.dart';
import 'package:sidekick/redux/state/app_state.dart';

AppState appStateReducer(AppState state, dynamic action) {
  return state.copyWith(
    navstate: navStateReducer(state.navstate, action),
    fixtureState: fixtureStateReducer(state.fixtureState, action),
  );
}
