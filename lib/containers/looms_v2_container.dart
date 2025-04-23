import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/data_selectors/select_loom_view_models.dart';
import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/loom_stock_model.dart';
import 'package:sidekick/redux/models/permanent_loom_composition.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/looms/looms_v2.dart';
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
          onChangePowerMultiTypeOfSelectedCables: store
                  .state.navstate.selectedCableIds.isNotEmpty
              ? () =>
                  store.dispatch(changeSelectedCablesToDefaultPowerMultiType())
              : null,
          defaultPowerMultiType: store.state.fixtureState.defaultPowerMulti,
          onDefaultPowerMultiTypeChanged: (newValue) =>
              store.dispatch(SetDefaultPowerMulti(newValue)),
          onCombineSelectedDataCablesIntoSneak: () =>
              store.dispatch(combineSelectedDataCablesIntoSneakV2(context)),
          onSplitSneakIntoDmxPressed: () =>
              store.dispatch(splitSelectedSneakIntoDmxV2(context)),
          onCreateNewFeederLoom: (outletIds, insertIndex, modifiers) =>
              store.dispatch(createNewFeederLoomV2(
                  context, outletIds, insertIndex, modifiers)),
          onCreateNewExtensionLoom: (cableIds, insertIndex, modifiers) =>
              store.dispatch(createNewExtensionLoomV2(context, cableIds, insertIndex, modifiers)),
          loomVms: selectLoomViewModels(store, context: context),
          onLoomReorder: (oldIndex, newIndex) => store.dispatch(reorderLooms(context, oldIndex, newIndex)),
          onDeleteSelectedCables: store.state.navstate.selectedCableIds.isNotEmpty ? () => store.dispatch(deleteSelectedCablesV2(context)) : null,
          availabilityDrawOpen: store.state.navstate.isAvailabilityDrawerOpen,
          onShowAvailabilityDrawPressed: () => store.dispatch(SetIsAvailabilityDrawerOpen(!store.state.navstate.isAvailabilityDrawerOpen)),
          stockVms: _selectLoomStockViewModels(store),
          onSetupQuantiesDrawerButtonPressed: () => store.dispatch(showSetupQuantitiesDialog(context)));
    });
  }

  List<LoomStockQuantityViewModel> _selectLoomStockViewModels(
      Store<AppState> store) {
    final loomStock = store.state.fixtureState.loomStock;

    final loomsByType = store.state.fixtureState.looms.values
        .where((loom) => loom.type.permanentComposition.isNotEmpty)
        .groupListsBy((loom) => LoomStockModel.resolveFullName(
            loom.type.permanentComposition, loom.type.length));

    return loomStock.values
        .map((stock) => LoomStockQuantityViewModel(
            stock: stock, inUse: loomsByType[stock.fullName]?.length ?? 0))
        .toList();
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
