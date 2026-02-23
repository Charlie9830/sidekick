import 'dart:math';

import 'package:collection/collection.dart';
import 'package:redux/redux.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_rack_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/view_models/power_system_view_model.dart';
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
  final availablePowerSystems =
      _selectPowerSystems(context: context, store: store);
  // Instantiate a closure to serve the Selection indexes to the individual channel.
  final getAssignedIndex = () {
    int index = 0;
    return () => index++;
  }();

  return store.state.fixtureState.powerRacks.values.map((rack) {
    final channelVms = _selectChannelVms(
      context: context,
      store: store,
      parentRack: rack,
      selectionIndexClosure: getAssignedIndex,
    );

    return PowerRackViewModel(
        rack: rack,
        availablePowerSystems: availablePowerSystems,
        powerFeed: _selectPowerFeed(uid: rack.powerFeedId, store: store),
        channelVms: channelVms,
        availableTypes: store.state.fixtureState.powerRackTypes.values.toList(),
        updatePowerSystemId: (id) =>
            store.dispatch(assignPowerRackToSystem(id, rack.uid)),
        hasOverflowed: (channelVms
                    .lastIndexWhereOrNull((e) => e.assignedMultiId != null) ??
                0) >
            (store.state.fixtureState.powerRackTypes[rack.typeId]
                    ?.multiOutletCount ??
                0),
        onTypeChanged: (typeId) =>
            store.dispatch(updatePowerRackType(rack.uid, typeId)),
        onDelete: () => store.dispatch(deletePowerRack(context, rack)),
        onNameChanged: (value) =>
            store.dispatch(UpdatePowerRackName(rack.uid, value)),
        onEditPowerSystems: () =>
            store.dispatch(showPowerSystemManager(context)),
        onManagePowerSystems: () => store.dispatch(
              showPowerSystemManager(context),
            ),
        onPowerFeedSelected: (feedId) =>
            store.dispatch(updatePowerRackFeed(feedId, rack.uid)));
  }).toList();
}

PowerFeedViewModel? _selectPowerFeed(
    {required String uid, required Store<AppState> store}) {
  final feed = store.state.fixtureState.powerFeeds[uid];
  if (feed == null) {
    return null;
  }

  return PowerFeedViewModel(
      feed: feed,
      draw: _calculateCurrentDraw(feedId: feed.uid, store: store),
      parentSystemName:
          store.state.fixtureState.powerSystems[feed.powerSystemId]?.name ??
              '');
}

CurrentDraw _calculateCurrentDraw(
    {required String feedId, required Store<AppState> store}) {
  return store.state.fixtureState.powerRacks.values
      .where((rack) => rack.powerFeedId == feedId)
      .map((rack) => store.state.fixtureState.powerMultiOutlets.values
          .where((multi) => multi.parentRack.rackId == rack.uid))
      .flattened
      .fold(CurrentDraw(0, 0, 0), (accum, item) => accum.addedWith(item.draw));
}

List<PowerSystemViewModel> _selectPowerSystems(
    {required BuildContext context, required Store<AppState> store}) {
  final powerFeedsBySystemId = store.state.fixtureState.powerFeeds.values
      .groupListsBy((i) => i.powerSystemId);

  return store.state.fixtureState.powerSystems.values.map((system) {
    return PowerSystemViewModel(
        system: system,
        childFeeds: (powerFeedsBySystemId[system.uid] ?? [])
            .map(
              (feed) => PowerFeedViewModel(
                  feed: feed,
                  draw: _calculateCurrentDraw(feedId: feed.uid, store: store),
                  parentSystemName: system.name),
            )
            .toList());
  }).toList();
}

List<PowerRackChannelViewModel> _selectChannelVms(
    {required BuildContext context,
    required Store<AppState> store,
    required PowerRackModel parentRack,
    required int Function() selectionIndexClosure}) {
  final rackType = store.state.fixtureState.powerRackTypes[parentRack.typeId]!;
  final multisAssignedToRack = store.state.fixtureState.powerMultiOutlets.values
      .where((multi) => multi.parentRack.rackId == parentRack.uid)
      .toList();

  final assignedMultisByChannel = Map<int, PowerMultiOutletModel>.fromEntries(
      multisAssignedToRack
          .map((multi) => MapEntry(multi.parentRack.channel, multi)));

  final multiChannelCount = max(rackType.multiOutletCount,
      PowerMultiOutletModel.getHighestChannelNumber(multisAssignedToRack));

  return List<PowerRackChannelViewModel>.generate(
    multiChannelCount,
    (index) {
      final assignedId = assignedMultisByChannel[index + 1]?.uid;

      return PowerRackChannelViewModel(
        assignedMultiId: assignedId,
        assignedSelectionIndex:
            assignedId != null ? selectionIndexClosure() : null,
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
