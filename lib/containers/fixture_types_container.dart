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
            showAllFixtureTypes: store.state.navstate.showAllFixtureTypes,
            onShowAllFixtureTypesChanged: (newValue) =>
                store.dispatch(SetShowAllFixtureTypes(newValue)));
      },
    );
  }

  List<FixtureTypeViewModel> _selectFixtureTypeItems(Store<AppState> store) {
    List<FixtureTypeModel> fixtureTypes;
    if (store.state.navstate.showAllFixtureTypes) {
      fixtureTypes = store.state.fixtureState.fixtureTypes.values.toList();
    } else {
      final Set<String> inUseFixtureTypeIds = store
          .state.fixtureState.fixtures.values
          .map((fixture) => fixture.typeId)
          .toSet();

      fixtureTypes = inUseFixtureTypeIds
          .map((id) => store.state.fixtureState.fixtureTypes[id]!)
          .toList();
    }

    return fixtureTypes
        .map((type) => FixtureTypeViewModel(
              qty: store.state.fixtureState.fixtures.values
                  .where((fixture) => fixture.typeId == type.uid)
                  .length,
              type: type,
              onMaxPairingsChanged: (newValue) => store
                  .dispatch(UpdateFixtureTypeMaxPiggybacks(type.uid, newValue)),
              onShortNameChanged: (newValue) => store
                  .dispatch(UpdateFixtureTypeShortName(type.uid, newValue)),
            ))
        .toList();
  }
}
