import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/containers/select_power_patch_view_models.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/power_feed_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
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
          rows: selectPowerPatchViewModels(context, store),
          feedLoadings: _selectFeedLoadings(store),
          totalPhaseLoad: _calculatePhaseLoad(
              store.state.fixtureState.powerMultiOutlets.values.toList()),
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
          onDeleteSpareOutlet: (uid) => store.dispatch(deleteSpareOutlet(uid)),
          onMultiOutletPressed: (uid) =>
              store.dispatch(SetSelectedMultiOutlet(uid)),
          onToggleFeedsSidebarButtonPressed: () =>
              store.dispatch(ToggleFeedsDrawer()),
          isFeedsDrawerOpen: store.state.navstate.isFeedsDrawerOpen,
        );
      },
    );
  }

  List<FeedLoadViewModel> _selectFeedLoadings(Store<AppState> store) {
    final multiOutletsByFeedId =
        store.state.fixtureState.powerMultiOutlets.values.groupListsBy((multi) {
      final feedId = store
          .state.fixtureState.powerRacks[multi.parentRack.rackId]?.powerFeedId;

      return feedId == null || feedId.isEmpty
          ? const PowerFeedModel.defaultFeed().uid
          : feedId;
    });

    return multiOutletsByFeedId.entries.map((entry) {
      final feedId = entry.key;
      final multiOutlets = entry.value;

      return FeedLoadViewModel(
          load: _calculatePhaseLoad(multiOutlets),
          feed: store.state.fixtureState.powerFeeds[feedId]!);
    }).toList();
  }

  PhaseLoad _calculatePhaseLoad(List<PowerMultiOutletModel> multiOutlets) {
    final singleOutlets =
        multiOutlets.map((outlet) => outlet.children).flattened.toList();
    return PhaseLoad(
      PhaseLoad.calculateTotalPhaseLoad(singleOutlets, 1),
      PhaseLoad.calculateTotalPhaseLoad(singleOutlets, 2),
      PhaseLoad.calculateTotalPhaseLoad(singleOutlets, 3),
    );
  }
}
