import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/navigation_state.dart';

NavigationState navStateReducer(NavigationState state, dynamic a) {
  if (a is NewProject || a is OpenProject) {
    return NavigationState.initial();
  }

  if (a is SetSelectedFixtureIds) {
    return state.copyWith(selectedFixtureIds: a.ids);
  }

  if (a is SetSelectedMultiOutlet) {
    return state.copyWith(selectedMultiOutlet: a.uid);
  }

  return state;
}
