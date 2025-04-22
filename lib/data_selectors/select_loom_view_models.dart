import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/data_selectors/select_cable_label.dart';
import 'package:sidekick/data_selectors/select_cable_location.dart';
import 'package:sidekick/data_selectors/select_child_cables.dart';
import 'package:sidekick/data_selectors/select_dmx_universe.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/view_models/cable_view_model.dart';
import 'package:sidekick/view_models/loom_view_model.dart';

List<LoomViewModel> selectLoomViewModels(
  Store<AppState> store, {
  BuildContext? context,
  bool forExcel = false,
}) {
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
        label: selectCableLabel(
          powerMultiOutlets: store.state.fixtureState.powerMultiOutlets,
          dataPatches: store.state.fixtureState.dataPatches,
          dataMultis: store.state.fixtureState.dataMultis,
          cable: cable,
          preferUniverseOnly: forExcel,
        ),
        typeLabel: _getTypeLabel(
          cable.type,
          localNumber,
          isSneakChild: cable.parentMultiId.isNotEmpty,
        ),
        onLengthChanged: (newValue) =>
            store.dispatch(UpdateCableLength(cable.uid, newValue)),
        onNotesChanged: (newValue) =>
            store.dispatch(UpdateCableNote(cable.uid, newValue)));
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
              store.dispatch(addOutletsToLoom(context!, loomId, outletIds)),
          isValidComposition: loom.type.type == LoomType.permanent
              ? loom.type.checkIsValid(childCables)
              : true,
          children: loomedCableVms,
          onRepairCompositionButtonPressed: () =>
              store.dispatch(repairLoomComposition(loom, context!)),
          onLengthChanged: (newValue) =>
              store.dispatch(UpdateLoomLength(loom.uid, newValue)),
          onDelete: () => store.dispatch(
                deleteLoomV2(context!, loom.uid),
              ),
          onDropperToggleButtonPressed: () => store.dispatch(
                ToggleCableDropperStateByLoom(
                  loom.uid,
                ),
              ),
          onSwitchType: () => store.dispatch(switchLoomTypeV2(
                context!,
                loom.uid,
              )),
          addSpareCablesToLoom: () =>
              store.dispatch(addSpareCablesToLoom(context!, loom.uid)),
          onNameChanged: (newValue) =>
              store.dispatch(UpdateLoomName(loom.uid, newValue)),
          onMoveCablesIntoLoom: (loomId, cableIds) =>
              store.dispatch(moveCablesIntoLoom(context!, loomId, cableIds)));
    },
  ).toList();

  return loomVms;
}

String _getTypeLabel(CableType type, int localNumber,
    {bool isSneakChild = false}) {
  if (isSneakChild) {
    return 'Data $localNumber';
  }

  return switch (type) {
    CableType.dmx => 'DMX $localNumber',
    CableType.socapex => 'Soca $localNumber',
    CableType.sneak => 'Sneak $localNumber',
    CableType.wieland6way => '6way $localNumber',
    CableType.unknown => "Unknown",
  };
}

String _getLoomName(LoomModel loom, Store<AppState> store) {
  return loom.name;
}
