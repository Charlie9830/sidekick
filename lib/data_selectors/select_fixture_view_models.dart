import 'package:collection/collection.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/view_models/fixture_table_view_model.dart';

List<FixtureTableRowViewModel> selectFixtureRowViewModels(
    Store<AppState> store) {
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
                mode: fixture.mode,
                powerPatch: fixture.powerPatch,
                location: location.name,
                hasSequenceNumberBreak: prevFixture != null &&
                    prevFixture.sequence + 1 != fixture.sequence,
                hasInvalidSequenceNumber: prevFixture != null &&
                    (prevFixture.sequence == fixture.sequence ||
                        accum.usedSequenceNumbers.contains(fixture.sequence)));

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
