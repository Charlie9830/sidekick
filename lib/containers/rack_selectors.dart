import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_rack_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';

List<PowerMultiSidebarLocation> selectPowerMultiSidebarItems(
    {required BuildContext context, required Store<AppState> store}) {
  final powerMultisByLocationId = store
      .state.fixtureState.powerMultiOutlets.values
      .groupListsBy((hoist) => hoist.locationId);

  return store.state.fixtureState.locations.values.foldIndexed(
      <PowerMultiSidebarLocation>[], (locationIndex, accum, location) {
    final globalIndexOffset = accum.fold(0, (v, e) => v + e.children.length);

    return [
      ...accum,
      PowerMultiSidebarLocation(
        location: location,
        children: (powerMultisByLocationId[location.uid] ?? [])
            .mapIndexed((multisInLocationIndex, multi) => PowerMultiSidebarItem(
                  uid: multi.uid,
                  selectionIndex: globalIndexOffset + multisInLocationIndex,
                ))
            .toList(),
      )
    ];
  });
}

List<PowerRackViewModel> selectPowerRacks(
    {required BuildContext context, required Store<AppState> store}) {
  return store.state.fixtureState.powerRacks.values.map((rack) {
    final channelVms =
        _selectChannelVms(context: context, store: store, parentRack: rack);
    return PowerRackViewModel(
      rack: rack,
      channelVms:
          _selectChannelVms(context: context, store: store, parentRack: rack),
      availableTypes: store.state.fixtureState.powerRackTypes.values.toList(),
      hasOverflowed:
          (channelVms.lastIndexWhereOrNull((e) => e.assignedMultiId != null) ??
                  0) >
              (store.state.fixtureState.powerRackTypes[rack.typeId]
                      ?.multiOutletCount ??
                  0),
      onTypeChanged: (typeId) =>
          store.dispatch(updatePowerRackType(rack.uid, typeId)),
      onDelete: () => store.dispatch(deletePowerRack(context, rack)),
      onNameChanged: (value) =>
          store.dispatch(UpdatePowerRackName(rack.uid, value)),
    );
  }).toList();
}

List<PowerRackChannelViewModel> _selectChannelVms(
    {required BuildContext context,
    required Store<AppState> store,
    required PowerRackModel parentRack}) {
  final rackType = store.state.fixtureState.powerRackTypes[parentRack.typeId]!;
  final multisAssignedToRack = store.state.fixtureState.powerMultiOutlets.values
      .where((multi) => multi.parentRack.rackId == parentRack.uid)
      .toList();

  final assignedMultisByChannel = Map<int, PowerMultiOutletModel>.fromEntries(
      multisAssignedToRack
          .map((multi) => MapEntry(multi.parentRack.channel, multi)));

  final multiChannelCount = max(rackType.multiOutletCount,
      PowerMultiOutletModel.getHighestChannelNumber(multisAssignedToRack));

  final getAssignedIndex = () {
    int index = 0;
    return () => index++;
  }();

  return List<PowerRackChannelViewModel>.generate(
    multiChannelCount,
    (index) {
      final assignedId = assignedMultisByChannel[index + 1]?.uid;

      return PowerRackChannelViewModel(
        assignedMultiId: assignedId,
        assignedSelectionIndex: assignedId != null ? getAssignedIndex() : null,
        isOverflowing: index >= rackType.multiOutletCount,
        onUnpatch: () =>
            store.dispatch(unpatchPowerMulti(parentRack, assignedId)),
        onMultisLanded: (ids) => store.dispatch(assignPowerMultisToRack(
            movingOrIncomingMultiIds: ids,
            startingChannelNumber: index + 1,
            targetRackId: parentRack.uid)),
      );
    },
  );
}
