import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/data_selectors/select_cable_and_loom_rows.dart';
import 'package:sidekick/data_selectors/select_cable_label.dart';
import 'package:sidekick/data_selectors/select_cable_specific_location_color_label.dart';
import 'package:sidekick/data_selectors/select_child_cables.dart';
import 'package:sidekick/data_selectors/select_dmx_universe.dart';
import 'package:sidekick/data_selectors/select_loom_name.dart';
import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/looms_v2/looms_v2.dart';
import 'package:sidekick/view_models/loom_item_view_model.dart';
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
          onCreateNewCustomLoom: (outletIds) =>
              store.dispatch(createNewCustomLoomV2(context, outletIds)),
          onCreateNewPermanentLoom: (outletIds) => print("TODO: Build me"),
          loomVms: _selectLoomRows(
            context,
            store,
          ));
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

          return allOutletsInLocation.map((outlet) => switch (outlet) {
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
              });
        })
        .flattened
        .toList();
  }

  Set<String> _selectAssignedOutletIds(Store<AppState> store) {
    return store.state.fixtureState.cables.values
        .where((cable) => cable.outletId.isNotEmpty)
        .map((cable) => cable.uid)
        .toSet();
  }
}

List<LoomItemViewModel> _selectLoomRows(
    BuildContext context, Store<AppState> store) {
  // Wrapper Function to wrap multiple similiar calls to Cable VM creation.
  CableViewModel wrapCableVm(CableModel cable) => CableViewModel(
        cable: cable,
        locationId: cable.locationId,
        labelColor: selectCableSpecificLocationColorLabel(
            cable, store.state.fixtureState.locations),
        isExtension: cable.upstreamId.isNotEmpty,
        universe: selectDmxUniverse(store.state.fixtureState, cable),
        label: selectCableLabel(
          powerMultiOutlets: store.state.fixtureState.powerMultiOutlets,
          dataMultis: store.state.fixtureState.dataMultis,
          dataPatches: store.state.fixtureState.dataPatches,
          cable: cable,
          includeUniverse: false,
        ),
        onLengthChanged: (newValue) =>
            store.dispatch(UpdateCableLength(cable.uid, newValue)),
      );

  final List<LoomModel> orderedLooms =
      store.state.fixtureState.looms.values.toList();

  final loomVms = orderedLooms.map(
    (loom) {
      final childCables = store.state.fixtureState.cables.values
          .where((cable) =>
              cable.loomId == loom.uid && cable.parentMultiId.isEmpty)
          .toList();

      final loomedCableVms = childCables
          .sorted((a, b) => CableModel.compareByType(a, b))
          .map((cable) => [
                // Top Level Cable
                if (cable.parentMultiId.isEmpty) wrapCableVm(cable),

                // Optional Children of Multi Cables.
                ...selectChildCables(cable, store.state.fixtureState)
                    .map((child) => wrapCableVm(child))
              ])
          .flattened
          .toList();

      return LoomViewModel(
          loom: loom,
          hasVariedLengthChildren:
              childCables.map((cable) => cable.length).toSet().length > 1,
          name: 'V2 Not Implemented Yet...',
          isValidComposition: loom.type.type == LoomType.permanent
              ? loom.type.checkIsValid(childCables)
              : true,
          children: loomedCableVms,
          onRepairCompositionButtonPressed: () =>
              store.dispatch(repairLoomComposition(loom, context)),
          onLengthChanged: (newValue) =>
              store.dispatch(UpdateLoomLength(loom.uid, newValue)),
          onDelete: () => store.dispatch(
                deleteLoom(context, loom.uid),
              ),
          onDropperToggleButtonPressed: () => store.dispatch(
                ToggleLoomDropperState(
                  loom.uid,
                  !loom.isDrop,
                  loomedCableVms.map((child) => child.cable).toList(),
                ),
              ),
          onSwitchType: () => store.dispatch(switchLoomType(context, loom.uid,
              loomedCableVms.map((child) => child.cable).toList())),
          addSelectedCablesToLoom:
              store.state.navstate.selectedCableIds.isNotEmpty
                  ? () => store.dispatch(
                        addSelectedCablesToLoom(
                          context,
                          loom.uid,
                          store.state.navstate.selectedCableIds,
                        ),
                      )
                  : null,
          addSpareCablesToLoom: () =>
              store.dispatch(addSpareCablesToLoom(context, loom.uid)));
    },
  ).toList();

  if (loomVms.isEmpty) {
    return [];
  }

  return [
    DividerViewModel(index: 0),
    ...loomVms
        .mapIndexed(
            (index, element) => [element, DividerViewModel(index: index + 2)])
        .flattened
  ];
}
