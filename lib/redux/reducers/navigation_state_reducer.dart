import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/navigation_state.dart';

NavigationState navStateReducer(NavigationState state, dynamic action) {
  return switch (action) {
    SetSelectedMultiOutlet a => state.copyWith(selectedMultiOutlet: a.uid),
    _ => state
  };
}
