import 'package:sidekick/perform_data_patch.dart';
import 'package:sidekick/perform_power_patch.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';

/// Handles file-related actions. Returns null when the action
/// is not handled here.
FixtureState? reduceFileActions(FixtureState state, dynamic a) {
  if (a is SetImportedFixtureData) {
    final powerPatch = performPowerPatch(
      fixtures: a.fixtures,
      fixtureTypes: a.fixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: a.locations,
      maxSequenceBreak: state.maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
      fixtureTypePools: state.fixtureTypePools,
      powerRacks: state.powerRacks,
    );
    return state.copyWith(
      fixtures: FixtureModel.sort(powerPatch.fixtures, a.locations),
      locations: a.locations,
      fixtureTypes: a.fixtureTypes,
      trusses: a.trusses,
      powerMultiOutlets: powerPatch.powerMultiOutlets,
      dataPatches: performDataPatch(
        fixtures: a.fixtures,
        dataPatches: state.dataPatches,
        locations: a.locations,
      ),
    );
  }

  if (a is NewProject) {
    return const FixtureState.initial();
  }

  if (a is OpenProject) {
    return a.project.toFixtureState();
  }

  if (a is ResetFixtureState) {
    return const FixtureState.initial();
  }

  return null;
}
