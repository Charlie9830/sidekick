import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/locations/locations.dart';
import 'package:sidekick/view_models/locations_view_model.dart';

class LocationsContainer extends StatelessWidget {
  const LocationsContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, LocationsViewModel>(
      builder: (context, viewModel) {
        return Locations(
          vm: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        return LocationsViewModel(
          outlets: store.state.fixtureState.outlets,
          locations: store.state.fixtureState.locations,
          onMultiPrefixChanged: (location, newValue) => store.dispatch(
            UpdateLocationMultiPrefix(location, newValue),
          ),
        );
      },
    );
  }
}
