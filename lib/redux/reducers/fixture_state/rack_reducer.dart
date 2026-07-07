import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/perform_power_patch.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/fixture_state.dart';

/// Handles rack-related actions. Returns null when the action
/// is not handled here.
FixtureState? reduceRackActions(FixtureState state, dynamic a) {
  if (a is SetDataRacks) {
    return state.copyWith(dataRacks: a.racks);
  }

  if (a is SetPowerFeeds) {
    return state.copyWith(powerFeeds: a.powerFeeds);
  }

  if (a is SetPowerRacks) {
    final powerPatch = performPowerPatch(
      fixtures: state.fixtures,
      fixtureTypes: state.fixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: state.locations,
      maxSequenceBreak: state.maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
      powerRacks: a.racks,
      fixtureTypePools: state.fixtureTypePools,
    );

    return state.copyWith(
      powerRacks: a.racks,
      powerMultiOutlets: powerPatch.powerMultiOutlets,
      fixtures: powerPatch.fixtures,
    );
  }

  if (a is SetPowerFeedsAndPowerRacks) {
    final powerPatch = performPowerPatch(
      fixtures: state.fixtures,
      fixtureTypes: state.fixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: state.locations,
      maxSequenceBreak: state.maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
      powerRacks: a.racks,
      fixtureTypePools: state.fixtureTypePools,
    );

    return state.copyWith(
      powerFeeds: a.powerFeeds,
      powerRacks: a.racks,
      powerMultiOutlets: powerPatch.powerMultiOutlets,
      fixtures: powerPatch.fixtures,
    );
  }

  if (a is UpdatePowerRackName) {
    return state.copyWith(
      powerRacks: state.powerRacks.clone()
        ..update(
          a.rackId,
          (existing) => existing.copyWith(name: a.newValue.trim()),
        ),
    );
  }

  if (a is UpdatePowerRackNote) {
    return state.copyWith(
      powerRacks: state.powerRacks.clone()
        ..update(
          a.rackId,
          (existing) => existing.copyWith(note: a.newValue.trim()),
        ),
    );
  }

  if (a is UpdateDataRackName) {
    return state.copyWith(
      dataRacks: state.dataRacks.clone()
        ..update(
          a.rackId,
          (existing) => existing.copyWith(name: a.newValue.trim()),
        ),
    );
  }

  if (a is UpdateDataRackNote) {
    return state.copyWith(
      dataRacks: state.dataRacks.clone()
        ..update(
          a.rackId,
          (existing) => existing.copyWith(notes: a.newValue.trim()),
        ),
    );
  }

  return null;
}
