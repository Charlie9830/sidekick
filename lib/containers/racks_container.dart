import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/containers/rack_selectors.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/racks/racks.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';

import 'package:sidekick/view_models/racks_screen_view_model.dart';

class RacksContainer extends StatelessWidget {
  const RacksContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, RacksScreenViewModel>(
      builder: (context, viewModel) {
        return Racks(
          viewModel: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        final cablesByOutletId = store.state.fixtureState.cables.values
            .groupListsBy((e) => e.outletId);

        return RacksScreenViewModel(
            assignableItems: Map<String,
                ItemData<String, PowerMultiOutletViewModel>>.fromEntries(
              store.state.fixtureState.powerMultiOutlets.values.map(
                (outlet) => MapEntry(
                  outlet.uid,
                  ItemData<String, PowerMultiOutletViewModel>(
                    id: outlet.uid,
                    item: PowerMultiOutletViewModel(
                      multi: outlet,
                      assigned: false,
                      parentLocation: store
                          .state.fixtureState.locations[outlet.locationId]!,
                      selected: false,
                      hasRootCable:
                          cablesByOutletId[outlet.uid]?.isNotEmpty ?? false,
                    ),
                  ),
                ),
              ),
            ),
            powerRacks: selectPowerRacks(context: context, store: store),
            sidebarItems:
                selectPowerMultiSidebarItems(context: context, store: store),
            onAddPowerRack: () => store.dispatch(addPowerRack(context)));
      },
    );
  }
}
