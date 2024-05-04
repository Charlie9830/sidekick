import 'package:collection/collection.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/utils/try_match_location_color.dart';

FixtureState fixtureStateReducer(FixtureState state, dynamic action) {
  return switch (action) {
    SetFixtures a => state.copyWith(
        fixtures: a.fixtures,
        locations: _getLocationsFromFixtures(a.fixtures),
      ),
    SetPowerPatches a => state.copyWith(patches: a.patches),
    SetPowerOutlets a => state.copyWith(
        outlets: a.outlets,
      ),
    SetBalanceTolerance a => state.copyWith(
        balanceTolerance:
            _convertBalanceTolerance(a.value, state.balanceTolerance)),
    SetMaxSequenceBreak a => state.copyWith(
        maxSequenceBreak:
            _convertMaxSequenceBreak(a.value, state.maxSequenceBreak)),
    UpdateLocationMultiPrefix a => state.copyWith(
        locations: Map<String, LocationModel>.from(state.locations)
          ..update(
            a.location,
            (existing) => existing.copyWith(
              multiPrefix: a.newValue.trim(),
            ),
          ),
      ),
    CommitLocationPowerPatch a => state.copyWith(
        fixtures: _mergePowerMultiDataIntoFixtures(
          location: a.location,
          existingFixtures: state.fixtures,
          outlets: state.outlets,
        ),
      ),
    // Default
    _ => state
  };
}

Map<String, FixtureModel> _mergePowerMultiDataIntoFixtures({
  required LocationModel location,
  required Map<String, FixtureModel> existingFixtures,
  required List<PowerOutletModel> outlets,
}) {
  // Create reverse lookup map of Fixture uid to PowerOutlet Model. We will use this later to efficently
  // map fixtures to their associated power Outlets.
  final reverseLookup = Map<String, PowerOutletModel>.fromEntries(outlets
      .map((outlet) =>
          outlet.child.fixtures.map((fixture) => MapEntry(fixture.uid, outlet)))
      .expand((i) => i));

  // Create an iterable of all Fixtures associated with this location.
  final fixtureInLocation = outlets
      .map((outlet) => outlet.child.fixtures)
      .expand((i) => i)
      .where((fixture) => fixture.location == location.name);

  // Find the first Multi Number that this location starts at. We will use that to offset the integer in the Mutli name to "localize"
  // the integer to that Multi.. Otherwise the count keeps continuing up through multiple locations.
  final firstLocationOutlet = outlets.firstWhereOrNull((outlet) =>
      outlet.child.isNotEmpty &&
      outlet.child.fixtures.first.location == location.name);

  if (firstLocationOutlet == null) {
    throw "Couldn't find the first Outlet in this location. That indicates that something has gone wrong.";
  }

  final mutliNumberOffset = firstLocationOutlet.multiOutlet - 1;

  return Map<String, FixtureModel>.from(existingFixtures)
    ..addAll(
        Map<String, FixtureModel>.fromEntries(fixtureInLocation.map((fixture) {
      // Use the reverse Lookup to find the data we are going to apply to the fixture.
      final multiOutlet = reverseLookup[fixture.uid]!.multiOutlet;
      final multiPatch = reverseLookup[fixture.uid]!.multiPatch;

      return MapEntry(
          fixture.uid,
          fixture.copyWith(
            powerMulti:
                location.getPrefixedPowerMulti(multiOutlet - mutliNumberOffset),
            powerPatch: multiPatch,
          ));
    })));
}

Map<String, LocationModel> _getLocationsFromFixtures(
    Map<String, FixtureModel> fixtures) {
  final locationsSet =
      fixtures.values.map((fixture) => fixture.location).toSet();

  return Map<String, LocationModel>.fromEntries(
      locationsSet.map((location) => MapEntry(
          location,
          LocationModel(
            name: location,
            color: tryMatchLocationColor(location),
          ))));
}

double _convertBalanceTolerance(String newValue, double existingValue) {
  final asInt = int.tryParse(newValue.trim());

  if (asInt == null) {
    return existingValue;
  }

  if (asInt == 0) {
    return 0;
  }

  return asInt / 100;
}

int _convertMaxSequenceBreak(String newValue, int existingValue) {
  final asInt = int.tryParse(newValue.trim());

  if (asInt == null) {
    return existingValue;
  }

  return asInt;
}
