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
import 'package:sidekick/view_models/loom_screen_item_view_model.dart';

FixtureState fixtureStateReducer(FixtureState state, dynamic a) {
  if (a is ToggleLoomDropperState) {
    return _updateLoomDropperState(state, a.loomId, a.dropState, a.childCables);
  }

  if (a is SetCables) {
    return state.copyWith(cables: a.cables);
  }

  if (a is UpdateCablesAndDataMultis) {
    final (cleanCables, cleanLooms) =
        cleanupCablesAndLooms(a.cables, state.looms);
        
    return state.copyWith(
      cables: cleanCables,
      looms: cleanLooms,
      dataMultis: a.dataMultis,
    );
  }

  if (a is UpdateLoomName) {
    return state.copyWith(
        looms: Map<String, LoomModel>.from(state.looms)
          ..update(
              a.id, (existing) => existing.copyWith(name: a.newValue.trim())));
  }

  if (a is UpdateLoomLength) {
    return _updateLoomLength(state, a);
  }

  if (a is SetCablesAndLooms) {
    final (cleanCables, cleanLooms) = cleanupCablesAndLooms(a.cables, a.looms);

    return state.copyWith(
      cables: cleanCables,
      looms: cleanLooms,
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
    return state.copyWith(
      balanceTolerance: a.project.balanceTolerance,
      dataMultis: convertToModelMap(a.project.dataMultis),
      dataPatches: convertToModelMap(a.project.dataPatches),
      fixtures: convertToModelMap(a.project.fixtures),
      locations: convertToModelMap(a.project.locations),
      looms: convertToModelMap(a.project.looms),
      outlets: a.project.outlets,
      powerMultiOutlets: convertToModelMap(a.project.powerMultiOutlets),
      maxSequenceBreak: a.project.maxSequenceBreak,
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
    );
  }

  if (a is UpdateFixtureTypeName) {
    return state.copyWith(
      fixtureTypes: Map<String, FixtureTypeModel>.from(state.fixtureTypes)
        ..update(
          a.id,
          (type) => type.copyWith(
            name: a.newValue.trim(),
          ),
        ),
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

  if (a is UpdateLocationName) {
    return state.copyWith(
      locations: Map<String, LocationModel>.from(state.locations)
        ..update(a.locationId,
            (existing) => existing.copyWith(name: a.newValue.trim())),
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
        existingLooms: state.looms);

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
        existingLooms: state.looms);

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
        existingLooms: state.looms);

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

FixtureState _updateLoomDropperState(FixtureState state, String loomId,
    LoomDropState dropState, List<CableModel> children) {
  if (children.isEmpty) {
    return state;
  }

  bool targetState = switch (dropState) {
    LoomDropState.isDropdown || LoomDropState.various => false,
    LoomDropState.isNotDropdown => true
  };

  final updatedChildren =
      convertToModelMap(children.map((child) => child.copyWith(
            isDropper: targetState,
          )));

  return state.copyWith(
    cables: Map<String, CableModel>.from(state.cables)..addAll(updatedChildren),
  );
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

  final targetCables = existingLoom.childrenIds.toSet();
  final updatedCables = Map<String, CableModel>.from(state.cables)
    ..updateAll((key, value) =>
        targetCables.contains(key) ? value.copyWith(length: newLength) : value);

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
}) {
  final cablesByOutletId = Map<String, CableModel>.from(
      existingCables.map((key, value) => MapEntry(value.outletId, value)));

  final updatedPowerCables = powerMultiOutlets.values
      .map((outlet) => cablesByOutletId.containsKey(outlet.uid)
          ? cablesByOutletId[outlet.uid]!
          : CableModel(
              uid: getUid(),
              type: CableType.socapex,
              outletId: outlet.uid,
              locationId: outlet.locationId,
            ));

  final updatedDataMultis =
      dataMultis.values.map((outlet) => cablesByOutletId.containsKey(outlet.uid)
          ? cablesByOutletId[outlet.uid]!
          : CableModel(
              uid: getUid(),
              type: CableType.sneak,
              outletId: outlet.uid,
              locationId: outlet.locationId,
            ));

  final updatedDataPatches = dataPatches.values
      .where((patch) => patch.multiId.isEmpty)
      .map((outlet) => cablesByOutletId.containsKey(outlet.uid)
          ? cablesByOutletId[outlet.uid]!
          : CableModel(
              uid: getUid(),
              type: CableType.dmx,
              outletId: outlet.uid,
              locationId: outlet.locationId,
            ));

  final dirtyCables = convertToModelMap([
    ...updatedPowerCables,
    ...updatedDataMultis,
    ...updatedDataPatches,
  ]);
  final dirtyLooms = existingLooms;

  return cleanupCablesAndLooms(dirtyCables, dirtyLooms);
}
