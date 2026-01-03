import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/racks/racks_screen.dart';
import 'package:sidekick/view_models/racks_view_model.dart';

class RacksContainer extends StatelessWidget {
  const RacksContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, RacksViewModel>(
      builder: (context, viewModel) {
        return RacksScreen(
          vm: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        return RacksViewModel(
            powerItemVms: _selectPowerRackItemViewModels(store, context));
      },
    );
  }
}

List<RackScreenItemBase> _selectPowerRackItemViewModels(
    Store<AppState> store, BuildContext context) {
  final locationsBySystemId = store.state.fixtureState.locations.values
      .groupListsBy((location) => location.powerSystemId);

  final powerRacksByParentSystemId = store.state.fixtureState.powerRacks.values
      .groupListsBy((rack) => rack.parentSystemId);

  return store.state.fixtureState.powerSystems.values
      .map((system) {
        return [
          PowerSystemItem(
              system: system, locations: locationsBySystemId[system.uid] ?? []),
          ...(powerRacksByParentSystemId[system.uid] ?? [])
              .map((rack) => PowerRackItem(
                  rack: rack,
                  children: rack.outletSlots.slots.map((slot) {
                    final index = slot.index;
                    final id = slot.outletId;

                    if (id.isEmpty) {
                      // Empty Outlet.
                      return PowerOutletItem(
                        index: index,
                        assigned: false,
                        locationName: '',
                        outletName: '',
                      );
                    }

                    final multiOutlet =
                        store.state.fixtureState.powerMultiOutlets[id]!;

                    final location = store
                        .state.fixtureState.locations[multiOutlet.locationId]!;

                    return PowerOutletItem(
                      index: index,
                      assigned: true,
                      outletName: multiOutlet.name,
                      locationName: location.name,
                    );
                  }).toList()))
        ];
      })
      .flattened
      .toList();
}
