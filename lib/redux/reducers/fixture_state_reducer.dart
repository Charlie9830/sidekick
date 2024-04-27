import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/fixture_state.dart';

FixtureState fixtureStateReducer(FixtureState state, dynamic action) {
  return switch (action) {
    SetFixtures a => state.copyWith(fixtures: a.fixtures),
    SetPowerPatches a => state.copyWith(patches: a.patches),
    SetPowerOutlets a => state.copyWith(
        outlets: a.outlets,
      ),

    // Default
    _ => state
  };
}
