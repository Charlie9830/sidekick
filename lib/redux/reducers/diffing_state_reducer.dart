import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/diffing_state.dart';

DiffingState diffingStateReducer(DiffingState state, dynamic action) {
  if (action is SetDiffingUnions) {
    return state.copyWith(
      cablesUnion: action.cables,
    );
  }

  if (action is SetDiffingOriginalSource) {
    return state.copyWith(
      original: action.value,
    );
  }
  return state;
}
