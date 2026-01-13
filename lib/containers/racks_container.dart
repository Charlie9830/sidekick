import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/containers/hoist_selectors.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/hoists/hoists.dart';
import 'package:sidekick/screens/racks/racks.dart';

import 'package:sidekick/view_models/hoists_view_model.dart';
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
        final assignedMultiIds = store.state.fixtureState.powerRacks.values
            .map((rack) => rack.assignments.values)
            .flattened
            .toSet();

        final powerMultiOutletVmMap = mapPowerMultiOutletViewModels(
          store: store,
          assignedMultiIds: assignedMultiIds,
        );

        final selectedPowerMultiVms = mapSelectedPowerMultiChannelViewModels(
            store, powerMultiOutletVmMap);

        final powerMultiItems = _selectLocationPowerMultiItems(
            context: context,
            powerMultiViewModels: powerMultiOutletVmMap,
            store: store);

        final availablePowerRackTypes = store
            .state.fixtureState.powerRackTypes.values
            .map((type) => PowerRackTypeViewModel(type: type))
            .toList();

        return RacksScreenViewModel(
            powerOutletItems: powerMultiItems,
            selectedMultiOutlets: selectedPowerMultiVms,
            availablePowerRackTypes: availablePowerRackTypes,
            onSelectedPowerMultiOutletsChanged: (updateType, ids) =>
                store.dispatch(selectPowerMultiOutlets(updateType, ids)),
            onSelectedPowerRackChannelsChanged: (updateType, ids) =>
                store.dispatch(selectPowerMultiChannels(updateType, ids)),
            onAddPowerRack: (rackType) =>
                store.dispatch(addPowerRack(rackType)),
            powerRackVms: _selectPowerRacks(
                store: store,
                selectedPowerMultiOutlets: selectedPowerMultiVms,
                assignedMultiIds: assignedMultiIds,
                availablePowerRackTypes: availablePowerRackTypes));
      },
    );
  }
}

List<PowerRackViewModel> _selectPowerRacks({
  BuildContext? context,
  required Store<AppState> store,
  required Map<String, PowerMultiOutletViewModel> selectedPowerMultiOutlets,
  required Set<String> assignedMultiIds,
  required List<PowerRackTypeViewModel> availablePowerRackTypes,
  bool isDiffing = false,
}) {
  return store.state.fixtureState.powerRacks.values.map((rack) {
    final childMultis = rack.assignments.map((index, multiId) =>
        MapEntry(index, store.state.fixtureState.powerMultiOutlets[multiId]!));
    final rackType = store.state.fixtureState.powerRackTypes[rack.typeId]!;
    final maxOutletCount = max(childMultis.length, rackType.multiOutletCount);

    return PowerRackViewModel(
        rack: rack,
        availableTypes: availablePowerRackTypes,
        onTypeChanged: (typeId) =>
            store.dispatch(updatePowerRackType(rack.uid, typeId)),
        rackType: PowerRackTypeViewModel(type: rackType),
        hasOverflowed: childMultis.values.length > rackType.multiOutletCount,
        onNameChanged: (newValue) =>
            store.dispatch(UpdatePowerRackName(rack.uid, newValue)),
        onDelete: () => store.dispatch(deletePowerRack(context!, rack)),
        children: List.generate(maxOutletCount, (index) {
          final channel = index + 1;
          final multi = childMultis[channel];

          return PowerMultiChannelViewModel(
              number: channel,
              isOverflowing: channel > rackType.multiOutletCount,
              onDragStarted: multi != null
                  ? () =>
                      store.dispatch(AppendSelectedHoistChannelId(multi.uid))
                  : () {},
              multiVm: multi == null
                  ? null
                  : _selectPowerMultiViewModel(
                      multi: multi,
                      store: store,
                      assignedMultiIds: assignedMultiIds),
              onMultisLanded: (multiIds) =>
                  store.dispatch(assignPowerMultisToRack(
                    movingOrIncomingPowerMultiIds: multiIds,
                    targetRackId: rack.uid,
                    startingChannelNumber: channel,
                  )),
              selectedMultiOutlets: selectedPowerMultiOutlets,
              onUnpatch: multi != null
                  ? () => store.dispatch(unpatchPowerMulti(rack, multi))
                  : null);
        }));
  }).toList();
}

PowerMultiOutletViewModel _selectPowerMultiViewModel(
    {required PowerMultiOutletModel multi,
    required Store<AppState> store,
    required Set<String> assignedMultiIds}) {
  return PowerMultiOutletViewModel(
    multi: multi,
    parentLocation: store.state.fixtureState.locations[multi.locationId]!,
    assigned: assignedMultiIds.contains(multi.uid),
    selected:
        store.state.navstate.selectedMultiPowerOutletIds.contains(multi.uid),
  );
}

Map<String, PowerMultiOutletViewModel> mapSelectedPowerMultiChannelViewModels(
    Store<AppState> store,
    Map<String, PowerMultiOutletViewModel> powerMultiViewModels) {
  return Map<String, PowerMultiOutletViewModel>.fromEntries(store
      .state.navstate.selectedPowerMultiChannelIds
      .map((id) => powerMultiViewModels[id])
      .nonNulls
      .map((vm) => MapEntry(vm.uid, vm)));
}

Map<String, PowerMultiOutletViewModel> mapPowerMultiOutletViewModels(
    {required Store<AppState> store, required Set<String> assignedMultiIds}) {
  return store.state.fixtureState.powerMultiOutlets.values
      .map(
        (multi) => _selectPowerMultiViewModel(
          multi: multi,
          store: store,
          assignedMultiIds: assignedMultiIds,
        ),
      )
      .toModelMap();
}

List<RackScreenItemBase> _selectLocationPowerMultiItems(
    {required BuildContext context,
    required Map<String, PowerMultiOutletViewModel> powerMultiViewModels,
    required Store<AppState> store}) {
  final locations = store.state.fixtureState.locations.values
      .where((location) => location.isHybrid == false);

  final powerMultiViewModelsByLocationId =
      powerMultiViewModels.values.groupListsBy((vm) => vm.multi.locationId);

  final value = locations
      .map((location) => [
            RackOutletLocationViewModel(
              locationName: location.name,
            ),
            ...powerMultiViewModelsByLocationId[location.uid]
                    ?.map((vm) => vm) ??
                <PowerMultiOutletViewModel>[],
          ])
      .flattened
      .cast<RackScreenItemBase>()
      .toList();

  return value;
}
