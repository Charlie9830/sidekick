import 'package:sidekick/model_collection/convert_to_model_map.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';

FixtureState fixtureStateReducer(FixtureState state, dynamic a) {
  if (a is UpdateLoomName) {
    return state.copyWith(
      looms: Map<String, LoomModel>.from(state.looms)..update(a.uid, (existing) => existing.copyWith(
        name: a.value.trim(),
      ))
    );
  }

  if (a is SetDefaultPowerMulti) {
    return state.copyWith(
      defaultPowerMulti: a.value,
    );
  }

  if (a is UpdateCableLength) {
    return state.copyWith(
        cables: Map<String, CableModel>.from(state.cables)
          ..update(
              a.uid,
              (existing) => existing.copyWith(
                  length:
                      double.tryParse(a.newLength.trim()) ?? existing.length)));
  }

  if (a is ToggleLoomDropperState) {
    return state.copyWith(
        looms: Map<String, LoomModel>.from(state.looms)
          ..update(
              a.loomId, (existing) => existing.copyWith(isDrop: a.isDropper)));
  }

  if (a is SetCables) {
    return state.copyWith(cables: a.cables);
  }

  if (a is UpdateCablesAndDataMultis) {
    return state.copyWith(
      cables: a.cables,
      dataMultis: a.dataMultis,
    );
  }

  if (a is UpdateLoomLength) {
    return _updateLoomLength(state, a);
  }

  if (a is SetCablesAndLooms) {
    return state.copyWith(
      cables: a.cables,
      looms: a.looms,
    );
  }

  if (a is SetLocationPowerLock) {
    return state.copyWith(
        locations: Map<String, LocationModel>.from(state.locations)
          ..update(a.locationId,
              (existing) => existing.copyWith(isPowerPatchLocked: a.value)));
  }

  if (a is SetLocationDataLock) {
    return state.copyWith(
        locations: Map<String, LocationModel>.from(state.locations)
          ..update(a.locationId,
              (existing) => existing.copyWith(isDataPatchLocked: a.value)));
  }

  if (a is SetHonorDataSpans) {
    return state.copyWith(honorDataSpans: a.value);
  }

  if (a is SetFixtureTypes) {
    return state.copyWith(fixtureTypes: a.types);
  }

  if (a is NewProject) {
    return FixtureState.initial();
  }

  if (a is OpenProject) {
    return a.project.toFixtureState(
      fixtureTypes: state.fixtureTypes,
      honorDataSpans: state.honorDataSpans,
    );
  }

  if (a is ResetFixtureState) {
    return state.copyWith(
      fixtures: FixtureState.initial().fixtures,
      balanceTolerance: FixtureState.initial().balanceTolerance,
      dataMultis: FixtureState.initial().dataMultis,
      dataPatches: FixtureState.initial().dataPatches,
      locations: FixtureState.initial().locations,
      looms: FixtureState.initial().looms,
      maxSequenceBreak: FixtureState.initial().maxSequenceBreak,
      outlets: FixtureState.initial().outlets,
      powerMultiOutlets: FixtureState.initial().powerMultiOutlets,
      cables: FixtureState.initial().cables,
      defaultPowerMulti: FixtureState.initial().defaultPowerMulti,
      honorDataSpans: FixtureState.initial().honorDataSpans,
    );
  }

  if (a is UpdateFixtureTypeShortName) {
    return state.copyWith(
      fixtureTypes: Map<String, FixtureTypeModel>.from(state.fixtureTypes)
        ..update(
          a.id,
          (type) => type.copyWith(
            shortName: a.newValue.trim(),
          ),
        ),
    );
  }

  if (a is UpdateFixtureTypeMaxPiggybacks) {
    return state.copyWith(
      fixtureTypes: Map<String, FixtureTypeModel>.from(state.fixtureTypes)
        ..update(
          a.id,
          (type) => type.copyWith(
            maxPiggybacks: int.parse(a.newValue.trim()),
          ),
        ),
    );
  }

  if (a is UpdateLocationDelimiter) {
    return state.copyWith(
      locations: Map<String, LocationModel>.from(state.locations)
        ..update(a.locationId,
            (existing) => existing.copyWith(delimiter: a.newValue)),
    );
  }

  if (a is UpdateLocationColor) {
    return state.copyWith(
      locations: Map<String, LocationModel>.from(state.locations)
        ..update(
            a.locationId, (existing) => existing.copyWith(color: a.newValue)),
    );
  }

  if (a is SetDataMultis) {
    return state.copyWith(
      dataMultis: a.multis,
    );
  }

  if (a is SetDataPatches) {
    return state.copyWith(
      dataPatches: a.patches,
    );
  }

  if (a is SetFixtures) {
    return state.copyWith(
      fixtures: a.fixtures,
    );
  }

  if (a is SetLocations) {
    return state.copyWith(
      locations: a.locations,
    );
  }

  if (a is SetPowerOutlets) {
    return state.copyWith(
      outlets: a.outlets,
    );
  }

  if (a is SetPowerMultiOutlets) {
    return state.copyWith(
      powerMultiOutlets: a.multiOutlets,
    );
  }

  if (a is SetBalanceTolerance) {
    return state.copyWith(
        balanceTolerance:
            _convertBalanceTolerance(a.value, state.balanceTolerance));
  }

  if (a is SetMaxSequenceBreak) {
    return state.copyWith(
        maxSequenceBreak:
            _convertMaxSequenceBreak(a.value, state.maxSequenceBreak));
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

  final updatedCables = Map<String, CableModel>.from(state.cables)
    ..addAll(convertToModelMap(
        targetCables.map((cable) => cable.copyWith(length: newLength))));

  return state.copyWith(
    looms: Map<String, LoomModel>.from(state.looms)
      ..update(
        a.id,
        (existing) =>
            existing.copyWith(type: existing.type.copyWith(length: newLength)),
      ),
    cables: updatedCables,
  );
}
