import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';

FixtureState fixtureStateReducer(FixtureState state, dynamic action) {
  return switch (action) {
    UpdateFixtureTypeName a => state.copyWith(
        fixtures: Map<String, FixtureModel>.from(state.fixtures)
          ..updateAll((uid, fixture) => fixture.type.uid == a.id
              ? fixture.copyWith(
                  type: fixture.type.copyWith(
                  name: a.newValue.trim(),
                  shortName:
                      fixture.type.shortName.isEmpty ? a.newValue.trim() : null,
                ))
              : fixture),
        outlets: state.outlets
            .map((outlet) => _updateOutletFixtureType(
                outlet: outlet,
                fixtureTypeUid: a.id,
                update: (existing) => existing.copyWith(name: a.newValue)))
            .toList()),
    UpdateFixtureTypeShortName a => state.copyWith(
        fixtures: Map<String, FixtureModel>.from(state.fixtures)
          ..updateAll((uid, fixture) => fixture.type.uid == a.id
              ? fixture.copyWith(
                  type: fixture.type.copyWith(shortName: a.newValue.trim()))
              : fixture),
        outlets: state.outlets
            .map((outlet) => _updateOutletFixtureType(
                outlet: outlet,
                fixtureTypeUid: a.id,
                update: (existing) => existing.copyWith(shortName: a.newValue)))
            .toList()),
    UpdateFixtureTypeMaxPiggybacks a => state.copyWith(
        fixtures: Map<String, FixtureModel>.from(state.fixtures)
          ..updateAll((uid, fixture) => fixture.type.uid == a.id
              ? fixture.copyWith(
                  type: fixture.type.copyWith(
                      maxPiggybacks: int.parse(a.newValue.trim()).abs()))
              : fixture)),
    UpdateLocationName a => state.copyWith(
        locations: Map<String, LocationModel>.from(state.locations)
          ..update(a.locationId,
              (existing) => existing.copyWith(name: a.newValue.trim())),
      ),
    UpdateLocationColor a => state.copyWith(
        locations: Map<String, LocationModel>.from(state.locations)
          ..update(
              a.locationId, (existing) => existing.copyWith(color: a.newValue)),
      ),
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
            a.locationId,
            (existing) => existing.copyWith(
              multiPrefix: a.newValue,
            ),
          ),
      ),
    // Default
    _ => state
  };
}

PowerOutletModel _updateOutletFixtureType(
    {required PowerOutletModel outlet,
    required String fixtureTypeUid,
    required FixtureTypeModel Function(FixtureTypeModel existing) update}) {
  return outlet.copyWith(
      child: outlet.child.copyWith(
    fixtures: outlet.child.fixtures.map((fixture) {
      if (fixture.type.uid == fixtureTypeUid) {
        return fixture.copyWith(
          type: update(fixture.type),
        );
      }
      return fixture;
    }).toList(),
  ));
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
