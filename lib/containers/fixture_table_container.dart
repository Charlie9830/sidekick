// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/home/fixture_table/fixture_table.dart';
import 'package:sidekick/view_models/fixture_table_view_model.dart';

class FixtureTableContainer extends StatelessWidget {
  const FixtureTableContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, FixtureTableViewModel>(
        builder: (context, viewModel) {
      return FixtureTable(
        vm: viewModel,
      );
    }, converter: (Store<AppState> store) {
      return FixtureTableViewModel(
          selectedFixtureIds: store.state.navstate.selectedFixtureIds,
          rowVms: _selectFixtureRowVms(store),
          onSetSequenceButtonPressed: () =>
              store.dispatch(setSequenceNumbers(context)),
          hasSelections: store.state.navstate.selectedFixtureIds.length ==
                  store.state.fixtureState.fixtures.values.length
              ? true
              : (store.state.navstate.selectedFixtureIds.isEmpty
                  ? false
                  : null),
          onSelectedFixturesChanged: (ids) =>
              store.dispatch(SetSelectedFixtureIds(ids)),
          onSelectAllFixtures: () => store.dispatch(SetSelectedFixtureIds(store
              .state.fixtureState.fixtures.values
              .map((fixture) => fixture.uid)
              .toSet())),
          onRangeSelectFixtures: (startUid, endUid, isAdditive) => store
              .dispatch(rangeSelectFixtures(startUid, endUid, isAdditive)));
    });
  }

  List<FixtureTableRow> _selectFixtureRowVms(Store<AppState> store) {
    const String kBadLookupValue = 'NONE';

    final fixturesByLocationId = store.state.fixtureState.fixtures.values
        .groupListsBy((fixture) => fixture.locationId);

    return store.state.fixtureState.locations.values
        .map((location) {
          final associatedFixtures =
              (fixturesByLocationId[location.uid] ?? []).sorted();

          return [
            FixtureRowDividerVM(
              locationId: location.uid,
              title: location.name,
              onSelectFixtures: () => store.dispatch(
                SetSelectedFixtureIds(
                  associatedFixtures.map((fixture) => fixture.uid).toSet(),
                ),
              ),
            ),
            ...associatedFixtures.fold<FixtureVMAccumulator>(
                FixtureVMAccumulator.empty(), (accum, fixture) {
              final prevFixture = accum.prevFixture;

              final vm = FixtureViewModel(
                  selected: store.state.navstate.selectedFixtureIds
                      .contains(fixture.uid),
                  uid: fixture.uid,
                  sequence: fixture.sequence,
                  fid: fixture.fid,
                  address: fixture.dmxAddress.formatted,
                  type: store.state.fixtureState.fixtureTypes[fixture.typeId]
                          ?.name ??
                      '',
                  powerPatch: fixture.powerPatch,
                  location: location.name,
                  hasSequenceNumberBreak: prevFixture != null &&
                      prevFixture.sequence + 1 != fixture.sequence,
                  hasInvalidSequenceNumber: prevFixture != null &&
                      (prevFixture.sequence == fixture.sequence ||
                          accum.usedSequenceNumbers
                              .contains(fixture.sequence)));

              return accum.copyWith(prevFixture: fixture, usedSequenceNumbers: {
                ...accum.usedSequenceNumbers,
                fixture.sequence
              }, vms: [
                ...accum.vms,
                vm,
              ]);
            }).vms,
          ];
        })
        .flattened
        .toList();
  }
}

class FixtureVMAccumulator {
  final List<FixtureViewModel> vms;
  final Set<int> usedSequenceNumbers;
  final FixtureModel? prevFixture;

  FixtureVMAccumulator({
    required this.vms,
    required this.usedSequenceNumbers,
    required this.prevFixture,
  });

  FixtureVMAccumulator.empty()
      : vms = const [],
        usedSequenceNumbers = {},
        prevFixture = null;

  FixtureVMAccumulator copyWith({
    List<FixtureViewModel>? vms,
    Set<int>? usedSequenceNumbers,
    FixtureModel? prevFixture,
  }) {
    return FixtureVMAccumulator(
      vms: vms ?? this.vms,
      usedSequenceNumbers: usedSequenceNumbers ?? this.usedSequenceNumbers,
      prevFixture: prevFixture ?? this.prevFixture,
    );
  }
}
