import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/containers/hoist_selectors.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/hoists/hoists.dart';

import 'package:sidekick/view_models/hoists_view_model.dart';

class HoistsContainer extends StatelessWidget {
  const HoistsContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, HoistsViewModel>(
      builder: (context, viewModel) {
        return Hoists(
          viewModel: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        final cablesByOutletId = selectCablesByOutletId(store);
        final hoistVmMap = mapHoistViewModels(
          store: store,
          cablesByOutletId: cablesByOutletId,
        );

        final selectedHoistChannelVmMap =
            mapSelectedHoistChannelViewModels(store, hoistVmMap);

        final hoistItems = selectLocationHoistItems(
            context: context, hoistViewModels: hoistVmMap, store: store);

        return HoistsViewModel(
            hoistItems: hoistItems,
            selectedHoistViewModels: Map<String, HoistViewModel>.fromEntries(
              store.state.navstate.selectedHoistIds
                  .map((id) => hoistVmMap[id])
                  .nonNulls
                  .map((vm) => MapEntry(vm.uid, vm)),
            ),
            onSelectedHoistsChanged: (type, items) =>
                store.dispatch(selectHoistOutlets(type, items)),
            onSelectedHoistChannelsChanged: (type, items) =>
                store.dispatch(selectHoistControllerChannels(type, items)),
            hoistControllers: selectHoistControllers(
                context: context,
                store: store,
                selectedHoistChannelViewModelMap: selectedHoistChannelVmMap,
                cablesByHoistId: cablesByOutletId),
            selectedHoistChannelViewModels: selectedHoistChannelVmMap,
            onAddMotorController: (wayNumber) =>
                store.dispatch(addHoistController(wayNumber)),
            onDeleteSelectedHoistChannels: () =>
                store.dispatch(deleteSelectedHoistChannels()),
            onAddLocationButtonPressed: () =>
                store.dispatch(addRiggingLocation(context)),
            onHoistReorder: (oldIndex, newIndex) =>
                store.dispatch(reorderHoists(
                  oldIndex,
                  newIndex,
                  hoistItems,
                  context,
                )));
      },
    );
  }
}
