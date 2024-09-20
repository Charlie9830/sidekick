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
          onRangeSelectFixtures: (startUid, endUid) =>
              store.dispatch(rangeSelectFixtures(startUid, endUid)));
    });
  }

  List<FixtureTableRow> _selectFixtureRowVms(Store<AppState> store) {
    const String kBadLookupValue = 'NONE';
    String? lastLocationId;
    FixtureModel? prevFixture;

    final fixtures = store.state.fixtureState.fixtures.values.toList();
    return fixtures
        .map((fixture) {
          final location =
              store.state.fixtureState.locations[fixture.locationId];
          final powerMulti =
              store.state.fixtureState.powerMultiOutlets[fixture.powerMultiId];

          final vms = [
            if (lastLocationId != fixture.locationId)
              FixtureRowDividerVM(
                locationId: fixture.locationId,
                title: location?.name ?? kBadLookupValue,
                onSelectFixtures: () => store.dispatch(
                  SetSelectedFixtureIds(
                    store.state.fixtureState.fixtures.values
                        .where((element) =>
                            element.locationId == fixture.locationId)
                        .map((fixture) => fixture.uid)
                        .toSet(),
                  ),
                ),
              ),
            FixtureRowVM(
              selected:
                  store.state.navstate.selectedFixtureIds.contains(fixture.uid),
              fixtureUid: fixture.uid,
              sequence: fixture.sequence,
              fid: fixture.fid,
              address: fixture.dmxAddress.formatted,
              type: fixture.type.name,
              location: location?.name ?? kBadLookupValue,
              powerMulti: powerMulti?.name ?? kBadLookupValue,
              powerPatch: fixture.powerPatch,
              dataMulti: fixture.dataMulti,
              dataPatch: fixture.dataPatch,
              hasSequenceNumberBreak: prevFixture != null &&
                  prevFixture!.sequence + 1 != fixture.sequence,
              hasInvalidSequenceNumber: prevFixture != null && prevFixture!.sequence == fixture.sequence
            )
          ];

          lastLocationId = fixture.locationId;
          prevFixture = fixture;

          return vms;
        })
        .flattened
        .toList();
  }
}
