import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/containers/hoist_selectors.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/hoists/hoist_item.dart';
import 'package:sidekick/screens/hoists/hoists.dart';
import 'package:sidekick/slotted_list/attempt2.dart';

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

        final assignableItems = hoistVmMap.map(
          (key, value) => MapEntry(
            key,
            AssignableItem<String, HoistViewModel>(
              id: key,
              item: value,
              assignedSelectionIndex: value.assignedSelectionIndex,
              candidateSelectionIndex: value.candidateSelectionIndex,
            ),
          ),
        );

        final selectedHoistChannelVmMap =
            mapSelectedHoistChannelViewModels(store, hoistVmMap);

        final hoistItems = selectLocationHoistItems(
            context: context, hoistViewModels: hoistVmMap, store: store);

        final hoistControllers = selectHoistControllers(
          context: context,
          store: store,
          selectedHoistChannelViewModelMap: selectedHoistChannelVmMap,
          hoistViewModels: hoistVmMap,
        );

        return HoistsViewModel(
            hoistItems: hoistItems,
            assignableItems: assignableItems,
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
            hoistControllers: hoistControllers,
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
