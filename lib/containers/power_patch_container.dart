import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/power_patch/power_patch.dart';
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
            rows: _selectRows(store),
            phaseLoad: _selectPhaseLoad(store),
            maxSequenceBreak: store.state.fixtureState.maxSequenceBreak,
            onMaxSequenceBreakChanged: (newValue) =>
                store.dispatch(SetMaxSequenceBreak(newValue)),
            balanceTolerancePercent:
                (store.state.fixtureState.balanceTolerance * 100)
                    .round()
                    .toString(),
            onBalanceToleranceChanged: (newValue) =>
                store.dispatch(SetBalanceTolerance(newValue)),
            onAddSpareOutlet: (uid) => store.dispatch(addSpareOutlet(uid)),
            onDeleteSpareOutlet: (uid) =>
                store.dispatch(deleteSpareOutlet(uid)),
            onMultiOutletPressed: (uid) =>
                store.dispatch(SetSelectedMultiOutlet(uid)));
      },
    );
  }

  PhaseLoad _selectPhaseLoad(Store<AppState> store) {
    final outlets = store.state.fixtureState.powerMultiOutlets.values
        .map((multi) => multi.children)
        .flattened
        .toList();

    return PhaseLoad(
      PhaseLoad.calculateTotalPhaseLoad(outlets, 1),
      PhaseLoad.calculateTotalPhaseLoad(outlets, 2),
      PhaseLoad.calculateTotalPhaseLoad(outlets, 3),
    );
  }

  List<PowerPatchRow> _selectRows(Store<AppState> store) {
    return store.state.fixtureState.locations.values
        .map((location) {
          final associatedMultis = store
              .state.fixtureState.powerMultiOutlets.values
              .where((multi) => multi.locationId == location.uid)
              .toList();

          return [
            LocationRow(
                location: location,
                multiCount: associatedMultis.length,
                onLockChanged: (value) =>
                    store.dispatch(SetLocationPowerLock(location.uid, value))),
            ...associatedMultis.map((multi) => MultiOutletRow(
                multi,
                multi.children
                    .map(
                      (outlet) => PowerOutletVM(
                          outlet: outlet,
                          fixtureVm: outlet.fixtureIds.map((id) {
                            final fixture =
                                store.state.fixtureState.fixtures[id]!;

                            return FixtureOutletVM(
                                fixture: fixture,
                                type: store.state.fixtureState
                                    .fixtureTypes[fixture.typeId]!);
                          }).toList()),
                    )
                    .toList())),
          ];
        })
        .flattened
        .toList();
  }
}
