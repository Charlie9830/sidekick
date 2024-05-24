import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';

FixtureState fixtureStateReducer(FixtureState state, dynamic action) {
  return switch (action) {
    SetDataMultis a => state.copyWith(dataMultis: a.multis),
    SetDataPatches a => state.copyWith(dataPatches: a.patches),
    SetFixtures a => state.copyWith(
        fixtures: a.fixtures,
      ),
    SetLocations a => state.copyWith(
        locations: a.locations,
      ),
    SetPowerOutlets a => state.copyWith(
        outlets: a.outlets,
      ),
    SetPowerMultiOutlets a => state.copyWith(powerMultiOutlets: a.multiOutlets),
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
  return existingFixtures;
  // // Create reverse lookup map of Fixture uid to PowerOutlet Model. We will use this later to efficently
  // // map fixtures to their associated power Outlets.
  // final reverseLookup = Map<String, PowerOutletModel>.fromEntries(outlets
  //     .map((outlet) =>
  //         outlet.child.fixtures.map((fixture) => MapEntry(fixture.uid, outlet)))
  //     .expand((i) => i));

  // // Create an iterable of all Fixtures associated with this location.
  // final fixtureInLocation = outlets
  //     .map((outlet) => outlet.child.fixtures)
  //     .expand((i) => i)
  //     .where((fixture) => fixture.locationId == location.name);

  // // Find the first Multi Number that this location starts at. We will use that to offset the integer in the Mutli name to "localize"
  // // the integer to that Multi.. Otherwise the count keeps continuing up through multiple locations.
  // final firstLocationOutlet = outlets.firstWhereOrNull((outlet) =>
  //     outlet.child.isNotEmpty &&
  //     outlet.child.fixtures.first.locationId == location.name);

  // if (firstLocationOutlet == null) {
  //   throw "Couldn't find the first Outlet in this location. That indicates that something has gone wrong.";
  // }

  // final mutliNumberOffset = firstLocationOutlet.multiOutlet - 1;

  // return Map<String, FixtureModel>.from(existingFixtures)
  //   ..addAll(
  //       Map<String, FixtureModel>.fromEntries(fixtureInLocation.map((fixture) {
  //     // Use the reverse Lookup to find the data we are going to apply to the fixture.
  //     final multiOutlet = reverseLookup[fixture.uid]!.multiOutlet;
  //     final multiPatch = reverseLookup[fixture.uid]!.multiPatch;

  //     return MapEntry(
  //         fixture.uid,
  //         fixture.copyWith(
  //           powerMulti:
  //               location.getPrefixedPowerMulti(multiOutlet - mutliNumberOffset),
  //           powerPatch: multiPatch,
  //         ));
  //   })));
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
