import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/containers/hoist_selectors.dart';
import 'package:sidekick/containers/select_power_patch_view_models.dart';
import 'package:sidekick/data_selectors/select_cable_qtys.dart';
import 'package:sidekick/data_selectors/select_fixture_view_models.dart';
import 'package:sidekick/data_selectors/select_loom_view_models.dart';
import 'package:sidekick/diffing/compute_diffs.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/diffing/diffing_screen.dart';
import 'package:sidekick/view_models/diff_app_state_view_model.dart';
import 'package:sidekick/view_models/diffing_screen_view_model.dart';
import 'package:path/path.dart' as p;

class DiffingScreenContainer extends StatelessWidget {
  const DiffingScreenContainer({super.key});

  @override
  Widget build(BuildContext context) {
    // Diffing reads from two separate Redux stores:
    //   * the outer connector reads the `DiffAppState` store (the comparison
    //     file that was loaded to diff against) and exposes it as `originalVm`,
    //     a snapshot of all the *original* view models;
    //   * the inner connector reads the live `AppState` store (the *current*
    //     project) and diffs each current selector against the matching
    //     `originalVm.original*` field to build the screen view model.
    return StoreConnector<DiffAppState, DiffAppStateViewModel>(
      builder: (context, originalVm) {
        return StoreConnector<AppState, DiffingScreenViewModel>(
          builder: (context, viewModel) {
            return DiffingScreen(viewModel: viewModel);
          },
          converter: (store) =>
              _buildScreenViewModel(context, store, originalVm),
        );
      },
      converter: (Store<DiffAppState> diffStore) {
        final cablesByOutletId = selectCablesByOutletId(diffStore);
        final originalHoistVms = mapHoistViewModels(
          store: diffStore,
          cablesByOutletId: cablesByOutletId,
        );
        return DiffAppStateViewModel(
          originalLoomViewModels: selectLoomViewModels(diffStore).toModelMap(),
          onSelectFileForCompareButtonPressed: ({String? path}) =>
              diffStore.dispatch(openProjectFile(context, false, path: path)),
          originalPatchViewModels: selectPowerPatchViewModels(
            context,
            diffStore,
          ).toModelMap(),
          originalFixtureViewModels: selectFixtureRowViewModels(
            diffStore,
          ).toModelMap(),
          originalHoistControllerViewModels: selectHoistControllers(
            store: diffStore,
            selectedHoistChannelViewModelMap: {},
            hoistViewModels: originalHoistVms,
            isDiffing: true,
          ).toModelMap(),
          hoistViewModels: originalHoistVms,
          originalCableQtysByLocationId: selectCableQtysByLocationId(
            buildCableGraphForState(diffStore.state),
          ),
          originalLocationNames: _selectLocationNames(diffStore.state),
        );
      },
    );
  }

  /// Diffs the live [store] against the comparison-file snapshot [originalVm]
  /// to build the view model consumed by [DiffingScreen].
  DiffingScreenViewModel _buildScreenViewModel(
    BuildContext context,
    Store<AppState> store,
    DiffAppStateViewModel originalVm,
  ) {
    final cablesByOutletId = selectCablesByOutletId(store);
    final currentHoistVms = mapHoistViewModels(
      store: store,
      cablesByOutletId: cablesByOutletId,
    );

    return DiffingScreenViewModel(
      onFileSelectedForCompare: ({String? path}) {
        originalVm.onSelectFileForCompareButtonPressed(path: path);
      },
      initialDirectory: store.state.fileState.comparisonFilePath.isEmpty
          ? store.state.fileState.lastUsedProjectDirectory
          : p.dirname(store.state.fileState.comparisonFilePath),
      comparisonFilePath: store.state.fileState.comparisonFilePath,
      patchItemVms: computePatchDiffs(
        currentPatchVms: selectPowerPatchViewModels(
          context,
          store,
        ).toModelMap(),
        originalPatchVms: originalVm.originalPatchViewModels,
      ),
      loomItemVms: computeLoomDiffs(
        currentLoomVms: selectLoomViewModels(store).toModelMap(),
        originalLoomVms: originalVm.originalLoomViewModels,
      ),
      fixtureItemVms: computeFixtureDiffs(
        currentFixtureVms: selectFixtureRowViewModels(store).toModelMap(),
        originalFixtureVms: originalVm.originalFixtureViewModels,
      ),
      hoistControllerVms: computeHoistControllerDiffs(
        currentControllerVms: selectHoistControllers(
          store: store,
          selectedHoistChannelViewModelMap: {},
          hoistViewModels: currentHoistVms,
          isDiffing: true,
        ).toModelMap(),
        originalControllerVms: originalVm.originalHoistControllerViewModels,
        currentHoistVms: currentHoistVms,
        originalHoistVms: originalVm.hoistViewModels,
      ),
      cableQtyItemVms: computeCableQtyDiffs(
        currentQtys: selectCableQtysByLocationId(
          buildCableGraphForState(store.state),
        ),
        originalQtys: originalVm.originalCableQtysByLocationId,
        currentLocationNames: _selectLocationNames(store.state),
        originalLocationNames: originalVm.originalLocationNames,
      ),
      onTabSelected: (index) => store.dispatch(SetSelectedDiffingTab(index)),
      selectedTab: store.state.navstate.selectedDiffingTab,
    );
  }

  /// Maps every location uid in [state] to its display name.
  Map<String, String> _selectLocationNames(AppState state) => {
    for (final location in state.fixtureState.locations.values)
      location.uid: location.name,
  };
}
