import 'package:sidekick/redux/reducers/diffing_state_reducer.dart';
import 'package:sidekick/redux/reducers/file_state_reducer.dart';
import 'package:sidekick/redux/reducers/fixture_state_reducer.dart';
import 'package:sidekick/redux/reducers/navigation_state_reducer.dart';
import 'package:sidekick/redux/state/app_state.dart';

AppState appStateReducer(AppState state, dynamic action) {
  return state.copyWith(
    navstate: navStateReducer(state.navstate, action),
    fixtureState: fixtureStateReducer(state.fixtureState, action),
    fileState: fileStateReducer(state.fileState, action),
    diffingState: diffingStateReducer(state.diffingState, action),
  );
}
