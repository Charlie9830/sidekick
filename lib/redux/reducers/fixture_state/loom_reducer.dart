import 'package:sidekick/multi_outlet_asserts.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/redux/reducers/fixture_state/assert_cable_state.dart';

/// Handles loom-related actions. Returns null when the action
/// is not handled here.
FixtureState? reduceLoomActions(FixtureState state, dynamic a) {
  if (a is UpdateCableNote) {
    return state.copyWith(
      cables: state.cables.clone()
        ..update(a.id, (existing) => existing.copyWith(notes: a.value.trim())),
    );
  }

  if (a is UpdateLoomName) {
    return state.copyWith(
      looms: state.looms.clone()
        ..update(a.uid, (existing) => existing.copyWith(name: a.value.trim())),
    );
  }

  if (a is SetDefaultPowerMulti) {
    return state.copyWith(defaultPowerMulti: a.value);
  }

  if (a is UpdateCableLength) {
    final updatedCables = state.cables.clone()
      ..update(
        a.uid,
        (existing) => existing.copyWith(
          length: double.tryParse(a.newLength.trim()) ?? existing.length,
        ),
      );

    return state.copyWith(
      cables: assertCableState(
        cables: updatedCables,
        powerMultiOutlets: state.powerMultiOutlets,
        dataMultis: state.dataMultis,
        dataPatches: state.dataPatches,
        hoistMultis: state.hoistMultis,
        hoistOutlets: state.hoists,
      ),
    );
  }

  if (a is ToggleCableDropperStateByLoom) {
    return state.copyWith(
      cables: assertCableState(
        cables: _toggleCableDropperState(a.loomId, state.cables),
        powerMultiOutlets: state.powerMultiOutlets,
        dataMultis: state.dataMultis,
        dataPatches: state.dataPatches,
        hoistMultis: state.hoistMultis,
        hoistOutlets: state.hoists,
      ),
    );
  }

  if (a is SetCables) {
    final cables = assertCableState(
      cables: a.cables,
      powerMultiOutlets: state.powerMultiOutlets,
      dataMultis: state.dataMultis,
      dataPatches: state.dataPatches,
      hoistMultis: state.hoistMultis,
      hoistOutlets: state.hoists,
    );

    return state.copyWith(
      cables: cables,
      dataMultis: assertMultiOutletState<DataMultiModel>(
        multiOutlets: state.dataMultis,
        locations: state.locations,
        cables: cables,
      ),
      hoistMultis: assertMultiOutletState<HoistMultiModel>(
        multiOutlets: state.hoistMultis,
        locations: state.locations,
        cables: cables,
      ),
    );
  }

  if (a is UpdateLoomLength) {
    return _updateLoomLength(state, a);
  }

  if (a is SetCablesAndLooms) {
    final cables = assertCableState(
      cables: a.cables,
      powerMultiOutlets: state.powerMultiOutlets,
      dataMultis: state.dataMultis,
      dataPatches: state.dataPatches,
      hoistMultis: state.hoistMultis,
      hoistOutlets: state.hoists,
    );

    return state.copyWith(
      cables: cables,
      looms: a.looms,
      dataMultis: assertMultiOutletState<DataMultiModel>(
        multiOutlets: state.dataMultis,
        locations: state.locations,
        cables: cables,
      ),
      hoistMultis: assertMultiOutletState<HoistMultiModel>(
        multiOutlets: state.hoistMultis,
        locations: state.locations,
        cables: cables,
      ),
    );
  }

  if (a is SetLoomStock) {
    return state.copyWith(loomStock: a.value);
  }

  if (a is SetLooms) {
    return state.copyWith(looms: a.looms);
  }

  return null;
}

FixtureState _updateLoomLength(FixtureState state, UpdateLoomLength a) {
  final newLength = double.tryParse(a.newValue.trim()) ?? 0;
  final existingLoom = state.looms[a.id]!;

  final targetCables = state.cables.values.where(
    (cable) => cable.loomId == existingLoom.uid,
  );

  final updatedCables = state.cables.clone()
    ..addAll(
      targetCables
          .map((cable) => cable.copyWith(length: newLength))
          .toModelMap(),
    );

  return state.copyWith(
    looms: state.looms.clone()
      ..update(
        a.id,
        (existing) =>
            existing.copyWith(type: existing.type.copyWith(length: newLength)),
      ),
    cables: assertCableState(
      cables: updatedCables,
      powerMultiOutlets: state.powerMultiOutlets,
      dataMultis: state.dataMultis,
      dataPatches: state.dataPatches,
      hoistMultis: state.hoistMultis,
      hoistOutlets: state.hoists,
    ),
  );
}

Map<String, CableModel> _toggleCableDropperState(
  String loomId,
  Map<String, CableModel> existingCables,
) {
  final cables = existingCables.values.where((cable) => cable.loomId == loomId);

  if (cables.isEmpty) {
    return existingCables;
  }

  final valueSet = cables.map((cable) => cable.isDropper).toSet();
  final derivedCurrentState = valueSet.length == 1 ? valueSet.first : false;

  return existingCables.clone()..addAll(
    cables
        .map((cable) => cable.copyWith(isDropper: !derivedCurrentState))
        .toModelMap(),
  );
}
