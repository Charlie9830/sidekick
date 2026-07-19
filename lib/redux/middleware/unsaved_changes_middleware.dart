import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';

/// Flags the project as dirty whenever an action changes [AppState.fixtureState].
///
/// Relies on a property of the reducer chain: `fixtureStateReducer` returns the
/// *identical* [FixtureState] instance when no sub-reducer handles the action,
/// and `appStateReducer` passes that reference through `copyWith` unchanged. So
/// an [identical] comparison across `next(action)` is a cheap "did project
/// content change?" signal that needs no action allowlist as new actions are
/// added.
///
/// Register on `appStore` only — `diffAppStore` loads comparison files into its
/// fixture state and must never dirty the live project.
void unsavedChangesMiddleware(
  Store<AppState> store,
  dynamic action,
  NextDispatcher next,
) {
  final before = store.state.fixtureState;
  next(action);
  final after = store.state.fixtureState;

  if (identical(before, after)) {
    return;
  }

  // These replace fixture state wholesale to establish a clean baseline; the
  // reducer has already cleared the flag for them.
  if (action is NewProject || action is OpenProject) {
    return;
  }

  if (!store.state.fileState.hasUnsavedChanges) {
    store.dispatch(SetHasUnsavedChanges(true));
  }
}
