import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide IndexedSlot;
import 'package:sidekick/redux/models/fixture_type_pool_model.dart';

import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/loom_stock_model.dart';
import 'package:sidekick/redux/models/permanent_loom_composition.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/sequencer_dialog/sequencer_dialog.dart';
import 'package:sidekick/screens/setup_quantities_dialog/setup_quantities_dialog.dart';
import 'package:sidekick/utils/get_uid.dart';

ThunkAction<AppState> createFixtureTypePool() {
  return (Store<AppState> store) async {
    final newPool = FixtureTypePoolModel(
      uid: getUid(),
      name: 'New Pool',
      items: {},
    );

    store.dispatch(
      SetFixtureTypePools(
        store.state.fixtureState.fixtureTypePools.clone()
          ..addAll({newPool.uid: newPool}),
      ),
    );
  };
}

ThunkAction<AppState> showSetupQuantitiesDialog(BuildContext context) {
  return (Store<AppState> store) async {
    final items = store.state.fixtureState.loomStock.isEmpty
        ? PermanentLoomComposition.buildAllLoomQuantities()
        : store.state.fixtureState.loomStock.values.toList();

    final vms = items
        .map(
          (item) => LoomStockItemViewModel(
            item: item,
            parentComposition:
                PermanentLoomComposition.byName[item.compositionName]!,
          ),
        )
        .toList();

    final sortedVms = [
      // Socas
      ...vms
          .where((vm) => vm.parentComposition.socaWays > 0)
          .groupListsBy((vm) => vm.parentComposition.powerWays)
          .values
          .map((group) => [...group, LoomStockItemDividerViewModel()])
          .flattened,

      // 6ways.
      ...vms
          .where((vm) => vm.parentComposition.wieland6Ways > 0)
          .groupListsBy((vm) => vm.parentComposition.powerWays)
          .values
          .map((group) => [...group, LoomStockItemDividerViewModel()])
          .flattened,
    ];

    final result = await showDialog(
      context: context,
      builder: (innerContext) => SetupQuantitiesDialog(items: sortedVms),
    );

    if (result is Map<String, LoomStockModel>) {
      store.dispatch(SetLoomStock(result));
    }
  };
}

ThunkAction<AppState> rangeSelectFixtures(
  String startUid,
  String endUid,
  bool isAdditive,
) {
  return (Store<AppState> store) async {
    final fixtures = store.state.fixtureState.fixtures.values.toList();

    if (fixtures.isEmpty) {
      return;
    }

    if (fixtures.length == 1 || startUid == endUid) {
      store.dispatch(SetSelectedFixtureIds({startUid}));
      return;
    }

    final rawStartIndex = fixtures.indexWhere(
      (fixture) => fixture.uid == startUid,
    );
    final rawEndIndex = fixtures.indexWhere((fixture) => fixture.uid == endUid);

    if (rawStartIndex == -1 || rawEndIndex == -1) {
      return;
    }

    final (coercedStartIndex, coercedEndIndex) = rawStartIndex > rawEndIndex
        ? (rawEndIndex, rawStartIndex)
        : (rawStartIndex, rawEndIndex);

    final ids = fixtures
        .sublist(
          coercedStartIndex,
          coercedEndIndex + 1 <= fixtures.length ? coercedEndIndex + 1 : null,
        )
        .map((fixture) => fixture.uid)
        .toSet();

    if (isAdditive) {
      ids.addAll(store.state.navstate.selectedFixtureIds);
    }

    // Optionally reverse the collection if the Range Selection itself was inverted.
    store.dispatch(
      SetSelectedFixtureIds(
        rawStartIndex > rawEndIndex ? ids.toList().reversed.toSet() : ids,
      ),
    );
  };
}

ThunkAction<AppState> setSequenceNumbers(BuildContext context) {
  return (Store<AppState> store) async {
    final selectedFixtures = store.state.navstate.selectedFixtureIds
        .map((id) => store.state.fixtureState.fixtures[id]!)
        .toList();

    final result = await showDialog(
      context: context,
      builder: (context) => SequencerDialog(
        fixtures: selectedFixtures,
        fixtureTypes: store.state.fixtureState.fixtureTypes,
        fixtureGeometries: store.state.fixtureState.fixtureGeometries,
        nextAvailableSequenceNumber: _findNextAvailableSequenceNumber(
          selectedFixtures.map((fix) => fix.sequence).toList(),
        ),
      ),
    );

    if (result == null) {
      return;
    }

    if (result is Map<int, FixtureModel>) {
      final existingFixtures = store.state.fixtureState.fixtures.clone();

      for (final entry in result.entries) {
        final newSeqNumber = entry.key;
        final fixtureId = entry.value.uid;

        existingFixtures.update(
          fixtureId,
          (fixture) => fixture.copyWith(sequence: newSeqNumber),
        );
      }

      final sortedFixtures = FixtureModel.sort(
        existingFixtures,
        store.state.fixtureState.locations,
      );

      store.dispatch(SetFixtures(sortedFixtures));
    }
  };
}

int _findNextAvailableSequenceNumber(List<int> sequenceNumbers) {
  if (sequenceNumbers.isEmpty) {
    return 1;
  }

  if (sequenceNumbers.length == 1) {
    return sequenceNumbers.first + 1;
  }

  final sortedSequenceNumbers = sequenceNumbers.sorted((a, b) => a - b);

  for (final (index, seq) in sortedSequenceNumbers.indexed) {
    if (index + 1 < sortedSequenceNumbers.length) {
      final nextSeq = sortedSequenceNumbers[index + 1];

      if (seq + 1 != nextSeq) {
        return seq + 1;
      }
    }
  }

  return sortedSequenceNumbers.last + 1;
}
