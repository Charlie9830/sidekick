import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/data_selectors/select_cable_label.dart';
import 'package:sidekick/data_selectors/select_cable_specific_location.dart';
import 'package:sidekick/data_selectors/select_cable_specific_location_color_label.dart';
import 'package:sidekick/data_selectors/select_loom_name.dart';
import 'package:sidekick/data_selectors/select_title_case_color.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/looms/looms.dart';
import 'package:sidekick/view_models/loom_screen_item_view_model.dart';
import 'package:sidekick/view_models/looms_view_model.dart';

class LoomsContainer extends StatelessWidget {
  const LoomsContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, LoomsViewModel>(
        builder: (context, viewModel) {
      return Looms(
        vm: viewModel,
      );
    }, converter: (Store<AppState> store) {
      final selectedCables = store.state.navstate.selectedCableIds
          .map((id) => store.state.fixtureState.cables[id])
          .nonNulls
          .toList();

      return LoomsViewModel(
        selectedCableIds: store.state.navstate.selectedCableIds,
        selectCables: (ids) => store.dispatch(SetSelectedCableIds(ids)),
        onGenerateLoomsButtonPressed: () => store.dispatch(generateCables()),
        rowVms: _selectRows(context, store),
        onCombineCablesIntoNewLoomButtonPressed: (type) => store.dispatch(
            combineCablesIntoNewLoom(
                context, store.state.navstate.selectedCableIds, type)),
        onCreateExtensionFromSelection: () => store.dispatch(
            createExtensionFromSelection(
                context, store.state.navstate.selectedCableIds)),
        onCombineDmxIntoSneak: () => store.dispatch(combineDmxCablesIntoSneak(
            context, store.state.navstate.selectedCableIds)),
        onSplitSneakIntoDmx: () => store.dispatch(
          splitSneakIntoDmx(context, store.state.navstate.selectedCableIds),
        ),
        onDeleteSelectedCables: _selectCanDeleteSelectedCables(selectedCables)
            ? () => store.dispatch(deleteSelectedCables(context))
            : null,
      );
    });
  }

  List<LoomScreenItemViewModel> _selectRows(
      BuildContext context, Store<AppState> store) {
    final cablesAndLoomsByLocation =
        store.state.fixtureState.locations.map((locationId, loomLocation) {
      final cablesInLocation = store.state.fixtureState.cables.values.where(
        (cable) =>
            cable.locationId == locationId && cable.parentMultiId.isEmpty,
      );

      final loomsInLocation = store.state.fixtureState.looms.values
          .where((loom) => loom.locationId == locationId)
          .toList();

      final nakedCables =
          cablesInLocation.where((cable) => cable.loomId.isEmpty);

      // Wrapper Function to wrap multiple similiar calls to Cable VM creation.
      CableViewModel wrapCableVm(CableModel cable) => CableViewModel(
            cable: cable,
            locationId: cable.locationId,
            labelColor: selectCableSpecificLocationColorLabel(
                cable, store.state.fixtureState.locations),
            isExtension: cable.upstreamId.isNotEmpty,
            universe: _selectDmxUniverse(store, cable),
            label: _selectCableLabel(store, cable),
            onLengthChanged: (newValue) =>
                store.dispatch(UpdateCableLength(cable.uid, newValue)),
          
          );

      return MapEntry(loomLocation, [
        // Naked Cables
        ...nakedCables.map(
          (cable) {
            return [
              // Cable
              wrapCableVm(cable),

              /// Optional Child Cables
              ..._selectChildCables(cable, store)
                  .map((child) => wrapCableVm(child))
            ];
          },
        ).flattened,

        // Looms
        ...loomsInLocation.map(
          (loom) {
            final childCables = store.state.fixtureState.cables.values
                .where((cable) =>
                    cable.loomId == loom.uid && cable.parentMultiId.isEmpty)
                .toList();

            final loomedCableVms = childCables
                .map((cable) => [
                      // Top Level Cable
                      wrapCableVm(cable),

                      // Optional Children of Multi Cables.
                      ..._selectChildCables(cable, store)
                          .map((child) => wrapCableVm(child))
                    ])
                .flattened
                .toList();

            return LoomViewModel(
                loom: loom,
                hasVariedLengthChildren:
                    childCables.map((cable) => cable.length).toSet().length > 1,
                name: selectLoomName(
                    loomsInLocation,
                    loomLocation,
                    loom,
                    loom.secondaryLocationIds
                        .map((id) => store.state.fixtureState.locations[id])
                        .nonNulls
                        .toList()),
                isValidComposition: loom.type.type == LoomType.permanent
                    ? loom.type.checkIsValid(childCables)
                    : true,
                children: loomedCableVms,
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
                onSwitchType: () => store.dispatch(switchLoomType(
                    context,
                    loom.uid,
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
        )
      ]);
    });

    return cablesAndLoomsByLocation.entries
        .map((entry) {
          final location = entry.key;
          final cablesAndLooms = entry.value;

          return [
            LocationDividerViewModel(location: location),
            ...cablesAndLooms,
          ];
        })
        .flattened
        .toList();
  }

  List<CableModel> _selectChildCables(
      CableModel parentCable, Store<AppState> store) {
    return parentCable.isMultiCable
        ? store.state.fixtureState.cables.values
            .where((child) => child.parentMultiId == parentCable.uid)
            .toList()
        : const [];
  }

  String _selectCableLabel(Store<AppState> store, CableModel cable) {
    return selectCableLabel(
      powerMultiOutlets: store.state.fixtureState.powerMultiOutlets,
      dataMultis: store.state.fixtureState.dataMultis,
      dataPatches: store.state.fixtureState.dataPatches,
      cable: cable,
      includeUniverse: false,
    );
  }

  int _selectDmxUniverse(Store<AppState> store, CableModel cable) {
    if (cable.type != CableType.dmx || cable.isSpare) {
      return 0;
    }

    final patchOutlet = store.state.fixtureState.dataPatches[cable.outletId];

    if (patchOutlet == null) {
      return 0;
    }

    return patchOutlet.universe;
  }

  bool _selectCanDeleteSelectedCables(List<CableModel> selectedCables) {
    return selectedCables
        .any((cable) => cable.upstreamId.isNotEmpty || cable.isSpare);
  }
}
