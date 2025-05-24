// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/data_selectors/select_fixture_view_models.dart';

import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
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
          rowVms: selectFixtureRowViewModels(store),
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
}
