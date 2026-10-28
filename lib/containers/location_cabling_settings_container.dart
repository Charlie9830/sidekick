import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/breakout_cabling/location_cabling_settings.dart';

/// Opens a location's cabling settings in a popover anchored to [context].
void showLocationCablingSettingsPopover(
  BuildContext context,
  String locationId,
) {
  showOverlay<void>(
    context,
    const PopoverConfiguration(
      alignment: Alignment.topRight,
      anchorAlignment: Alignment.bottomRight,
      offset: Offset(0, 8),
    ),
    adaptive: false,
    builder: (context) =>
        LocationCablingSettingsContainer(locationId: locationId),
  );
}

/// Connects [LocationCablingSettings] to the store for a single location.
///
/// The settings are shown in a popover, which is built once when it opens,
/// so they read the store directly to reflect each edit as it is made.
class LocationCablingSettingsContainer extends StatelessWidget {
  final String locationId;

  const LocationCablingSettingsContainer({super.key, required this.locationId});

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, LocationCablingSettingsViewModel?>(
      converter: (store) => _selectViewModel(store, locationId),
      builder: (context, vm) => vm == null
          ? const SizedBox.shrink()
          : LocationCablingSettings(vm: vm),
    );
  }
}

LocationCablingSettingsViewModel? _selectViewModel(
  Store<AppState> store,
  String locationId,
) {
  final location = store.state.fixtureState.locations[locationId];

  if (location == null) {
    return null;
  }

  return LocationCablingSettingsViewModel(
    location: location,
    fixtureTypes: _selectFixtureTypesInLocation(store, locationId),
    onSetBreakAtTrussJoins: (value) =>
        store.dispatch(UpdateLocationBreakAtTrussJoins(locationId, value)),
    onCablingChanged: (typeId, override) => store.dispatch(
      UpdateLocationCablingOverride(locationId, typeId, override),
    ),
  );
}

/// The distinct fixture types patched into a location, in fixture order.
List<FixtureTypeModel> _selectFixtureTypesInLocation(
  Store<AppState> store,
  String locationId,
) {
  final fixtureTypes = store.state.fixtureState.fixtureTypes;

  return store.state.fixtureState.fixtures.values
      .where((fixture) => fixture.locationId == locationId)
      .map((fixture) => fixture.typeId)
      .toSet()
      .map((typeId) => fixtureTypes[typeId])
      .nonNulls
      .toList();
}
