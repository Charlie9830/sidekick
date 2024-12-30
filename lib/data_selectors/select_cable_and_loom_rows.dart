import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/data_selectors/select_cable_label.dart';
import 'package:sidekick/data_selectors/select_cable_specific_location_color_label.dart';
import 'package:sidekick/data_selectors/select_child_cables.dart';
import 'package:sidekick/data_selectors/select_dmx_universe.dart';
import 'package:sidekick/data_selectors/select_loom_name.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/redux/state/navigation_state.dart';
import 'package:sidekick/view_models/loom_item_view_model.dart';

List<LoomItemViewModel> selectCableAndLoomRows({
  required BuildContext context,
  required FixtureState fixtureState,
  required dynamic Function(dynamic action) dispatch,
  NavigationState? navState,
}) {
  final allCables = fixtureState.cables;
  final allLooms = fixtureState.looms;

  final cablesAndLoomsByLocation =
      fixtureState.locations.map((locationId, loomLocation) {
    final loomsInLocation =
        allLooms.values.where((loom) => loom.locationId == locationId).toList();

    final unassignedCablesInLocation = allCables.values.where(
        (cable) => cable.loomId.isEmpty && cable.locationId == locationId);

    // Wrapper Function to wrap multiple similiar calls to Cable VM creation.
    CableViewModel wrapCableVm(CableModel cable) => CableViewModel(
          cable: cable,
          locationId: cable.locationId,
          labelColor: selectCableSpecificLocationColorLabel(
              cable, fixtureState.locations),
          isExtension: cable.upstreamId.isNotEmpty,
          universe: selectDmxUniverse(fixtureState, cable),
          label: selectCableLabel(
            powerMultiOutlets: fixtureState.powerMultiOutlets,
            dataMultis: fixtureState.dataMultis,
            dataPatches: fixtureState.dataPatches,
            cable: cable,
            includeUniverse: false,
          ),
          onLengthChanged: (newValue) =>
              dispatch(UpdateCableLength(cable.uid, newValue)),
        );

    return MapEntry(loomLocation, [
      // Naked Cables
      ...unassignedCablesInLocation.map(
        (cable) {
          return [
            // Parent Cable
            if (cable.parentMultiId.isEmpty) wrapCableVm(cable),

            /// Optional Child Cables
            ...selectChildCables(cable, fixtureState)
                .map((child) => wrapCableVm(child))
          ];
        },
      ).flattened,

      // Looms
      ...loomsInLocation.map(
        (loom) {
          final childCables = fixtureState.cables.values
              .where((cable) =>
                  cable.loomId == loom.uid && cable.parentMultiId.isEmpty)
              .toList();

          final loomedCableVms = childCables
              .sorted((a, b) => CableModel.compareByType(a, b))
              .map((cable) => [
                    // Top Level Cable
                    if (cable.parentMultiId.isEmpty) wrapCableVm(cable),

                    // Optional Children of Multi Cables.
                    ...selectChildCables(cable, fixtureState)
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
              ),
              isValidComposition: loom.type.type == LoomType.permanent
                  ? loom.type.checkIsValid(childCables)
                  : true,
              children: loomedCableVms,
              onRepairCompositionButtonPressed: () =>
                  dispatch(repairLoomComposition(loom, context)),
              onLengthChanged: (newValue) =>
                  dispatch(UpdateLoomLength(loom.uid, newValue)),
              onDelete: () => dispatch(
                    deleteLoom(context, loom.uid),
                  ),
              onDropperToggleButtonPressed: () => dispatch(
                    ToggleLoomDropperState(
                      loom.uid,
                      !loom.isDrop,
                      loomedCableVms.map((child) => child.cable).toList(),
                    ),
                  ),
              onSwitchType: () => dispatch(switchLoomType(context, loom.uid,
                  loomedCableVms.map((child) => child.cable).toList())),
              addSelectedCablesToLoom:
                  navState?.selectedCableIds.isNotEmpty ?? false
                      ? () => dispatch(
                            addSelectedCablesToLoom(
                              context,
                              loom.uid,
                              navState?.selectedCableIds ?? {},
                            ),
                          )
                      : null,
              addSpareCablesToLoom: () =>
                  dispatch(addSpareCablesToLoom(context, loom.uid)));
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
