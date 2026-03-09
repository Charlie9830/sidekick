import 'dart:math';

import 'package:collection/collection.dart';
import 'package:redux/redux.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/data_rack_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_rack_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';

List<PowerMultiSidebarLocation> selectPowerMultiSidebarItems(
    {required BuildContext context, required Store<AppState> store}) {
  final powerMultisByLocationId = store
      .state.fixtureState.powerMultiOutlets.values
      .groupListsBy((outlet) => outlet.locationId);

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

List<DataOutletSidebarLocation> selectDataPatchSidebarItems(
    {required BuildContext context, required Store<AppState> store}) {
  final dataPatchesByLocationId = store.state.fixtureState.dataPatches.values
      .groupListsBy((outlet) => outlet.locationId);

  return store.state.fixtureState.locations.values.foldIndexed(
      <DataOutletSidebarLocation>[], (locationIndex, accum, location) {
    final globalIndexOffset = accum.fold(0, (v, e) => v + e.children.length);

    return [
      ...accum,
      DataOutletSidebarLocation(
        location: location,
        children: (dataPatchesByLocationId[location.uid] ?? [])
            .mapIndexed((patchesInLocationIndex, patch) =>
                DataOutletSidebarItem(
                  uid: patch.uid,
                  selectionIndex: globalIndexOffset + patchesInLocationIndex,
                ))
            .toList(),
      )
    ];
  });
}

List<PowerRackViewModel> selectPowerRacks(
    {required BuildContext context, required Store<AppState> store}) {
  // Instantiate a closure to serve the Selection indexes to the individual channel.
  final getAssignedIndex = () {
    int index = 0;
    return () => index++;
  }();

  return store.state.fixtureState.powerRacks.values.map((rack) {
    final channelVms = _selectPowerChannelVms(
      context: context,
      store: store,
      parentRack: rack,
      selectionIndexClosure: getAssignedIndex,
    );

    return PowerRackViewModel(
        rack: rack,
        powerFeed: _selectPowerFeed(uid: rack.powerFeedId, store: store),
        channelVms: channelVms,
        availableTypes: store.state.fixtureState.powerRackTypes.values.toList(),
        updatePowerSystemId: (id) =>
            store.dispatch(assignPowerRackToFeed(id, rack.uid)),
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
        onEditPowerSystems: () => store.dispatch(showPowerFeedManager(context)),
        onManagePowerSystems: () => store.dispatch(
              showPowerFeedManager(context),
            ),
        onPowerFeedSelected: (feedId) =>
            store.dispatch(updatePowerRackFeed(feedId, rack.uid)),
        availablePowerFeeds: store.state.fixtureState.powerFeeds.values
            .map((feed) => _selectPowerFeed(uid: feed.uid, store: store))
            .nonNulls
            .toList());
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
  );
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

List<PowerRackChannelViewModel> _selectPowerChannelVms(
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

List<DataRackViewModel> selectDataRacks(
    {required BuildContext context, required Store<AppState> store}) {
  // Instantiate a closure to serve the Selection indexes to the individual channel.
  final getAssignedIndex = () {
    int index = 0;
    return () => index++;
  }();

  return store.state.fixtureState.dataRacks.values.map((rack) {
    final channelVms = _selectDataChannelVms(
      context: context,
      store: store,
      parentRack: rack,
      selectionIndexClosure: getAssignedIndex,
    );

    return DataRackViewModel(
        rack: rack,
        channelVms: channelVms,
        availableTypes: store.state.fixtureState.dataRackTypes.values.toList(),
        rackType: store.state.fixtureState.dataRackTypes[rack.typeId]!,
        hasOverflowed: (channelVms
                    .lastIndexWhereOrNull((e) => e.assignedPatchId != null) ??
                0) >
            (store.state.fixtureState.dataRackTypes[rack.typeId]?.outletCount ??
                0),
        onTypeChanged: (typeId) =>
            store.dispatch(updateDataRackType(rack.uid, typeId)),
        onDelete: () => store.dispatch(deleteDataRack(context, rack)),
        onNameChanged: (value) =>
            store.dispatch(UpdateDataRackName(rack.uid, value)));
  }).toList();
}

List<DataRackChannelViewModel> _selectDataChannelVms(
    {required BuildContext context,
    required Store<AppState> store,
    required DataRackModel parentRack,
    required int Function() selectionIndexClosure}) {
  final rackType = store.state.fixtureState.dataRackTypes[parentRack.typeId]!;
  final patchesAssignedToRack = store.state.fixtureState.dataPatches.values
      .where((patch) => patch.parentRack.rackId == parentRack.uid)
      .toList();

  final assignedPatchesByChannel = Map<int, DataPatchModel>.fromEntries(
      patchesAssignedToRack
          .map((patch) => MapEntry(patch.parentRack.channel, patch)));

  final patchChannelCount = max(rackType.outletCount,
      DataPatchModel.getHighestChannelNumber(patchesAssignedToRack));

  return List<DataRackChannelViewModel>.generate(
    patchChannelCount,
    (index) {
      final assignedId = assignedPatchesByChannel[index + 1]?.uid;

      return DataRackChannelViewModel(
        assignedPatchId: assignedId,
        assignedSelectionIndex:
            assignedId != null ? selectionIndexClosure() : null,
        isOverflowing: index >= rackType.outletCount,
        onUnpatch: () =>
            store.dispatch(unpatchDataOutlet(parentRack, assignedId)),
        onPatchesLanded: (ids) => store.dispatch(assignDataPatchesToRack(
            movingOrIncomingPatchIds: ids,
            startingChannelNumber: index + 1,
            targetRackId: parentRack.uid)),
      );
    },
  );
}

class PatchInfo {
  final DataPatchModel patch;
  final CableModel cable;
  final CableModel? parentMultiCable;
  final DataMultiModel? parentMultiOutlet;
  final LocationModel location;
  final int? parentMultiLine;

  PatchInfo({
    required this.patch,
    required this.cable,
    required this.parentMultiCable,
    required this.parentMultiOutlet,
    required this.location,
    required this.parentMultiLine,
  });
}

List<PatchInfo> selectRootDataPatches(Store<AppState> store) {
  final cablesByParentMultiId = store.state.fixtureState.cables.values
      .where((cable) => cable.type == CableType.dmx)
      .where((cable) => cable.parentMultiId.isNotEmpty)
      .groupListsBy((cable) => cable.parentMultiId);

  return store.state.fixtureState.cables.values
      .where((cable) => cable.upstreamId.isEmpty)
      .where((cable) => cable.type == CableType.dmx)
      .map((cable) {
        final patch = store.state.fixtureState.dataPatches[cable.outletId];

        if (patch == null) {
          return null;
        }
        final location = store.state.fixtureState.locations[patch.locationId];

        if (location == null) {
          return null;
        }

        final parentMultiCable =
            store.state.fixtureState.cables[cable.parentMultiId];
        final parentMultiOutlet =
            store.state.fixtureState.dataMultis[parentMultiCable?.outletId];
        final parentMultiIndex = cablesByParentMultiId[parentMultiCable?.uid]
            ?.indexWhereOrNull((value) => value.uid == cable.uid);

        return PatchInfo(
            cable: cable,
            patch: patch,
            parentMultiCable: parentMultiCable,
            parentMultiOutlet: parentMultiOutlet,
            location: location,
            parentMultiLine:
                parentMultiIndex != null ? parentMultiIndex + 1 : null);
      })
      .nonNulls
      .toList();
}
