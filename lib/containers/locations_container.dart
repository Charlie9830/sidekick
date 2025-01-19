import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
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
            itemVms: _selectLocationItems(store),
            onMultiPrefixChanged: (locationId, newValue) => store.dispatch(
                  updateLocationMultiPrefix(locationId, newValue),
                ),
            onLocationColorChanged: (locationId, color) => store.dispatch(
                  UpdateLocationColor(locationId, color),
                ),
            onLocationDelimiterChanged: (locationId, newValue) => store
                .dispatch(updateLocationMultiDelimiter(locationId, newValue)));
      },
    );
  }

  List<LocationItemViewModel> _selectLocationItems(Store<AppState> store) {
    return store.state.fixtureState.locations.values.map((location) {
      return LocationItemViewModel(
        location: location,
        powerMultiCount: store.state.fixtureState.powerMultiOutlets.values
            .where((outlet) => outlet.locationId == location.uid)
            .length,
        dataMultiCount: store.state.fixtureState.dataMultis.values
            .where((multi) => multi.locationId == location.uid)
            .length,
        dataPatchCount: store.state.fixtureState.dataPatches.values
            .where((patch) =>
                patch.locationId == location.uid && patch.isSpare == false)
            .length,
      );
    }).toList();
  }
}
