import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/containers/rack_selectors.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/racks/racks.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';

import 'package:sidekick/view_models/racks_screen_view_model.dart';

class RacksContainer extends StatelessWidget {
  const RacksContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, RacksScreenViewModel>(
      builder: (context, viewModel) {
        return Racks(
          viewModel: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        final cablesByOutletId = store.state.fixtureState.cables.values
            .groupListsBy((e) => e.outletId);

        final assignedPowerMultiIds = store
            .state.fixtureState.powerMultiOutlets.values
            .where((multi) => multi.parentRack.isAssigned)
            .map((multi) => multi.uid)
            .toSet();

        final assignedDataPatchIds = store.state.fixtureState.dataPatches.values
            .where((patch) => patch.parentRack.isAssigned)
            .map((patch) => patch.uid);

        return RacksScreenViewModel(
            // Power Multis
            assignablePowerMultiItems: Map<String,
                ItemData<String, PowerMultiOutletViewModel>>.fromEntries(
              store.state.fixtureState.powerMultiOutlets.values.map(
                (outlet) => MapEntry(
                  outlet.uid,
                  ItemData<String, PowerMultiOutletViewModel>(
                    id: outlet.uid,
                    item: PowerMultiOutletViewModel(
                      multi: outlet,
                      assigned: assignedPowerMultiIds.contains(outlet.uid),
                      parentLocation: store
                          .state.fixtureState.locations[outlet.locationId]!,
                      hasRootCable:
                          cablesByOutletId[outlet.uid]?.isNotEmpty ?? false,
                    ),
                  ),
                ),
              ),
            ),

            // Data Outlets
            assignableDataItems:
                Map<String, ItemData<String, DataOutletViewModel>>.fromEntries(
              selectRootDataPatches(store).map(
                (patchInfo) => MapEntry(
                  patchInfo.patch.uid,
                  ItemData<String, DataOutletViewModel>(
                    id: patchInfo.patch.uid,
                    item: DataOutletViewModel(
                      assigned:
                          assignedDataPatchIds.contains(patchInfo.patch.uid),
                      parentMulti: patchInfo.parentMultiOutlet,
                      patch: patchInfo.patch,
                      parentLocation: patchInfo.location,
                      parentMultiLineNumber: patchInfo.parentMultiLine,
                    ),
                  ),
                ),
              ),
            ),
            powerRacks: selectPowerRacks(context: context, store: store),
            onUnpatchPowerMultis: (selectedMultiIds) =>
                store.dispatch(unpatchPowerMultis(selectedMultiIds)),
            dataRacks: selectDataRacks(context: context, store: store),
            powerSidebarItems:
                selectPowerMultiSidebarItems(context: context, store: store),
            dataSidebarItems:
                selectDataPatchSidebarItems(context: context, store: store),
            onAddPowerRack: () => store.dispatch(addPowerRack(context)),
            onAddDataRack: () => store.dispatch(addDataRack(context)),
            onTabSelected: (index) =>
                store.dispatch(SetSelectedRacksTabIndex(index)),
            tabIndex: store.state.navstate.selectedRacksTabIndex,
            onUnpatchDataOutlets: (selectedPatchOutletIds) =>
                store.dispatch(unpatchDataOutlets(selectedPatchOutletIds)));
      },
    );
  }
}
