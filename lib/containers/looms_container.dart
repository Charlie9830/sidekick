import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/data_selectors/select_cable_and_loom_rows.dart';
import 'package:sidekick/data_selectors/select_can_delete_selected_cables.dart';
import 'package:sidekick/data_selectors/select_can_remove_selected_cables_from_loom.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/looms/looms.dart';
import 'package:sidekick/view_models/looms_view_model.dart';

class LoomsContainer extends StatelessWidget {
  const LoomsContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, LoomsViewModel>(
        builder: (context, viewModel) {
      return Looms(
        vm: viewModel,
      );
    }, converter: (Store<AppState> store) {
      final selectedCables = store.state.navstate.selectedCableIds
          .map((id) => store.state.fixtureState.cables[id])
          .nonNulls
          .toList();

      return LoomsViewModel(
          selectedCableIds: store.state.navstate.selectedCableIds,
          selectCables: (ids) => store.dispatch(setSelectedCableIds(ids)),
          onGenerateLoomsButtonPressed: () => {},
          rowVms: selectCableAndLoomRows(
            context: context,
            fixtureState: store.state.fixtureState,
            navState: store.state.navstate,
            dispatch: store.dispatch,
          ),
          onCombineCablesIntoNewLoomButtonPressed: (type) => store.dispatch(
              combineCablesIntoNewLoom(
                  context, store.state.navstate.selectedCableIds, type)),
          onCreateExtensionFromSelection: () => store.dispatch(
              createExtensionFromSelection(
                  context, store.state.navstate.selectedCableIds)),
          onCombineDmxIntoSneak: () => store.dispatch(combineDmxCablesIntoSneak(
              context, store.state.navstate.selectedCableIds)),
          onSplitSneakIntoDmx: () => store.dispatch(
                splitSneakIntoDmx(
                    context, store.state.navstate.selectedCableIds),
              ),
          onDeleteSelectedCables: selectCanDeleteSelectedCables(selectedCables)
              ? () => store.dispatch(deleteSelectedCables(context))
              : null,
          onRemoveSelectedCablesFromLoom:
              selectCanRemoveSelectedCablesFromLoom(selectedCables)
                  ? () => store.dispatch(removeSelectedCablesFromLoom(context))
                  : null,
          onDefaultPowerMultiChanged: (value) =>
              store.dispatch(SetDefaultPowerMulti(value!)),
          defaultPowerMulti: store.state.fixtureState.defaultPowerMulti,
          onChangeExistingPowerMultiTypes: () =>
              store.dispatch(changeExistingPowerMultisToDefault(context)));
    });
  }
}
