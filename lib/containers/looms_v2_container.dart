import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/data_selectors/select_cable_label.dart';
import 'package:sidekick/data_selectors/select_cable_location.dart';
import 'package:sidekick/data_selectors/select_child_cables.dart';
import 'package:sidekick/data_selectors/select_dmx_universe.dart';
import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/looms/looms_v2.dart';
import 'package:sidekick/view_models/cable_view_model.dart';
import 'package:sidekick/view_models/loom_view_model.dart';
import 'package:sidekick/view_models/looms_v2_view_model.dart';

class LoomsV2Container extends StatelessWidget {
  const LoomsV2Container({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, LoomsV2ViewModel>(
        builder: (context, viewModel) {
      return LoomsV2(
        vm: viewModel,
      );
    }, converter: (Store<AppState> store) {
      final outlets = _selectOutlets(store);

      return LoomsV2ViewModel(
          outlets: outlets,
          loomsDraggingState: store.state.navstate.loomsDraggingState,
          onLoomsDraggingStateChanged: (draggingState) =>
              store.dispatch(SetLoomsDraggingState(draggingState)),
          selectedLoomOutlets: store.state.navstate.selectedLoomOutlets,
          selectedOutletVms: outlets
              .where((outlet) =>
                  store.state.navstate.selectedLoomOutlets.contains(outlet.uid))
              .toList(),
          selectedCableIds: store.state.navstate.selectedCableIds,
          onSelectCables: (ids) => store.dispatch(setSelectedCableIds(ids)),
          onSelectedLoomOutletsChanged: (updateType, values) {
            switch (updateType) {
              case UpdateType.overwrite:
                store.dispatch(SetSelectedLoomOutlets(values));
                break;
              case UpdateType.addIfAbsentElseRemove:
                store.dispatch(SetSelectedLoomOutlets(
                    store.state.navstate.selectedLoomOutlets.toSet()
                      ..addAllIfAbsentElseRemove(values)));
            }
          },
          onCombineSelectedDataCablesIntoSneak: () =>
              store.dispatch(combineSelectedDataCablesIntoSneakV2(context)),
          onSplitSneakIntoDmxPressed: () =>
              store.dispatch(splitSelectedSneakIntoDmxV2(context)),
          onCreateNewFeederLoom: (outletIds, insertIndex, modifiers) =>
              store.dispatch(createNewFeederLoomV2(
                  context, outletIds, insertIndex, modifiers)),
          onCreateNewExtensionLoom: (cableIds, insertIndex, modifiers) =>
              store.dispatch(createNewExtensionLoomV2(
                  context, cableIds, insertIndex, modifiers)),
          loomVms: _selectLoomRows(context, store),
          onLoomReorder: (oldIndex, newIndex) =>
              store.dispatch(reorderLooms(context, oldIndex, newIndex)),
          onDeleteSelectedCables: store.state.navstate.selectedCableIds.isNotEmpty ? () => store.dispatch(deleteSelectedCablesV2(context)) : null);
    });
  }

  List<OutletViewModel> _selectOutlets(Store<AppState> store) {
    final assignedOutletIds = _selectAssignedOutletIds(store);

    final powerMultiOutletsByLocation = store
        .state.fixtureState.powerMultiOutlets.values
        .groupListsBy((element) => element.locationId);
    final dataPatchOutletsByLocation = store
        .state.fixtureState.dataPatches.values
        .groupListsBy((element) => element.locationId);

    return store.state.fixtureState.locations.values
        .map((location) {
          final allOutletsInLocation = [
            ...powerMultiOutletsByLocation[location.uid] ?? [],
            ...dataPatchOutletsByLocation[location.uid] ?? [],
          ];

          return [
            OutletDividerViewModel(title: location.name, uid: location.uid),
            ...allOutletsInLocation.map((outlet) => switch (outlet) {
                  PowerMultiOutletModel outlet => PowerMultiOutletViewModel(
                      uid: outlet.uid,
                      outlet: outlet,
                      assigned: assignedOutletIds.contains(outlet.uid)),
                  DataPatchModel outlet => DataOutletViewModel(
                      uid: outlet.uid,
                      outlet: outlet,
                      assigned: assignedOutletIds.contains(outlet.uid)),
                  _ => throw UnimplementedError(
                      'Unable to convert unknown ModelCollectionMember to Outlet ViewModel'),
                })
          ];
        })
        .flattened
        .toList();
  }

  Set<String> _selectAssignedOutletIds(Store<AppState> store) {
    return store.state.fixtureState.cables.values
        .map((cable) => cable.outletId)
        .toSet()
      ..remove('');
  }
}

List<LoomViewModel> _selectLoomRows(
    BuildContext context, Store<AppState> store) {
  // Wrapper Function to wrap multiple similiar calls to Cable VM creation.
  CableViewModel wrapCableVm(CableModel cable, int localNumber) {
    final associatedLocation = selectCableLocation(cable, store);

    return CableViewModel(
      cable: cable,
      locationId: associatedLocation?.uid ?? '',
      labelColor: associatedLocation?.color ?? const LabelColorModel.none(),
      isExtension: cable.upstreamId.isNotEmpty,
      universe: selectDmxUniverse(store.state.fixtureState, cable),
      missingUpstreamCable: cable.upstreamId.isNotEmpty
          ? store.state.fixtureState.cables.containsKey(cable.upstreamId) ==
              false
          : false,
      localNumber: localNumber,
      label: selectCableLabel(
        powerMultiOutlets: store.state.fixtureState.powerMultiOutlets,
        dataPatches: store.state.fixtureState.dataPatches,
        dataMultis: store.state.fixtureState.dataMultis,
        cable: cable,
        includeUniverse: false,
      ),
      onLengthChanged: (newValue) =>
          store.dispatch(UpdateCableLength(cable.uid, newValue)),
      onNotesChanged: (newValue) => store.dispatch(UpdateCableNote(cable.uid, newValue))
    );
  }

  final List<LoomModel> orderedLooms =
      store.state.fixtureState.looms.values.toList();

  // Getting a bit stupidly smarty pants here. Create a local closure to track the current 'localNumber' of a cable.
  // The local number pertains to the current count of a type of cable within a loom, for example Soca 1, Soca 2, Soca 3, Sneak 1 etc.
  int Function(CableType) localNumberCounterClosure() {
    Map<CableType, int> buffer = {
      CableType.socapex: 0,
      CableType.wieland6way: 0,
      CableType.sneak: 0,
      CableType.dmx: 0,
    };

    return (CableType type) {
      buffer[type] = buffer[type]! + 1;
      return buffer[type]!;
    };
  }

  final loomVms = orderedLooms.mapIndexed(
    (index, loom) {
      final childCables = store.state.fixtureState.cables.values
          .where((cable) =>
              cable.loomId == loom.uid && cable.parentMultiId.isEmpty)
          .toList();

      final getCount = localNumberCounterClosure();

      final loomedCableVms = childCables
          .sorted((a, b) => CableModel.compareByType(a, b))
          .map((cable) {
            return [
              // Top Level Cable
              if (cable.parentMultiId.isEmpty)
                wrapCableVm(cable, getCount(cable.type)),

              // Optional Children of Multi Cables.
              ...selectChildCables(cable, store.state.fixtureState)
                  .mapIndexed((index, child) => wrapCableVm(child, index + 1))
            ];
          })
          .flattened
          .toList();

      return LoomViewModel(
          loom: loom,
          loomsOnlyIndex: index,
          hasVariedLengthChildren:
              childCables.map((cable) => cable.length).toSet().length > 1,
          name: _getLoomName(loom, store),
          addOutletsToLoom: (loomId, outletIds) =>
              store.dispatch(addOutletsToLoom(context, loomId, outletIds)),
          isValidComposition: loom.type.type == LoomType.permanent
              ? loom.type.checkIsValid(childCables)
              : true,
          children: loomedCableVms,
          onRepairCompositionButtonPressed: () =>
              store.dispatch(repairLoomComposition(loom, context)),
          onLengthChanged: (newValue) =>
              store.dispatch(UpdateLoomLength(loom.uid, newValue)),
          onDelete: () => store.dispatch(
                deleteLoomV2(context, loom.uid),
              ),
          onDropperToggleButtonPressed: () => store.dispatch(
                ToggleCableDropperStateByLoom(
                  loom.uid,
                ),
              ),
          onSwitchType: () => store.dispatch(switchLoomTypeV2(
                context,
                loom.uid,
              )),
          addSpareCablesToLoom: () =>
              store.dispatch(addSpareCablesToLoom(context, loom.uid)),
          onNameChanged: (newValue) =>
              store.dispatch(UpdateLoomName(loom.uid, newValue)),
          onMoveCablesIntoLoom: (loomId, cableIds) =>
              store.dispatch(moveCablesIntoLoom(context, loomId, cableIds)));
    },
  ).toList();

  return loomVms;
}

String _getLoomName(LoomModel loom, Store<AppState> store) {
  String loomName = loom.name;

  // // If no custom loom name has been provided. Auto generate one.
  // if (loomName.isEmpty) {
  //   final location = store.state.fixtureState.locations[loom.locationId];
  //   print(location);
  //   if (location != null) {
  //     loomName = selectGeneratedLoomName(
  //         store.state.fixtureState.looms.values
  //             .where((loom) => loom.locationId == location.uid)
  //             .toList(),
  //         location,
  //         loom);
  //   }
  // }

  return loomName;
}
