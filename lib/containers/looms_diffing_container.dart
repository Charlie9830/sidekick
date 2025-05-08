import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/data_selectors/select_loom_view_models.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/diffing/loom_diffing.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/view_models/cable_view_model.dart';
import 'package:sidekick/view_models/diff_app_state_view_model.dart';
import 'package:sidekick/view_models/loom_diffing_item_view_model.dart';
import 'package:sidekick/view_models/loom_diffing_view_model.dart';
import 'package:sidekick/view_models/loom_view_model.dart';
import 'package:path/path.dart' as p;

class LoomsDiffingContainer extends StatelessWidget {
  const LoomsDiffingContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<DiffAppState, DiffAppStateViewModel>(
      builder: (context, diffViewModel) {
        return StoreConnector<AppState, LoomDiffingViewModel>(
          builder: (context, viewModel) {
            return LoomDiffing(vm: viewModel);
          },
          converter: (Store<AppState> store) {
            return LoomDiffingViewModel(
              onFileSelectedForCompare: (path) {
                store.dispatch(SetComparisonFilePath(path));
                diffViewModel.onFileSelectedForCompare(path);
              },
              initialDirectory: store.state.fileState.comparisonFilePath.isEmpty
                  ? store.state.fileState.lastUsedProjectDirectory
                  : p.dirname(store.state.fileState.comparisonFilePath),
              comparisonFilePath: store.state.fileState.comparisonFilePath,
              itemVms: _getLoomDiffs(
                  currentLoomVms: selectLoomViewModels(store).toModelMap(),
                  originalLoomVms: diffViewModel.originalLoomViewModels),
            );
          },
        );
      },
      converter: (Store<DiffAppState> diffStore) {
        return DiffAppStateViewModel(
            originalLoomViewModels:
                selectLoomViewModels(diffStore).toModelMap(),
            onFileSelectedForCompare: (path) =>
                diffStore.dispatch(openProjectFile(context, false, path)));
      },
    );
  }

  List<LoomDiffingItemViewModel> _getLoomDiffs(
      {required Map<String, LoomViewModel> currentLoomVms,
      required Map<String, LoomViewModel> originalLoomVms}) {
    final allIds = {
      ...currentLoomVms.values.map((vm) => vm.loom.uid),
      ...originalLoomVms.values.map((vm) => vm.loom.uid),
    };

    return allIds.map((loomId) {
      final current = currentLoomVms[loomId];
      final original = originalLoomVms[loomId];

      final originalChildCableVms = original?.children.toModelMap() ?? {};
      final currentChildCableVms = current?.children.toModelMap() ?? {};

      if (original != null && current == null) {
        return LoomDiffingItemViewModel(
          current: null,
          original: original,
          deltas: const PropertyDeltaSet.empty(),
          overallDiff: DiffState.deleted,
          cableDeltas:
              _getCableDeltas(originalChildCableVms, currentChildCableVms),
        );
      }

      if (current != null && original == null) {
        return LoomDiffingItemViewModel(
          current: current,
          original: original,
          deltas: const PropertyDeltaSet.empty(),
          overallDiff: DiffState.added,
          cableDeltas:
              _getCableDeltas(originalChildCableVms, currentChildCableVms),
        );
      }

      return LoomDiffingItemViewModel(
        current: current,
        original: original,
        deltas: current!.calculateDeltas(original!),
        overallDiff: DiffState.unchanged,
        cableDeltas:
            _getCableDeltas(originalChildCableVms, currentChildCableVms),
      );
    }).toList();
  }

  Map<String, CableDelta> _getCableDeltas(Map<String, CableViewModel> original,
      Map<String, CableViewModel> current) {
    final allIds = {
      ...original.keys.map((id) => id),
      ...current.keys.map((id) => id),
    };

    final diffs = allIds.map((cableId) {
      if (original.containsKey(cableId) == true &&
          current.containsKey(cableId) == false) {
        return CableDelta(
          uid: cableId,
          overallDiff: DiffState.deleted,
          properties: const PropertyDeltaSet.empty(),
        );
      }

      if (current.containsKey(cableId) == true &&
          original.containsKey(cableId) == false) {
        return CableDelta(
          uid: cableId,
          overallDiff: DiffState.added,
          properties: const PropertyDeltaSet.empty(),
        );
      }

      return CableDelta(
          uid: cableId,
          overallDiff: DiffState.unchanged,
          properties: current[cableId]!.calculateDeltas(original[cableId]!));
    });

    return diffs.toModelMap();
  }
}

class CableDelta extends ModelCollectionMember {
  @override
  final String uid;
  final DiffState overallDiff;
  final PropertyDeltaSet properties;

  CableDelta({
    required this.uid,
    required this.overallDiff,
    required this.properties,
  });
}
