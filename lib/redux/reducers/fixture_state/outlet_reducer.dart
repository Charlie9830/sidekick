import 'package:sidekick/multi_outlet_asserts.dart';
import 'package:sidekick/perform_power_patch.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/redux/reducers/fixture_state/assert_cable_state.dart';

/// Handles outlet-related actions. Returns null when the action
/// is not handled here.
FixtureState? reduceOutletActions(FixtureState state, dynamic a) {
  if (a is SetDataPatches) {
    final patches = assertDataPatchState(a.patches, state.locations);

    final cables = assertCableState(
      cables: state.cables,
      powerMultiOutlets: state.powerMultiOutlets,
      dataMultis: state.dataMultis,
      dataPatches: patches,
      hoistOutlets: state.hoists,
      hoistMultis: state.hoistMultis,
    );

    return state.copyWith(dataPatches: patches, cables: cables);
  }

  if (a is SetDataMultis) {
    return state.copyWith(
      dataMultis: assertMultiOutletState<DataMultiModel>(
        multiOutlets: a.multis,
        locations: state.locations,
        cables: state.cables,
      ),
    );
  }

  if (a is SetPowerMultiOutlets) {
    final outlets = performPowerPatch(
      fixtures: state.fixtures,
      fixtureTypes: state.fixtureTypes,
      powerMultiOutlets: a.multiOutlets,
      locations: state.locations,
      maxSequenceBreak: state.maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
      powerRacks: state.powerRacks,
      fixtureTypePools: state.fixtureTypePools,
    );

    return state.copyWith(
      powerMultiOutlets: outlets.powerMultiOutlets,
      fixtures: outlets.fixtures,
    );
  }

  if (a is SetBalanceTolerance) {
    final tolerance = _convertBalanceTolerance(a.value, state.balanceTolerance);

    final outlets = performPowerPatch(
      fixtures: state.fixtures,
      fixtureTypes: state.fixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: state.locations,
      maxSequenceBreak: state.maxSequenceBreak,
      balanceTolerance: tolerance,
      powerRacks: state.powerRacks,
      fixtureTypePools: state.fixtureTypePools,
    );

    return state.copyWith(
      balanceTolerance: tolerance,
      powerMultiOutlets: outlets.powerMultiOutlets,
      fixtures: outlets.fixtures,
    );
  }

  if (a is SetMaxSequenceBreak) {
    final maxSequenceBreak = _convertMaxSequenceBreak(
      a.value,
      state.maxSequenceBreak,
    );

    final outlets = performPowerPatch(
      fixtures: state.fixtures,
      fixtureTypes: state.fixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: state.locations,
      maxSequenceBreak: maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
      powerRacks: state.powerRacks,
      fixtureTypePools: state.fixtureTypePools,
    );

    return state.copyWith(
      maxSequenceBreak: maxSequenceBreak,
      powerMultiOutlets: outlets.powerMultiOutlets,
      fixtures: outlets.fixtures,
    );
  }

  return null;
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
