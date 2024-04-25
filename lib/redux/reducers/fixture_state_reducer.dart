import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/utils/get_phase_from_index.dart';
import 'package:sidekick/utils/get_uid.dart';

FixtureState fixtureStateReducer(FixtureState state, dynamic action) {
  return switch (action) {
    SetFixtures a => state.copyWith(fixtures: a.fixtures),
    SetPowerPatches a => state.copyWith(patches: a.patches),
    AddSpareOutlet a => state.copyWith(
        outlets: state.outlets.toList()
          ..insert(
            a.index,
            PowerOutletModel.spare(
                uid: getUid(), phase: getPhaseFromIndex(a.index)),
          )),
    SetPowerOutlets a => state.copyWith(
        outlets: a.outlets,
      ),

    // Default
    _ => state
  };
}
