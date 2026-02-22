import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/state/app_state.dart';
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
