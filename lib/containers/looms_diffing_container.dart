import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/data_selectors/select_cable_and_loom_rows.dart';
import 'package:sidekick/data_selectors/select_loom_name.dart';
import 'package:sidekick/diffing/diff_pair.dart';
import 'package:sidekick/diffing/union_proxy.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/app_store.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/diffing/diffing.dart';
import 'package:sidekick/screens/diffing/loom_diffing.dart';
import 'package:sidekick/view_models/diffing_view_model.dart';
import 'package:sidekick/view_models/loom_diffing_item_view_model.dart';
import 'package:sidekick/view_models/loom_diffing_view_model.dart';
import 'package:sidekick/view_models/loom_item_view_model.dart';

class LoomsDiffingContainer extends StatelessWidget {
  const LoomsDiffingContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, LoomDiffingViewModel>(
      builder: (context, viewModel) {
        return LoomDiffing(
          vm: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        return LoomDiffingViewModel(
          itemVms: _selectItems(store, context),
        );
      },
    );
  }

  List<LoomDiffingItemViewModel> _selectItems(
      Store<AppState> store, BuildContext context) {
    final originalVms = selectCableAndLoomRows(
      context: context,
      fixtureState: store.state.diffingState.original,
      dispatch: dispatchStub,
    );

    final currentVms = selectCableAndLoomRows(
      context: context,
      fixtureState: store.state.fixtureState,
      dispatch: dispatchStub,
    );

    final originalVmLookup = Map<String, LoomItemViewModel>.fromEntries(
        originalVms.map((vm) => MapEntry(vm.uid, vm)));

    final currentVmLookup = Map<String, LoomItemViewModel>.fromEntries(
        currentVms.map((vm) => MapEntry(vm.uid, vm)));

    final deletedOriginalVmIds = originalVmLookup.keys
        .where((key) => currentVmLookup.containsKey(key) == false);

    final diffPairs = [
      ...currentVms.map((vm) => DiffPair(vm, originalVmLookup[vm.uid])),
      ...deletedOriginalVmIds
          .map((id) => originalVmLookup[id])
          .nonNulls
          .map((vm) => DiffPair<LoomItemViewModel>(null, vm)),
    ];
    
    return diffPairs
        .map((pair) => LoomDiffingItemViewModel(
              current: pair.current,
              original: pair.original,
              deltas: pair.deltas,
            ))
        .toList();
  }
}
