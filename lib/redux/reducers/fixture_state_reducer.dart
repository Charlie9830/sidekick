import 'package:collection/collection.dart';
import 'package:sidekick/assert_data_multi_and_patch_state.dart';
import 'package:sidekick/assert_outlet_name_and_number.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/perform_data_patch.dart';
import 'package:sidekick/perform_power_patch.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';

FixtureState fixtureStateReducer(FixtureState state, dynamic a) {
  if (a is SetImportedFixtureData) {
    final powerPatch = performPowerPatch(
      fixtures: a.fixtures,
      fixtureTypes: a.fixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: a.locations,
      maxSequenceBreak: state.maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
    );

    return state.copyWith(
        fixtures: FixtureModel.sort(powerPatch.fixtures, a.locations),
        locations: a.locations,
        fixtureTypes: a.fixtureTypes,
        powerMultiOutlets: powerPatch.powerMultiOutlets,
        dataPatches: performDataPatch(
          fixtures: a.fixtures,
          dataPatches: state.dataPatches,
          locations: a.locations,
        ));
  }

  if (a is UpdateCableNote) {
    return state.copyWith(
        cables: state.cables.clone()
          ..update(
              a.id,
              (existing) => existing.copyWith(
                    notes: a.value.trim(),
                  )));
  }

  if (a is UpdateLoomName) {
    return state.copyWith(
        looms: state.looms.clone()
          ..update(
              a.uid,
              (existing) => existing.copyWith(
                    name: a.value.trim(),
                  )));
  }

  if (a is SetDefaultPowerMulti) {
    return state.copyWith(
      defaultPowerMulti: a.value,
    );
  }

  if (a is UpdateCableLength) {
    final updatedCables = state.cables.clone()
      ..update(
          a.uid,
          (existing) => existing.copyWith(
              length: double.tryParse(a.newLength.trim()) ?? existing.length));

    return state.copyWith(
      cables: _assertCableOrderings(
          cables: updatedCables,
          powerMultiOutlets: state.powerMultiOutlets,
          dataMultis: state.dataMultis,
          dataPatches: state.dataPatches),
    );
  }

  if (a is ToggleCableDropperStateByLoom) {
    return state.copyWith(
        cables: _assertCableOrderings(
            cables: _toggleCableDropperState(a.loomId, state.cables),
            powerMultiOutlets: state.powerMultiOutlets,
            dataMultis: state.dataMultis,
            dataPatches: state.dataPatches));
  }

  if (a is SetCables) {
    return state.copyWith(
      cables: _assertCableOrderings(
          cables: a.cables,
          powerMultiOutlets: state.powerMultiOutlets,
          dataMultis: state.dataMultis,
          dataPatches: state.dataPatches),
    );
  }

  if (a is UpdateLoomLength) {
    return _updateLoomLength(state, a);
  }

  if (a is SetCablesAndLooms) {
    return state.copyWith(
      cables: _assertCableOrderings(
        cables: a.cables,
        powerMultiOutlets: state.powerMultiOutlets,
        dataMultis: state.dataMultis,
        dataPatches: state.dataPatches,
      ),
      looms: a.looms,
    );
  }

  if (a is SetLoomStock) {
    return state.copyWith(loomStock: a.value);
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

  if (a is UpdateFixtureTypeShortName) {
    return state.copyWith(
      fixtureTypes: state.fixtureTypes.clone()
        ..update(
          a.id,
          (type) => type.copyWith(
            shortName: a.newValue.trim(),
          ),
        ),
    );
  }

  if (a is UpdateFixtureTypeMaxPiggybacks) {
    final updatedFixtureTypes = state.fixtureTypes.clone()
      ..update(
          a.id,
          (type) => type.copyWith(
                maxPiggybacks: int.parse(a.newValue.trim()),
              ));

    final outlets = performPowerPatch(
      fixtures: state.fixtures,
      fixtureTypes: updatedFixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: state.locations,
      maxSequenceBreak: state.maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
    );

    return state.copyWith(
      fixtureTypes: updatedFixtureTypes,
      powerMultiOutlets: outlets.powerMultiOutlets,
      fixtures: outlets.fixtures,
    );
  }

  if (a is UpdateLocationDelimiter) {
    return state.copyWith(
      locations: state.locations.clone()
        ..update(a.locationId,
            (existing) => existing.copyWith(delimiter: a.newValue)),
    );
  }

  if (a is UpdateLocationColor) {
    return state.copyWith(
      locations: state.locations.clone()
        ..update(
            a.locationId, (existing) => existing.copyWith(color: a.newValue)),
    );
  }

  if (a is SetDataMultis) {
    return state.copyWith(
      dataMultis: assertDataMultiState(a.multis, state.locations),
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
    );

    return state.copyWith(
        fixtures: outlets.fixtures,
        powerMultiOutlets: outlets.powerMultiOutlets,
        dataPatches: performDataPatch(
            fixtures: a.fixtures,
            dataPatches: state.dataPatches,
            locations: state.locations));
  }

  if (a is SetLocations) {
    return state.copyWith(
      locations: a.locations,
      dataMultis: assertOutletNameAndNumbers<DataMultiModel>(
              state.dataMultis.values, a.locations)
          .toModelMap(),
      powerMultiOutlets: assertOutletNameAndNumbers<PowerMultiOutletModel>(
              state.powerMultiOutlets.values, a.locations)
          .toModelMap(),
      dataPatches: assertOutletNameAndNumbers<DataPatchModel>(
              state.dataPatches.values, a.locations)
          .toModelMap(),
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
    );

    return state.copyWith(
      balanceTolerance: tolerance,
      powerMultiOutlets: outlets.powerMultiOutlets,
      fixtures: outlets.fixtures,
    );
  }

  if (a is SetMaxSequenceBreak) {
    final maxSequenceBreak =
        _convertMaxSequenceBreak(a.value, state.maxSequenceBreak);

    final outlets = performPowerPatch(
      fixtures: state.fixtures,
      fixtureTypes: state.fixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: state.locations,
      maxSequenceBreak: maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
    );

    return state.copyWith(
      maxSequenceBreak: maxSequenceBreak,
      powerMultiOutlets: outlets.powerMultiOutlets,
      fixtures: outlets.fixtures,
    );
  }

  if (a is SetLooms) {
    return state.copyWith(
      looms: a.looms,
    );
  }

  return state;
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

FixtureState _updateLoomLength(FixtureState state, UpdateLoomLength a) {
  final newLength = double.tryParse(a.newValue.trim()) ?? 0;
  final existingLoom = state.looms[a.id]!;

  final targetCables =
      state.cables.values.where((cable) => cable.loomId == existingLoom.uid);

  final updatedCables = state.cables.clone()
    ..addAll(targetCables
        .map(
          (cable) => cable.copyWith(length: newLength),
        )
        .toModelMap());

  return state.copyWith(
    looms: state.looms.clone()
      ..update(
        a.id,
        (existing) =>
            existing.copyWith(type: existing.type.copyWith(length: newLength)),
      ),
    cables: _assertCableOrderings(
        cables: updatedCables,
        powerMultiOutlets: state.powerMultiOutlets,
        dataMultis: state.dataMultis,
        dataPatches: state.dataPatches),
  );
}

Map<String, CableModel> _assertCableOrderings({
  required Map<String, CableModel> cables,
  required Map<String, PowerMultiOutletModel> powerMultiOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, DataPatchModel> dataPatches,
}) {
  final cablesByOutletId = cables.values.groupListsBy((item) => item.outletId);
  final orderedOutletIds = [
    ...powerMultiOutlets.keys,
    ...dataMultis.keys,
    ...dataPatches.keys,
    '', // Spare cables will have an empty outletId field. Therefore we need to include an empty string here, otherwise
    // the spares will get inadvertantly filltered out.
  ];

  final orderedCables = orderedOutletIds
      .map((outletId) => cablesByOutletId[outletId] ?? [])
      .flattened;

  return orderedCables.toModelMap();
}

Map<String, CableModel> _toggleCableDropperState(
    String loomId, Map<String, CableModel> existingCables) {
  final cables = existingCables.values.where((cable) => cable.loomId == loomId);

  if (cables.isEmpty) {
    return existingCables;
  }

  final valueSet = cables.map((cable) => cable.isDropper).toSet();
  final derivedCurrentState = valueSet.length == 1 ? valueSet.first : false;

  return existingCables.clone()
    ..addAll(
      cables
          .map((cable) => cable.copyWith(isDropper: !derivedCurrentState))
          .toModelMap(),
    );
}
