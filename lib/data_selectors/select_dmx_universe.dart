import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';

int selectDmxUniverse(FixtureState fixtureState, CableModel cable) {
  if (cable.type != CableType.dmx || cable.isSpare) {
    return 0;
  }

  final patchOutlet = fixtureState.dataPatches[cable.outletId];

  if (patchOutlet == null) {
    return 0;
  }

  return patchOutlet.universe;
}
