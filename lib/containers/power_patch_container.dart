import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
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
            selectedMultiOutlet: store.state.navstate.selectedMultiOutlet,
            multiOutlets: _selectMultiOutlets(store),
            maxSequenceBreak: store.state.fixtureState.maxSequenceBreak,
            onMaxSequenceBreakChanged: (newValue) =>
                store.dispatch(SetMaxSequenceBreak(newValue)),
            balanceTolerancePercent:
                (store.state.fixtureState.balanceTolerance * 100)
                    .round()
                    .toString(),
            onBalanceToleranceChanged: (newValue) =>
                store.dispatch(SetBalanceTolerance(newValue)),
            onGeneratePatch: () => store.dispatch(generatePatch()),
            onAddSpareOutlet: (uid) => store.dispatch(addSpareOutlet(uid)),
            onDeleteSpareOutlet: (uid) =>
                store.dispatch(deleteSpareOutlet(uid)),
            onMultiOutletPressed: (uid) =>
                store.dispatch(SetSelectedMultiOutlet(uid)));
      },
    );
  }

  Map<PowerMultiOutletModel, List<PowerOutletModel>> _selectMultiOutlets(
      Store<AppState> store) {
    return Map<PowerMultiOutletModel, List<PowerOutletModel>>.fromEntries(store
        .state.fixtureState.powerMultiOutlets.values
        .map((multiOutlet) => MapEntry(
            multiOutlet,
            store.state.fixtureState.outlets
                .where((outlet) => outlet.multiOutletId == multiOutlet.uid)
                .toList())));
  }
}
