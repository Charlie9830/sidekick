import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/power_patch/power_patch.dart';
import 'package:sidekick/view_models/power_patch_row_view_model.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';

class PowerPatchContainer extends StatelessWidget {
  const PowerPatchContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, PowerPatchViewModel>(
      builder: (context, viewModel) {
        return PowerPatch(
          vm: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        return PowerPatchViewModel(
            rowViewModels: _selectRowViewModels(store),
            maxSequenceBreak: store.state.fixtureState.maxSequenceBreak,
            onMaxSequenceBreakChanged: (newValue) =>
                store.dispatch(SetMaxSequenceBreak(newValue)),
            balanceTolerancePercent:
                (store.state.fixtureState.balanceTolerance * 100)
                    .round()
                    .toString(),
            onBalanceToleranceChanged: (newValue) =>
                store.dispatch(SetBalanceTolerance(newValue)),
            onRowSelected: (uid) => store.dispatch(SelectPatchRow(uid)),
            onGeneratePatch: () => store.dispatch(generatePatch()),
            onAddSpareOutlet: (index) => store.dispatch(addSpareOutlet(index)),
            onDeleteSpareOutlet: (index) =>
                store.dispatch(deleteSpareOutlet(index)));
      },
    );
  }

  List<PowerPatchRowViewModel> _selectRowViewModels(Store<AppState> store) {
    return store.state.fixtureState.outlets.map((outlet) {
      final multiOutlet =
          store.state.fixtureState.powerMultiOutlets[outlet.multiOutletId] ??
              const PowerMultiOutletModel.none();

      final location =
          store.state.fixtureState.locations[multiOutlet.locationId] ??
              const LocationModel.none();

      return PowerPatchRowViewModel(
        outlet: outlet,
        multiOutlet: multiOutlet,
        location: location,
      );
    }).toList();
  }
}
