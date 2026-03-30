import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/breakout_cabling/breakout_cabling.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';

class BreakoutCablingContainer extends StatelessWidget {
  const BreakoutCablingContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, BreakoutCablingViewModel>(
      builder: (context, viewModel) {
        return BreakoutCabling(
          vm: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        return BreakoutCablingViewModel(
          selectedLocationId:
              store.state.navstate.selectedBreakoutCablingLocationId,
          locationVms: _selectLocations(store),
          locationFixtureVms: _selectLocationFixtures(store),
          fixtureMap: store.state.fixtureState.fixtures,
        );
      },
    );
  }
}

List<LocationViewModel> _selectLocations(Store<AppState> store) {
  return store.state.fixtureState.locations.values
      .map((location) => LocationViewModel(
          location: location,
          onSelect: () =>
              store.dispatch(SetBreakoutCablingLocationId(location.uid))))
      .toList();
}

Map<String, FixtureViewModel> _selectLocationFixtures(Store<AppState> store) {
  return store.state.fixtureState.fixtures.values
      .where((fix) =>
          fix.locationId ==
          store.state.navstate.selectedBreakoutCablingLocationId)
      .map((fixture) => FixtureViewModel(
          fixture: fixture,
          fixtureType: store.state.fixtureState.fixtureTypes[fixture.typeId]!))
      .toModelMap();
}
