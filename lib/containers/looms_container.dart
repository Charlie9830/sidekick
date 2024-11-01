import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/data_selectors/select_cable_label.dart';
import 'package:sidekick/data_selectors/select_loom_name.dart';
import 'package:sidekick/data_selectors/select_title_case_color.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
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
          onSplitSneakIntoDmx: () => store.dispatch(splitSneakIntoDmx(
              context, store.state.navstate.selectedCableIds)));
    });
  }

  List<LoomScreenItemViewModel> _selectRows(
      BuildContext context, Store<AppState> store) {
    final cablesAndLoomsByLocation =
        store.state.fixtureState.locations.map((locationId, location) {
      final cablesInLocation = store.state.fixtureState.cables.values.where(
        (cable) => cable.locationId == locationId && cable.dataMultiId.isEmpty,
      );

      final loomsInLocation = store.state.fixtureState.looms.values
          .where((loom) => loom.locationIds.contains(locationId))
          .toList();

      final nakedCables =
          cablesInLocation.where((cable) => cable.loomId.isEmpty);

      return MapEntry(location, [
        // Naked Cables
        ...nakedCables.map(
          (cable) => CableViewModel(
              cable: cable,
              locationId: location.uid,
              labelColor:
                  selectTitleCaseColor(NamedColors.names[location.color] ?? ''),
              isExtension: cable.upstreamId.isNotEmpty,
              sneakUniverses: _selectSneakUniverses(store, cable),
              universe: _selectDmxUniverse(store, cable),
              label: _selectCableLabel(store, cable),
              onLengthChanged: (newValue) =>
                  store.dispatch(UpdateCableLength(cable.uid, newValue))),
        ),

        // Looms
        ...loomsInLocation.map(
          (loom) {
            final childCables = store.state.fixtureState.cables.values
                .where((cable) =>
                    cable.loomId == loom.uid && cable.dataMultiId.isEmpty)
                .toList();

            final childVms = childCables
                .map((cable) => CableViewModel(
                    cable: cable,
                    locationId: location.uid,
                    labelColor: selectTitleCaseColor(
                        NamedColors.names[location.color] ?? ''),
                    isExtension: cable.upstreamId.isNotEmpty,
                    sneakUniverses: _selectSneakUniverses(store, cable),
                    universe: _selectDmxUniverse(store, cable),
                    label: _selectCableLabel(store, cable),
                    onLengthChanged: (newValue) =>
                        store.dispatch(UpdateCableLength(cable.uid, newValue))))
                .toList();

            return LoomViewModel(
              loom: loom,
              hasVariedLengthChildren: childCables.map((cable) => cable.length).toSet().length > 1,
              name: selectLoomName(loomsInLocation, location, loom),
              isValidComposition: loom.type.type == LoomType.permanent
                  ? loom.type.checkIsValid(childCables)
                  : true,
              children: childVms,
              onLengthChanged: (newValue) =>
                  store.dispatch(UpdateLoomLength(loom.uid, newValue)),
              onDelete: () => store.dispatch(
                deleteLoom(context, loom.uid),
              ),
              onDropperToggleButtonPressed: () => store.dispatch(
                ToggleLoomDropperState(
                  loom.uid,
                  !loom.isDrop,
                  childVms.map((child) => child.cable).toList(),
                ),
              ),
              onSwitchType: () => store.dispatch(switchLoomType(context,
                  loom.uid, childVms.map((child) => child.cable).toList())),
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
            );
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

  String _selectCableLabel(Store<AppState> store, CableModel cable) {
    return selectCableLabel(
      powerMultiOutlets: store.state.fixtureState.powerMultiOutlets,
      dataMultis: store.state.fixtureState.dataMultis,
      dataPatches: store.state.fixtureState.dataPatches,
      cable: cable,
      includeUniverse: false,
    );
  }

  List<int> _selectSneakUniverses(Store<AppState> store, CableModel cable) {
    if (cable.type != CableType.sneak || cable.isSpare == true) {
      return [];
    }

    final associatedChildCables = store.state.fixtureState.cables.values
        .where((child) => child.dataMultiId == cable.uid);

    final patchOutlets = associatedChildCables
        .map((child) => store.state.fixtureState.dataPatches[child.outletId])
        .nonNulls;

    return patchOutlets.map((patch) => patch.universe).toList();
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
}
