import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/navigation_state.dart';

NavigationState navStateReducer(NavigationState state, dynamic a) {
  if (a is SetSelectedLoomOutlets) {
    return state.copyWith(selectedLoomOutlets: a.value);
  }

  if (a is SetLoomsDraggingState) {
    return state.copyWith(loomsDraggingState: a.value);
  }

  if (a is SetSelectedDiffingTab) {
    return state.copyWith(selectedDiffingTab: a.value);
  }

  if (a is SetSelectedRawPatchRow) {
    return state.copyWith(selectedRawPatchRow: a.value);
  }

  if (a is SetActiveImportManagerStep) {
    return state.copyWith(activeImportManagerStep: a.value);
  }

  if (a is NewProject || a is OpenProject) {
    return NavigationState.initial();
  }

  if (a is SetOpenAfterExport) {
    return state.copyWith(openAfterExport: a.value);
  }

  if (a is SetSelectedCableIds) {
    return state.copyWith(selectedCableIds: a.ids);
  }

  if (a is SetSelectedFixtureIds) {
    return state.copyWith(selectedFixtureIds: a.ids);
  }

  if (a is SetSelectedMultiOutlet) {
    return state.copyWith(selectedMultiOutlet: a.uid);
  }

  if (a is SetShowAllFixtureTypes) {
    return state.copyWith(showAllFixtureTypes: a.value);
  }

  return state;
}
