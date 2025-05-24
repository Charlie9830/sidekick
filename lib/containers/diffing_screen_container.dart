import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/containers/select_power_patch_view_models.dart';
import 'package:sidekick/data_selectors/select_fixture_view_models.dart';
import 'package:sidekick/data_selectors/select_loom_view_models.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/diffing/diffing_screen.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/view_models/cable_view_model.dart';
import 'package:sidekick/view_models/diff_app_state_view_model.dart';
import 'package:sidekick/view_models/fixture_diffing_item_view_model.dart';
import 'package:sidekick/view_models/fixture_table_view_model.dart';
import 'package:sidekick/view_models/loom_diffing_item_view_model.dart';
import 'package:sidekick/view_models/diffing_screen_view_model.dart';
import 'package:sidekick/view_models/loom_view_model.dart';
import 'package:path/path.dart' as p;
import 'package:sidekick/view_models/patch_diffing_item_view_model.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';

class DiffingScreenContainer extends StatelessWidget {
  const DiffingScreenContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<DiffAppState, DiffAppStateViewModel>(
      builder: (context, diffViewModel) {
        return StoreConnector<AppState, DiffingScreenViewModel>(
          builder: (context, viewModel) {
            return DiffingScreen(viewModel: viewModel);
          },
          converter: (Store<AppState> store) {
            return DiffingScreenViewModel(
                onFileSelectedForCompare: (path) {
                  store.dispatch(SetComparisonFilePath(path));
                  diffViewModel.onFileSelectedForCompare(path);
                },
                initialDirectory:
                    store.state.fileState.comparisonFilePath.isEmpty
                        ? store.state.fileState.lastUsedProjectDirectory
                        : p.dirname(store.state.fileState.comparisonFilePath),
                comparisonFilePath: store.state.fileState.comparisonFilePath,
                patchItemVms: _getPatchDiffs(
                  currentPatchVms:
                      selectPowerPatchViewModels(store).toModelMap(),
                  originalPatchVms: diffViewModel.originalPatchViewModels,
                ),
                loomItemVms: _getLoomDiffs(
                    currentLoomVms: selectLoomViewModels(store).toModelMap(),
                    originalLoomVms: diffViewModel.originalLoomViewModels),
                fixtureItemVms: _getFixtureDiffs(
                  currentFixtureVms:
                      selectFixtureRowViewModels(store).toModelMap(),
                  originalFixtureVms: diffViewModel.originalFixtureViewModels,
                ));
          },
        );
      },
      converter: (Store<DiffAppState> diffStore) {
        return DiffAppStateViewModel(
          originalLoomViewModels: selectLoomViewModels(diffStore).toModelMap(),
          onFileSelectedForCompare: (path) =>
              diffStore.dispatch(openProjectFile(context, false, path)),
          originalPatchViewModels:
              selectPowerPatchViewModels(diffStore).toModelMap(),
          originalFixtureViewModels:
              selectFixtureRowViewModels(diffStore).toModelMap(),
        );
      },
    );
  }

  List<FixtureDiffingItemViewModel> _getFixtureDiffs({
    required Map<String, FixtureTableRowViewModel> currentFixtureVms,
    required Map<String, FixtureTableRowViewModel> originalFixtureVms,
  }) {
    final allIds = {
      ...currentFixtureVms.values.map((vm) => vm.uid),
      ...originalFixtureVms.values.map((vm) => vm.uid),
    };

    return allIds.map((rowId) {
      final current = currentFixtureVms[rowId];
      final original = originalFixtureVms[rowId];

      if (original != null && current == null) {
        return FixtureDiffingItemViewModel(
          current: null,
          original: original,
          overallDiff: DiffState.deleted,
        );
      }

      if (current != null && original == null) {
        return FixtureDiffingItemViewModel(
          current: current,
          original: original,
          overallDiff: DiffState.added,
        );
      }

      return FixtureDiffingItemViewModel(
        current: current,
        original: original,
        deltas: current!.calculateDeltas(original!),
        overallDiff: DiffState.unchanged,
      );
    }).toList();
  }

  List<PatchDiffingItemViewModel> _getPatchDiffs({
    required Map<String, PowerPatchRowViewModel> currentPatchVms,
    required Map<String, PowerPatchRowViewModel> originalPatchVms,
  }) {
    final allIds = {
      ...currentPatchVms.values.map((vm) => _extractPowerPatchUid(vm)),
      ...originalPatchVms.values.map((vm) => _extractPowerPatchUid(vm)),
    };

    return allIds.map((rowId) {
      final current = currentPatchVms[rowId];
      final original = originalPatchVms[rowId];

      if (original != null && current == null) {
        return PatchDiffingItemViewModel(
          current: null,
          original: original,
          deltas: const PropertyDeltaSet.empty(),
          overallDiff: DiffState.deleted,
        );
      }

      if (current != null && original == null) {
        return PatchDiffingItemViewModel(
          current: current,
          original: original,
          deltas: const PropertyDeltaSet.empty(),
          overallDiff: DiffState.added,
        );
      }

      return PatchDiffingItemViewModel(
          current: current,
          original: original,
          deltas: current!.calculateDeltas(original!),
          overallDiff: DiffState.unchanged,
          outletDeltas: _getOutletDeltas(original: original, current: current));
    }).toList();
  }

  String _extractPowerPatchUid(PowerPatchRowViewModel powerPatch) {
    return switch (powerPatch) {
      LocationRowViewModel i => i.location.uid,
      MultiOutletRowViewModel i => i.multiOutlet.uid,
      _ => throw UnimplementedError(),
    };
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

  List<OutletDelta> _getOutletDeltas(
      {required PowerPatchRowViewModel original,
      required PowerPatchRowViewModel current}) {
    if (original is MultiOutletRowViewModel == false ||
        current is MultiOutletRowViewModel == false) {
      return [];
    }

    if (original is MultiOutletRowViewModel &&
        current is MultiOutletRowViewModel) {
      return current.childOutlets.mapIndexed((index, currentChild) {
        final originalChild = original.childOutlets[index];

        return OutletDelta(
            multiPatchIndex: index,
            properties: currentChild.calculateDeltas(originalChild));
      }).toList();
    }

    return [];
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

class CableDelta implements ModelCollectionMember {
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

class OutletDelta {
  final int multiPatchIndex;
  final PropertyDeltaSet properties;

  OutletDelta({
    required this.multiPatchIndex,
    required this.properties,
  });
}
