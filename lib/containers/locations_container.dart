import 'package:collection/collection.dart';
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
            itemVms: _selectLocationItems(context, store),
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

  List<LocationItemViewModel> _selectLocationItems(
      BuildContext context, Store<AppState> store) {
    final powerMultisByLocation = store
        .state.fixtureState.powerMultiOutlets.values
        .groupListsBy((item) => item.locationId);
    final dataMultisByLocation = store.state.fixtureState.dataMultis.values
        .groupListsBy((item) => item.locationId);
    final dataPatchesByLocation = store.state.fixtureState.dataPatches.values
        .groupListsBy((item) => item.locationId);
    final motorsByLocation = store.state.fixtureState.hoists.values
        .groupListsBy((item) => item.locationId);

    return store.state.fixtureState.locations.values.map((location) {
      return LocationItemViewModel(
          location: location,
          powerMultiCount: powerMultisByLocation[location.uid]?.length ?? 0,
          dataMultiCount: dataMultisByLocation[location.uid]?.length ?? 0,
          dataPatchCount: dataPatchesByLocation[location.uid]?.length ?? 0,
          motorCount: motorsByLocation[location.uid]?.length ?? 0,
          otherLocationNames: location.isHybrid
              ? location.hybridIds
                  .map((id) => store.state.fixtureState.locations[id])
                  .nonNulls
                  .map((location) => location.name)
                  .toList()
              : const [],
          onDelete: () => store.dispatch(deleteLocation(context, location.uid)),
          onEditName: () =>
              store.dispatch(editRiggingLocation(context, location)));
    }).toList();
  }
}
