import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/perform_data_patch.dart';
import 'package:sidekick/perform_power_patch.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/fixture_type_pool_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';

/// Handles fixture-related actions. Returns null when the action
/// is not handled here.
FixtureState? reduceFixtureActions(FixtureState state, dynamic a) {
  if (a is ReorderFixtureTypePools) {
    int oldIndex = a.oldIndex;
    int newIndex = a.newIndex;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final items = state.fixtureTypePools.values.toList();

    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    return state.copyWith(fixtureTypePools: items.toModelMap());
  }

  if (a is DeleteFixtureTypePool) {
    final updatedPools = state.fixtureTypePools.clone()..remove(a.poolId);

    final powerPatch = performPowerPatch(
      fixtures: state.fixtures,
      fixtureTypes: state.fixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: state.locations,
      maxSequenceBreak: state.maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
      powerRacks: state.powerRacks,
      fixtureTypePools: updatedPools,
    );

    return state.copyWith(
      fixtureTypePools: updatedPools,
      powerMultiOutlets: powerPatch.powerMultiOutlets,
      fixtures: powerPatch.fixtures,
    );
  }

  if (a is RemoveFixtureTypePoolEntry) {
    final updatedPools = state.fixtureTypePools.clone()
      ..update(
        a.poolId,
        (existing) =>
            existing.copyWith(items: existing.items.clone()..remove(a.typeId)),
      );

    final powerPatch = performPowerPatch(
      fixtures: state.fixtures,
      fixtureTypes: state.fixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: state.locations,
      maxSequenceBreak: state.maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
      powerRacks: state.powerRacks,
      fixtureTypePools: updatedPools,
    );

    return state.copyWith(
      fixtureTypePools: updatedPools,
      powerMultiOutlets: powerPatch.powerMultiOutlets,
      fixtures: powerPatch.fixtures,
    );
  }

  if (a is UpdateFixtureTypePoolEntryQty) {
    final updatedPools = state.fixtureTypePools.clone()
      ..update(
        a.poolId,
        (existingPool) => existingPool.copyWith(
          items: existingPool.items.clone()
            ..update(
              a.typeId,
              (existingEntry) =>
                  existingEntry.copyWith(qty: int.tryParse(a.newValue.trim())),
            ),
        ),
      );

    final powerPatch = performPowerPatch(
      fixtures: state.fixtures,
      fixtureTypes: state.fixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: state.locations,
      maxSequenceBreak: state.maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
      powerRacks: state.powerRacks,
      fixtureTypePools: updatedPools,
    );

    return state.copyWith(
      fixtureTypePools: updatedPools,
      powerMultiOutlets: powerPatch.powerMultiOutlets,
      fixtures: powerPatch.fixtures,
    );
  }

  if (a is UpdateFixtureTypePoolName) {
    return state.copyWith(
      fixtureTypePools: state.fixtureTypePools.clone()
        ..update(
          a.poolId,
          (existing) => existing.copyWith(name: a.newValue.trim()),
        ),
    );
  }

  if (a is AddFixtureTypesToPool) {
    final updatedPools = state.fixtureTypePools.clone()
      ..update(
        a.poolId,
        (existing) => existing.copyWith(
          items: existing.items.clone()
            ..addEntries(
              a.typeIds.map(
                (id) =>
                    MapEntry(id, FixtureTypePoolEntryModel(typeId: id, qty: 1)),
              ),
            ),
        ),
      );

    final powerPatch = performPowerPatch(
      fixtures: state.fixtures,
      fixtureTypes: state.fixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: state.locations,
      maxSequenceBreak: state.maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
      powerRacks: state.powerRacks,
      fixtureTypePools: updatedPools,
    );

    return state.copyWith(
      fixtureTypePools: updatedPools,
      powerMultiOutlets: powerPatch.powerMultiOutlets,
      fixtures: powerPatch.fixtures,
    );
  }

  if (a is SetFixtureTypePools) {
    final powerPatch = performPowerPatch(
      fixtures: state.fixtures,
      fixtureTypes: state.fixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: state.locations,
      maxSequenceBreak: state.maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
      powerRacks: state.powerRacks,
      fixtureTypePools: a.value,
    );

    return state.copyWith(
      fixtureTypePools: a.value,
      powerMultiOutlets: powerPatch.powerMultiOutlets,
      fixtures: powerPatch.fixtures,
    );
  }

  if (a is UpdateFixtureTypeShortName) {
    return state.copyWith(
      fixtureTypes: state.fixtureTypes.clone()
        ..update(a.id, (type) => type.copyWith(shortName: a.newValue.trim())),
    );
  }

  if (a is UpdateFixtureTypeMaxPiggybacks) {
    final updatedFixtureTypes = state.fixtureTypes.clone()
      ..update(
        a.id,
        (type) => type.copyWith(maxPiggybacks: int.parse(a.newValue.trim())),
      );

    final outlets = performPowerPatch(
      fixtures: state.fixtures,
      fixtureTypes: updatedFixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: state.locations,
      maxSequenceBreak: state.maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
      powerRacks: state.powerRacks,
      fixtureTypePools: state.fixtureTypePools,
    );

    return state.copyWith(
      fixtureTypes: updatedFixtureTypes,
      powerMultiOutlets: outlets.powerMultiOutlets,
      fixtures: outlets.fixtures,
    );
  }

  if (a is SetFixtures) {
    final outlets = performPowerPatch(
      fixtures: a.fixtures,
      fixtureTypes: state.fixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: state.locations,
      maxSequenceBreak: state.maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
      powerRacks: state.powerRacks,
      fixtureTypePools: state.fixtureTypePools,
    );

    return state.copyWith(
      fixtures: outlets.fixtures,
      powerMultiOutlets: outlets.powerMultiOutlets,
      dataPatches: performDataPatch(
        fixtures: a.fixtures,
        dataPatches: state.dataPatches,
        locations: state.locations,
      ),
    );
  }

  return null;
}
