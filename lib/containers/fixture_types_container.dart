import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/fixture_types/fixture_types.dart';
import 'package:sidekick/view_models/fixture_types_view_model.dart';

class FixtureTypesContainer extends StatelessWidget {
  const FixtureTypesContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, FixtureTypesViewModel>(
      builder: (context, viewModel) {
        return FixtureTypes(
          vm: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        return FixtureTypesViewModel(
            itemVms: _selectFixtureTypeItems(store),
            onMaxPairingsChanged: (id, newValue) =>
                store.dispatch(UpdateFixtureTypeMaxPiggybacks(id, newValue)),
            onNameChanged: (id, newValue) =>
                store.dispatch(UpdateFixtureTypeName(id, newValue)),
            onShortNameChanged: (id, newValue) =>
                store.dispatch(UpdateFixtureTypeShortName(id, newValue)),
            showAllFixtureTypes: store.state.navstate.showAllFixtureTypes,
            onShowAllFixtureTypesChanged: (newValue) =>
                store.dispatch(SetShowAllFixtureTypes(newValue)));
      },
    );
  }

  List<FixtureTypeViewModel> _selectFixtureTypeItems(Store<AppState> store) {
    return store.state.fixtureState.fixtureTypes.values
        .where((type) =>
            store.state.navstate.showAllFixtureTypes ? true : type.inUse)
        .map((type) => FixtureTypeViewModel(
              qty: store.state.fixtureState.fixtures.values
                  .where((fixture) => fixture.typeId == type.uid)
                  .length,
              type: type,
            ))
        .toList();
  }
}
