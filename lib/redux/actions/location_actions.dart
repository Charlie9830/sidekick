import 'dart:collection';

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide IndexedSlot;

import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/generic_dialog/show_generic_dialog.dart';
import 'package:sidekick/open_shad_sheet.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/hoists/add_or_edit_rigging_location.dart';
import 'package:sidekick/screens/locations/reorder_locations_sheet.dart';
import 'package:sidekick/screens/location_overrides_dialog/location_overrides_dialog.dart';
import 'package:sidekick/show_dialog.dart';
import 'package:sidekick/utils/get_uid.dart';

ThunkAction<AppState> deleteLocation(BuildContext context, String locationId) {
  return (Store<AppState> store) async {
    final location = store.state.fixtureState.locations[locationId];

    if (location == null || location.isRiggingOnlyLocation == false) {
      return;
    }

    final result = await showGenericDialog(
      context: context,
      title: 'Delete Location',
      message:
          'Are you sure you want to delete ${location.name}. All motors and cables associated with this location will be deleted as well.',
      affirmativeText: 'Delete',
      destructiveAffirmative: true,
      declineText: 'Cancel',
    );

    if (result == true) {
      store.dispatch(RemoveLocation(location: location));
    }
  };
}

ThunkAction<AppState> editRiggingLocation(
  BuildContext context,
  LocationModel location,
) {
  return (Store<AppState> store) async {
    if (location.isRiggingOnlyLocation == false) {
      return;
    }

    final result = await openShadSheet(
      context: context,
      builder: (context) =>
          AddOrEditRiggingLocation(existingLocation: location),
    );

    if (result is AddRiggingLocationDialogResult) {
      final updatedLocation = location.copyWith(
        color: result.labelColor,
        name: result.name,
        multiPrefix: result.prefix,
        delimiter: result.delimiter,
      );

      final updatedPrimaryLocations = store.state.fixtureState.locations.clone()
        ..update(location.uid, (_) => updatedLocation);

      final associatedHybridLocations = store
          .state
          .fixtureState
          .locations
          .values
          .where(
            (item) => item.isHybrid && item.hybridIds.contains(location.uid),
          );

      final updatedHybridLocations = associatedHybridLocations.map(
        (hybridLoc) => hybridLoc.copyWith(
          name: LocationModel.getHybridLocationName(
            hybridLoc.hybridIds
                .map((id) => updatedPrimaryLocations[id])
                .nonNulls
                .toList(),
          ),
        ),
      );

      store.dispatch(
        SetLocations(
          updatedPrimaryLocations..addAll(updatedHybridLocations.toModelMap()),
        ),
      );
    }
  };
}

ThunkAction<AppState> showReorderLocationsSheet(BuildContext context) {
  return (Store<AppState> store) async {
    final result = await openShadSheet<List<String>>(
      context: context,
      builder: (context) => ReorderLocationsSheet(
        locations: store.state.fixtureState.locations.values.toList(),
      ),
    );

    if (result != null) {
      store.dispatch(ReorderLocations(result));
    }
  };
}

ThunkAction<AppState> addRiggingLocation(BuildContext context) {
  return (Store<AppState> store) async {
    final result = await openShadSheet(
      context: context,
      builder: (context) => const AddOrEditRiggingLocation(),
    );

    if (result is AddRiggingLocationDialogResult) {
      final newLocation = LocationModel(
        uid: getUid(),
        color: result.labelColor,
        name: result.name,
        multiPrefix: result.prefix,
        delimiter: result.delimiter,
        isRiggingOnlyLocation: true,
      );

      store.dispatch(
        SetLocations(
          store.state.fixtureState.locations.clone()
            ..addAll({newLocation.uid: newLocation}),
        ),
      );
    }
  };
}

ThunkAction<AppState> showLocationOverridesDialog(
  BuildContext context,
  String locationId,
) {
  return (Store<AppState> store) async {
    final result = await showDialog(
      context: context,
      fullScreen: true,
      builder: (context) => LocationOverridesDialog(
        initialLocationId: locationId,
        fixtureTypePools: store.state.fixtureState.fixtureTypePools,
        locations: store.state.fixtureState.locations,
        fixtures: store.state.fixtureState.fixtures,
        fixtureTypes: store.state.fixtureState.fixtureTypes,
        globalMaxSequenceBreak: store.state.fixtureState.maxSequenceBreak,
      ),
    );

    if (result is Map<String, LocationModel>) {
      store.dispatch(
        SetLocations(
          Map<String, LocationModel>.from(store.state.fixtureState.locations)
            ..addAll(result),
        ),
      );
    }
  };
}

ThunkAction<AppState> updateLocationMultiPrefix(
  String locationId,
  String newValue,
) {
  return (Store<AppState> store) async {
    final existingLocation = store.state.fixtureState.locations[locationId];

    if (existingLocation == null) {
      return;
    }

    final updatedLocation = existingLocation.copyWith(multiPrefix: newValue);

    store.dispatch(
      SetLocations(
        store.state.fixtureState.locations.clone()
          ..update(locationId, (_) => updatedLocation),
      ),
    );
  };
}

ThunkAction<AppState> updateLocationMultiDelimiter(
  String locationId,
  String newValue,
) {
  return (Store<AppState> store) async {
    final existingLocation = store.state.fixtureState.locations[locationId];

    if (existingLocation == null) {
      return;
    }

    final updatedLocation = existingLocation.copyWith(delimiter: newValue);

    store.dispatch(
      SetLocations(
        store.state.fixtureState.locations.clone()
          ..update(locationId, (_) => updatedLocation),
      ),
    );
  };
}
