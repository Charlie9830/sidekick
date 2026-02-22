import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/containers/hoist_selectors.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/hoists/hoists.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';

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

        final assignableItems =
            Map<String, ItemData<String, HoistViewModel>>.fromEntries(
                hoistVmMap.entries.map(
          (entry) => MapEntry(
            entry.key,
            ItemData<String, HoistViewModel>(
              id: entry.key,
              item: entry.value,
            ),
          ),
        ));

        final selectedHoistChannelVmMap =
            mapSelectedHoistChannelViewModels(store, hoistVmMap);

        final hoistControllers = selectHoistControllers(
          context: context,
          store: store,
          selectedHoistChannelViewModelMap: selectedHoistChannelVmMap,
          hoistViewModels: hoistVmMap,
        );

        final sidebarItems = selectSidebarItems(context: context, store: store);

        return HoistsViewModel(
          sidebarItems: sidebarItems,
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
        );
      },
    );
  }
}
