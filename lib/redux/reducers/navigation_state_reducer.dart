import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/navigation_state.dart';

NavigationState navStateReducer(NavigationState state, dynamic a) {
  if (a is SetSelectedPowerMultiOutletIds) {
    return state.copyWith(
      selectedPowerMultiOutletIds: a.value,
    );
  }

  if (a is SetSelectedPowerMultiOutletIds) {
    return state.copyWith(
      selectedPowerMultiChannelIds: a.value,
    );
  }

  if (a is RemoveLocation) {
    return state.copyWith(
      selectedCableIds: {},
      selectedHoistChannelIds: {},
      selectedHoistIds: {},
    );
  }

  if (a is SetImportedFixtureData) {
    return state.copyWith(
        importManagerStep: const NavigationState.initial().importManagerStep);
  }

  if (a is SetSelectedHoistOutlets) {
    return state.copyWith(
      selectedHoistIds: a.value,
      selectedHoistChannelIds: {},
    );
  }

  if (a is AppendSelectedHoistChannelId) {
    return state.copyWith(selectedHoistChannelIds: {
      ...state.selectedHoistChannelIds,
      a.value,
    });
  }

  if (a is SetSelectedHoistChannelIds) {
    return state.copyWith(
      selectedHoistChannelIds: a.value,
      selectedHoistIds: {},
    );
  }

  if (a is SetSelectedLoomOutlets) {
    return state.copyWith(
      selectedLoomOutlets: a.value,
      selectedCableIds: const {},
    );
  }

  if (a is SetIsAvailabilityDrawerOpen) {
    return state.copyWith(isAvailabilityDrawerOpen: a.value);
  }

  if (a is SetLoomsDraggingState) {
    return state.copyWith(loomsDraggingState: a.value);
  }

  if (a is SetSelectedDiffingTab) {
    return state.copyWith(selectedDiffingTab: a.value);
  }

  if (a is SetImportManagerStep) {
    return state.copyWith(importManagerStep: a.value);
  }

  if (a is NewProject || a is OpenProject) {
    return const NavigationState.initial();
  }

  if (a is SetOpenAfterExport) {
    return state.copyWith(openAfterExport: a.value);
  }

  if (a is SetSelectedCableIds) {
    return state
        .copyWith(selectedCableIds: a.ids, selectedLoomOutlets: const {});
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
