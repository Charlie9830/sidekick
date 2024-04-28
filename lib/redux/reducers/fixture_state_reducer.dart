import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/fixture_state.dart';

FixtureState fixtureStateReducer(FixtureState state, dynamic action) {
  return switch (action) {
    SetFixtures a => state.copyWith(fixtures: a.fixtures),
    SetPowerPatches a => state.copyWith(patches: a.patches),
    SetPowerOutlets a => state.copyWith(
        outlets: a.outlets,
      ),
    SetBalanceTolerance a => state.copyWith(
        balanceTolerance:
            _convertBalanceTolerance(a.value, state.balanceTolerance)),

    // Default
    _ => state
  };
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
