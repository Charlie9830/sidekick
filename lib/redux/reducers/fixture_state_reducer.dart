import 'package:flutter/foundation.dart';
import 'package:sidekick/loom_and_cable_cleanup/cable_cleanup.dart';
import 'package:sidekick/loom_and_cable_cleanup/cleanup_cables_and_looms.dart';
import 'package:sidekick/model_collection/convert_to_model_map.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/utils/get_uid.dart';

FixtureState fixtureStateReducer(FixtureState state, dynamic a) {
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
    final cleanCables = performCableCleanup(
        cables: a.cables,
        powerMultis: state.powerMultiOutlets,
        dataMultis: a.dataMultis,
        dataPatches: state.dataPatches,
        defaultPowerMultiType: state.defaultPowerMulti);

    return state.copyWith(
      cables: cleanCables,
      dataMultis: a.dataMultis,
    );
  }

  if (a is UpdateLoomLength) {
    return _updateLoomLength(state, a);
  }

  if (a is SetCablesAndLooms) {
    final cleanCables = performCableCleanup(
        cables: a.cables,
        powerMultis: state.powerMultiOutlets,
        dataMultis: state.dataMultis,
        dataPatches: state.dataPatches,
        defaultPowerMultiType: state.defaultPowerMulti);

    return state.copyWith(
      cables: cleanCables,
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
            (existing) => existing.copyWith(delimiter: a.newValue.trim())),
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
    final (updatedCables, updatedLooms) = assertCableAndLoomsExistence(
      powerMultiOutlets: state.powerMultiOutlets,
      dataMultis: a.multis,
      dataPatches: state.dataPatches,
      existingCables: state.cables,
      existingLooms: state.looms,
      defaultPowerMultiType: state.defaultPowerMulti,
    );

    return state.copyWith(
      dataMultis: a.multis,
      cables: updatedCables,
      looms: updatedLooms,
    );
  }

  if (a is SetDataPatches) {
    final (updatedCables, updatedLooms) = assertCableAndLoomsExistence(
      powerMultiOutlets: state.powerMultiOutlets,
      dataMultis: state.dataMultis,
      dataPatches: a.patches,
      existingCables: state.cables,
      existingLooms: state.looms,
      defaultPowerMultiType: state.defaultPowerMulti,
    );

    return state.copyWith(
      dataPatches: a.patches,
      cables: updatedCables,
      looms: updatedLooms,
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
    final (updatedCables, updatedLooms) = assertCableAndLoomsExistence(
      powerMultiOutlets: a.multiOutlets,
      dataMultis: state.dataMultis,
      dataPatches: state.dataPatches,
      existingCables: state.cables,
      existingLooms: state.looms,
      defaultPowerMultiType: state.defaultPowerMulti,
    );

    return state.copyWith(
      powerMultiOutlets: a.multiOutlets,
      cables: updatedCables,
      looms: updatedLooms,
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

(Map<String, CableModel> cables, Map<String, LoomModel> looms)
    assertCableAndLoomsExistence({
  required Map<String, PowerMultiOutletModel> powerMultiOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, DataPatchModel> dataPatches,
  required Map<String, CableModel> existingCables,
  required Map<String, LoomModel> existingLooms,
  required CableType defaultPowerMultiType,
}) {
  final headCablesByOutletId = Map<String, CableModel>.fromEntries(
      existingCables.values
          .where((cable) => cable.upstreamId.isEmpty)
          .map((cable) => MapEntry(cable.outletId, cable)));

  final updatedPowerCables = powerMultiOutlets.values
      .map((outlet) => headCablesByOutletId.containsKey(outlet.uid)
          ? headCablesByOutletId[outlet.uid]!
          : CableModel(
              uid: getUid(),
              type: defaultPowerMultiType,
              outletId: outlet.uid,
              locationId: outlet.locationId,
            ));

  final updatedDataMultis = dataMultis.values
      .map((outlet) => headCablesByOutletId.containsKey(outlet.uid)
          ? headCablesByOutletId[outlet.uid]!
          : CableModel(
              uid: getUid(),
              type: CableType.sneak,
              outletId: outlet.uid,
              locationId: outlet.locationId,
            ));

  final updatedDataPatches = dataPatches.values
      .map((outlet) => headCablesByOutletId.containsKey(outlet.uid)
          ? headCablesByOutletId[outlet.uid]!
          : CableModel(
              uid: getUid(),
              type: CableType.dmx,
              outletId: outlet.uid,
              locationId: outlet.locationId,
            ));

  final dirtyCables = convertToModelMap([
    ...existingCables.values,
    ...updatedPowerCables,
    ...updatedDataMultis,
    ...updatedDataPatches,
  ]);
  final dirtyLooms = existingLooms;

  return cleanupCablesAndLooms(
      dirtyCables: performCableCleanup(
          cables: dirtyCables,
          powerMultis: powerMultiOutlets,
          dataMultis: dataMultis,
          dataPatches: dataPatches,
          defaultPowerMultiType: defaultPowerMultiType),
      dirtyLooms: dirtyLooms);
}
