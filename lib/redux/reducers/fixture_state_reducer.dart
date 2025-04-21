import 'package:collection/collection.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';

FixtureState fixtureStateReducer(FixtureState state, dynamic a) {
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
            dataPatches: state.dataPatches));
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

  if (a is SetLocationPowerLock) {
    return state.copyWith(
        locations: state.locations.clone()
          ..update(a.locationId,
              (existing) => existing.copyWith(isPowerPatchLocked: a.value)));
  }

  if (a is SetLocationDataLock) {
    return state.copyWith(
        locations: state.locations.clone()
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
    return state.copyWith(
      fixtureTypes: state.fixtureTypes.clone()
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
      dataMultis: _assertDataMultiState(a.multis, state.locations),
    );
  }

  if (a is SetDataPatches) {
    return state.copyWith(
      dataPatches: _assertDataPatchState(a.patches, state.locations),
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
      dataMultis: _assertOutletNameAndNumbers<DataMultiModel>(
              state.dataMultis.values, a.locations)
          .toModelMap(),
      powerMultiOutlets: _assertOutletNameAndNumbers<PowerMultiOutletModel>(
              state.powerMultiOutlets.values, a.locations)
          .toModelMap(),
      dataPatches: _assertOutletNameAndNumbers<DataPatchModel>(
              state.dataPatches.values, a.locations)
          .toModelMap(),
    );
  }

  if (a is SetPowerOutlets) {
    return state.copyWith(
      outlets: a.outlets,
    );
  }

  if (a is SetPowerMultiOutlets) {
    return state.copyWith(
      powerMultiOutlets:
          _assertPowerMultiState(a.multiOutlets, state.locations),
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

Map<String, PowerMultiOutletModel> _assertPowerMultiState(
    Map<String, PowerMultiOutletModel> multiOutlets,
    Map<String, LocationModel> locations) {
  final outletsByLocationId =
      multiOutlets.values.groupListsBy((item) => item.locationId);

  final sortedOutlets = locations.values
      .map((location) => (outletsByLocationId[location.uid] ?? []).sorted())
      .flattened;

  return _assertOutletNameAndNumbers<PowerMultiOutletModel>(
          sortedOutlets, locations)
      .toModelMap();
}

Map<String, DataMultiModel> _assertDataMultiState(
    Map<String, DataMultiModel> multiOutlets,
    Map<String, LocationModel> locations) {
  final outletsByLocationId =
      multiOutlets.values.groupListsBy((item) => item.locationId);

  final sortedOutlets = locations.values
      .map((location) => (outletsByLocationId[location.uid] ?? [])
          .sorted((a, b) => b.number - a.number))
      .flattened;

  return _assertOutletNameAndNumbers<DataMultiModel>(sortedOutlets, locations)
      .toModelMap();
}

Map<String, DataPatchModel> _assertDataPatchState(
    Map<String, DataPatchModel> dataPatches,
    Map<String, LocationModel> locations) {
  final patchesByLocationId =
      dataPatches.values.groupListsBy((item) => item.locationId);

  final sortedPatches = locations.values
      .map((location) => (patchesByLocationId[location.uid] ?? []).sorted())
      .flattened;

  return _assertOutletNameAndNumbers<DataPatchModel>(sortedPatches, locations)
      .toModelMap();
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

List<T> _assertOutletNameAndNumbers<T extends Outlet>(
    Iterable<Outlet> outlets, Map<String, LocationModel> locations) {
  final typedOutlets = outlets.whereType<T>();

  final outletsByLocationId =
      typedOutlets.groupListsBy((outlet) => outlet.locationId);

  return outletsByLocationId.entries
      .map((entry) {
        final locationId = entry.key;

        final location = locations[locationId]!;
        final outletsInLocation = entry.value;

        return outletsInLocation.mapIndexed((index, outlet) =>
            _updateOutletNameAndNumber(outlet,
                location.getPrefixedNameByType(outlet, index + 1), index + 1));
      })
      .flattened
      .toList()
      .cast<T>();
}

Outlet _updateOutletNameAndNumber(Outlet outlet, String name, int number) {
  return switch (outlet) {
    PowerMultiOutletModel o => o.copyWith(name: name, number: number),
    DataPatchModel o => o.copyWith(name: name, number: number),
    DataMultiModel o => o.copyWith(name: name, number: number),
    _ => throw UnimplementedError('No handling for Type ${outlet.runtimeType}')
  };
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
