import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
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
                store.dispatch(UpdateFixtureTypeName(id, newValue)));
      },
    );
  }

  List<FixtureTypeViewModel> _selectFixtureTypeItems(Store<AppState> store) {
    final typesInUseById = store.state.fixtureState.fixtures.values
        .map((fixture) => fixture.type)
        .groupListsBy((type) => type.uid);

    return typesInUseById.values
        .map((types) =>
            FixtureTypeViewModel(type: types.first, qty: types.length))
        .toList();
  }
}
