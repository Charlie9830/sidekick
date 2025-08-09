import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/extension_methods/greater_of.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/hoist_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';

List<HoistControllerViewModel> selectHoistControllers({
  BuildContext? context,
  required Store<AppState> store,
  required Map<String, HoistViewModel> selectedHoistChannelViewModelMap,
  required Map<String, List<CableModel>> cablesByHoistId,
}) {
  final hoistsByControllerId = store.state.fixtureState.hoists.values
      .groupListsBy((hoist) => hoist.parentController.controllerId);

  return store.state.fixtureState.hoistControllers.values.map((controller) {
    final childHoists = hoistsByControllerId[controller.uid] ?? [];
    final childHoistsByChannel = Map<int, HoistModel>.fromEntries(childHoists
        .map((hoist) => MapEntry(hoist.parentController.channel, hoist)));

    final channelCount = HoistModel.getHighestChannelNumber(childHoists)
        .greaterOf(controller.ways);

    return HoistControllerViewModel(
        controller: controller,
        hasOverflowed: channelCount > controller.ways,
        onNameChanged: (newValue) => store.dispatch(UpdateHoistControllerName(
            hoistId: controller.uid, value: newValue)),
        onControllerWaysChanged: (newValue) => store.dispatch(
            UpdateHoistControllerWayCount(
                hoistId: controller.uid, value: newValue)),
        onDelete: () =>
            store.dispatch(deleteHoistController(context!, controller)),
        channels: List.generate(channelCount, (index) {
          final channel = index + 1;
          final hoist = childHoistsByChannel[channel];

          return HoistChannelViewModel(
              number: channel,
              isOverflowing: channel > controller.ways,
              onDragStarted: hoist != null
                  ? () =>
                      store.dispatch(AppendSelectedHoistChannelId(hoist.uid))
                  : () {},
              hoist: hoist == null
                  ? null
                  : selectHoistViewModel(
                      hoist: hoist,
                      store: store,
                      cablesByOutletId: cablesByHoistId),
              onHoistsLanded: (hoistIds) => store.dispatch(
                  assignHoistsToController(
                      movingOrIncomingHoistIds: hoistIds,
                      startingChannelNumber: channel,
                      targetControllerId: controller.uid)),
              selected: hoist == null
                  ? false
                  : store.state.navstate.selectedHoistChannelIds
                      .contains(hoist.uid),
              selectedHoistChannelViewModels: selectedHoistChannelViewModelMap,
              onUnpatchHoist: () =>
                  store.dispatch(unpatchHoist(controller, hoist)));
        }));
  }).toList();
}

HoistViewModel selectHoistViewModel(
    {required HoistModel hoist,
    required Store<AppState> store,
    required Map<String, List<CableModel>> cablesByOutletId}) {
  final associatedRootHoistCable = cablesByOutletId[hoist.uid]
      ?.firstWhereOrNull((cable) => cable.upstreamId.isEmpty);
  final associatedMultiOutlet = store.state.fixtureState.hoistMultis[store.state
      .fixtureState.cables[associatedRootHoistCable?.parentMultiId]?.outletId];
  final associatedRootMultiCable = cablesByOutletId[associatedMultiOutlet?.uid]
      ?.firstWhereOrNull((cable) => cable.upstreamId.isEmpty);

  final associatedChildCables = associatedRootMultiCable != null
      ? store.state.fixtureState.cables.values
          .where((cable) => cable.parentMultiId == associatedRootMultiCable.uid)
          .toList()
      : <CableModel>[];

  final childIndex = associatedRootHoistCable != null
      ? associatedChildCables.indexOf(associatedRootHoistCable)
      : -1;

  return HoistViewModel(
    hoist: hoist,
    hasRootCable: associatedRootHoistCable != null,
    patch: associatedRootHoistCable == null
        ? ''
        : associatedRootHoistCable.parentMultiId.isEmpty
            ? hoist.name.toString()
            : childIndex == -1
                ? ''
                : (childIndex + 1).toString(),
    multi: associatedMultiOutlet != null ? associatedMultiOutlet.name : '-',
    locationName:
        store.state.fixtureState.locations[hoist.locationId]?.name ?? '',
    onDelete: () => store.dispatch(deleteHoist(hoist.uid)),
    onNameChanged: (value) => store.dispatch(updateHoistName(hoist.uid, value)),
    selected: store.state.navstate.selectedHoistIds.contains(hoist.uid),
    assigned: hoist.parentController.isAssigned,
    onNoteChanged: (value) => store.dispatch(UpdateHoistNote(hoist.uid, value)),
  );
}

Map<String, List<CableModel>> selectCablesByOutletId(Store<AppState> store) {
  return store.state.fixtureState.cables.values
      .where((cable) =>
          cable.type == CableType.hoist || cable.type == CableType.hoistMulti)
      .groupListsBy((cable) => cable.outletId);
}

Map<String, HoistViewModel> mapSelectedHoistChannelViewModels(
    Store<AppState> store, Map<String, HoistViewModel> hoistVmMap) {
  return Map<String, HoistViewModel>.fromEntries(store
      .state.navstate.selectedHoistChannelIds
      .map((id) => hoistVmMap[id])
      .nonNulls
      .map((vm) => MapEntry(vm.uid, vm)));
}

Map<String, HoistViewModel> mapHoistViewModels(
    {required Store<AppState> store,
    required Map<String, List<CableModel>> cablesByOutletId}) {
  return store.state.fixtureState.hoists.values
      .map(
        (hoist) => selectHoistViewModel(
          hoist: hoist,
          store: store,
          cablesByOutletId: cablesByOutletId,
        ),
      )
      .toModelMap();
}

List<HoistItemBase> selectLocationHoistItems(
    {required BuildContext context,
    required Map<String, HoistViewModel> hoistViewModels,
    required Store<AppState> store}) {
  final locations = store.state.fixtureState.locations.values
      .where((location) => location.isHybrid == false);

  final hoistViewModelsByLocationId =
      hoistViewModels.values.groupListsBy((vm) => vm.hoist.locationId);

  final value = locations
      .map((location) => [
            HoistLocationViewModel(
                location: location,
                onDeleteLocation: () =>
                    store.dispatch(deleteLocation(context, location.uid)),
                onAddHoistButtonPressed: () =>
                    store.dispatch(addHoist(location.uid)),
                onEditLocation: () =>
                    store.dispatch(editRiggingLocation(context, location))),
            ...hoistViewModelsByLocationId[location.uid]?.map((vm) => vm) ??
                <HoistViewModel>[],
          ])
      .flattened
      .toList();

  return value;
}
