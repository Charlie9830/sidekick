import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
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
            patches: store.state.fixtureState.patches,
            outlets: store.state.fixtureState.outlets,
            maxSequenceBreak: store.state.fixtureState.maxSequenceBreak,
            onMaxSequenceBreakChanged: (newValue) => store.dispatch(SetMaxSequenceBreak(newValue)),
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
}
