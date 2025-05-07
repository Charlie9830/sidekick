import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/data_selectors/select_loom_view_models.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/diffing/loom_diffing.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/view_models/cable_view_model.dart';
import 'package:sidekick/view_models/diff_app_state_view_model.dart';
import 'package:sidekick/view_models/loom_diffing_item_view_model.dart';
import 'package:sidekick/view_models/loom_diffing_view_model.dart';
import 'package:sidekick/view_models/loom_view_model.dart';

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
              onFileSelectedForCompare: diffViewModel.onFileSelectedForCompare,
              itemVms: _getLoomDiffs(
                  currentLoomVms: selectLoomViewModels(store).toModelMap(),
                  originalLoomVms: diffViewModel.originalLoomViewModels),
            );
          },
        );
      },
      converter: (Store<DiffAppState> store) {
        return DiffAppStateViewModel(
            originalLoomViewModels: selectLoomViewModels(store).toModelMap(),
            onFileSelectedForCompare: (path) =>
                store.dispatch(openProjectFile(context, false, path)));
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

    final originalCableVms =
        originalLoomVms.values.expand((vm) => vm.children).toModelMap();
    final currentCableVms =
        currentLoomVms.values.expand((vm) => vm.children).toModelMap();

    final cableDeltas = _getCableDeltas(originalCableVms, currentCableVms);

    return allIds.map((loomId) {
      final current = currentLoomVms[loomId];
      final original = originalLoomVms[loomId];

      if (original != null && current == null) {
        return LoomDiffingItemViewModel(
          current: null,
          original: original,
          deltas: {},
          overallDiff: DiffState.deleted,
          cableDeltas: const {},
        );
      }

      if (current != null && original == null) {
        return LoomDiffingItemViewModel(
          current: current,
          original: original,
          deltas: {},
          overallDiff: DiffState.added,
          cableDeltas: const {},
        );
      }

      return LoomDiffingItemViewModel(
        current: current,
        original: original,
        deltas: current!.loom.calculateDeltas(original!.loom),
        overallDiff: DiffState.unchanged,
        cableDeltas: cableDeltas,
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
          properties: const {},
        );
      }

      if (current.containsKey(cableId) == true &&
          original.containsKey(cableId) == false) {
        return CableDelta(
          uid: cableId,
          overallDiff: DiffState.added,
          properties: const {},
        );
      }

      return CableDelta(
        uid: cableId,
        overallDiff: DiffState.unchanged,
        properties: current[cableId]!
            .cable
            .calculateDeltas(original[cableId]!.cable)
            .map((delta) => delta.name)
            .toSet(),
      );
    });

    return diffs.toModelMap();
  }
}

class CableDelta extends ModelCollectionMember {
  @override
  final String uid;
  final DiffState overallDiff;
  final Set<DeltaPropertyName> properties;

  CableDelta({
    required this.uid,
    required this.overallDiff,
    required this.properties,
  });

  DiffState checkDiffState(DeltaPropertyName property) =>
      properties.contains(property) ? DiffState.changed : DiffState.unchanged;
}
