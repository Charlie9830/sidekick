import 'package:collection/collection.dart';
import 'package:sidekick/multi_outlet_asserts.dart';
import 'package:sidekick/assert_outlet_name_and_number.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/perform_data_patch.dart';
import 'package:sidekick/perform_power_patch.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/hoist_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';

FixtureState fixtureStateReducer(FixtureState state, dynamic a) {
  if (a is SetPowerRacks) {
    return state.copyWith(
      powerRacks: a.racks,
    );
  }

  if (a is UpdatePowerRackName) {
    return state.copyWith(
        powerRacks: state.powerRacks.clone()
          ..update(a.rackId,
              (existing) => existing.copyWith(name: a.newValue.trim())));
  }

  if (a is UpdatePowerRackNote) {
    return state.copyWith(
        powerRacks: state.powerRacks.clone()
          ..update(a.rackId,
              (existing) => existing.copyWith(note: a.newValue.trim())));
  }

  if (a is SetHoistsAndControllers) {
    return state.copyWith(
      hoists: a.hoists,
      hoistControllers: a.hoistControllers,
    );
  }

  if (a is RemoveLocation) {
    return _removeLocation(state, a.location);
  }

  if (a is UpdateHoistNote) {
    return state.copyWith(
      hoists: state.hoists.clone()
        ..update(a.id,
            (existing) => existing.copyWith(controllerNote: a.value.trim())),
    );
  }

  if (a is SetHoists) {
    return state.copyWith(
        hoists: a.value,
        cables: _assertCableState(
            cables: state.cables,
            powerMultiOutlets: state.powerMultiOutlets,
            dataMultis: state.dataMultis,
            dataPatches: state.dataPatches,
            hoistOutlets: a.value,
            hoistMultis: state.hoistMultis));
  }

  if (a is SetHoistControllers) {
    return state.copyWith(hoistControllers: a.value);
  }

  if (a is UpdateHoistControllerName) {
    return state.copyWith(
        hoistControllers: state.hoistControllers.clone()
          ..update(a.hoistId,
              (existing) => existing.copyWith(name: a.value.trim())));
  }

  if (a is UpdateHoistControllerWayCount) {
    return state.copyWith(
        hoistControllers: state.hoistControllers.clone()
          ..update(a.hoistId, (existing) => existing.copyWith(ways: a.value)));
  }

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
      cables: _assertCableState(
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
        cables: _assertCableState(
      cables: _toggleCableDropperState(a.loomId, state.cables),
      powerMultiOutlets: state.powerMultiOutlets,
      dataMultis: state.dataMultis,
      dataPatches: state.dataPatches,
      hoistMultis: state.hoistMultis,
      hoistOutlets: state.hoists,
    ));
  }

  if (a is SetCables) {
    final cables = _assertCableState(
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
          cables: cables),
      hoistMultis: assertMultiOutletState<HoistMultiModel>(
          multiOutlets: state.hoistMultis,
          locations: state.locations,
          cables: cables),
    );
  }

  if (a is UpdateLoomLength) {
    return _updateLoomLength(state, a);
  }

  if (a is SetCablesAndLooms) {
    final cables = _assertCableState(
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
            cables: cables),
        hoistMultis: assertMultiOutletState<HoistMultiModel>(
            multiOutlets: state.hoistMultis,
            locations: state.locations,
            cables: cables));
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
      dataMultis: assertMultiOutletState<DataMultiModel>(
        multiOutlets: a.multis,
        locations: state.locations,
        cables: state.cables,
      ),
    );
  }

  if (a is SetHoistMultis) {
    return state.copyWith(
      hoistMultis: assertMultiOutletState<HoistMultiModel>(
        multiOutlets: a.multis,
        locations: state.locations,
        cables: state.cables,
      ),
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
    final outlets = performPowerPatch(
      fixtures: state.fixtures,
      fixtureTypes: state.fixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: a.locations,
      maxSequenceBreak: state.maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
    );

    return state.copyWith(
      locations: a.locations,
      fixtures: outlets.fixtures,
      dataMultis: assertOutletNameAndNumbers<DataMultiModel>(
              state.dataMultis.values, a.locations)
          .toModelMap(),
      powerMultiOutlets: assertOutletNameAndNumbers<PowerMultiOutletModel>(
              outlets.powerMultiOutlets.values, a.locations)
          .toModelMap(),
      dataPatches: assertOutletNameAndNumbers<DataPatchModel>(
              state.dataPatches.values, a.locations)
          .toModelMap(),
      // Don't Assert hoist Outlet Names and Numbers here.
      // Because we let the User customize the name of Hoists,
      // Asserting it will bork what they have entered.
      hoistMultis: assertOutletNameAndNumbers<HoistMultiModel>(
              state.hoistMultis.values, a.locations)
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

FixtureState _removeLocation(FixtureState state, LocationModel location) {
  if (location.isRiggingOnlyLocation == false) {
    // Only perform this action on Rigging Only locations.. God help us if we tried to do this to a non rigging location.
    return state;
  }

  // Determine if we have any Hybrid locations that contain this location and only 1 other location.
  // If that is the case, The other locationId needs to be cherry picked out of the Hybrid location, and any
  // items referencing the hybrid location need to be re-referenced to the proper location.
  final hybridLocationsToRemove = state.locations.values
      .where((item) => item.isHybrid)
      .where((item) => item.hybridIds.contains(location.uid))
      .where((item) => item.hybridIds.length == 2)
      .toList();

  Map<String, DataMultiModel> updatedDataMultis = state.dataMultis;
  Map<String, HoistMultiModel> updatedHoistMultis = state.hoistMultis;
  if (hybridLocationsToRemove.isNotEmpty) {
    /// Create a list of [LocationIDReferenceMove] objects that store the Old ID and the new ID.
    final idMoves = hybridLocationsToRemove.map((location) =>
        LocationIDReferenceMove(
            oldId: location.uid,
            newId: location.hybridIds.firstWhere((id) => id != location.uid)));

    // Iterate through the list of [LocationIDReferenceMove]. If an ID move needs to occur, perform it then
    // assign that changed Multi to its respective updated map.
    for (final idMove in idMoves) {
      final updatedDataMulti = state.dataMultis.values
          .firstWhereOrNull((multi) => multi.locationId == idMove.oldId)
          ?.copyWith(locationId: idMove.newId);
      if (updatedDataMulti != null) {
        updatedDataMultis.addAll({updatedDataMulti.uid: updatedDataMulti});
      }

      final updatedHoistMulti = state.hoistMultis.values
          .firstWhereOrNull((multi) => multi.locationId == idMove.oldId)
          ?.copyWith(locationId: idMove.newId);
      if (updatedHoistMulti != null) {
        updatedHoistMultis.addAll({updatedHoistMulti.uid: updatedHoistMulti});
      }
    }
  }

  final hybridLocationIdsToRemove =
      hybridLocationsToRemove.map((location) => location.uid).toSet();

  final hoistIdsToRemove = state.hoists.values
      .where((hoist) => hoist.locationId == location.uid)
      .map((hoist) => hoist.uid)
      .toSet();
  final hoistMultisToRemove = state.hoists.values
      .where((multi) => multi.locationId == location.uid)
      .map((multi) => multi.uid)
      .toSet();

  final dataMultis = state.dataMultis.clone()
    ..addAll(
        updatedDataMultis); // Data Multis may have an updated locationId if it was previously pointing to a hybrid location that we removed.

  final hoistOutlets = state.hoists.clone()
    ..removeWhere((id, _) => hoistIdsToRemove.contains(id))
    ..values;

  final hoistMultis = state.hoistMultis.clone()
    ..addAll(updatedHoistMultis)
    ..removeWhere((id, _) => hoistMultisToRemove.contains(id));

  final cables = _assertCableState(
    cables: state.cables,
    powerMultiOutlets: state.powerMultiOutlets,
    dataMultis: dataMultis,
    dataPatches: state.dataPatches,
    hoistMultis: hoistMultis,
    hoistOutlets: hoistOutlets,
  );

  final locations = state.locations.clone()
    ..removeWhere((id, location) => hybridLocationIdsToRemove.contains(
        id)) // Remove any Hybrid Locations that no longer need to be hybrid.
    ..updateAll((id,
            existing) => // Remove the reference to the location from any existing Hybrid Locations.
        existing.isHybrid && existing.hybridIds.contains(location.uid)
            ? existing.copyWith(
                hybridIds: existing.hybridIds.toSet()..remove(location.uid))
            : existing)
    ..remove(location.uid); // Remove the actual Location.

  return state.copyWith(
    locations: locations,
    cables: cables,
    dataMultis: assertMultiOutletState<DataMultiModel>(
        multiOutlets: dataMultis, locations: locations, cables: cables),
    hoistMultis: assertMultiOutletState<HoistMultiModel>(
        multiOutlets: hoistMultis, locations: locations, cables: cables),
  );
}

class LocationIDReferenceMove {
  final String oldId;
  final String newId;

  LocationIDReferenceMove({
    required this.oldId,
    required this.newId,
  });
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
    cables: _assertCableState(
      cables: updatedCables,
      powerMultiOutlets: state.powerMultiOutlets,
      dataMultis: state.dataMultis,
      dataPatches: state.dataPatches,
      hoistMultis: state.hoistMultis,
      hoistOutlets: state.hoists,
    ),
  );
}

Map<String, CableModel> _assertCableState({
  required Map<String, CableModel> cables,
  required Map<String, PowerMultiOutletModel> powerMultiOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, DataPatchModel> dataPatches,
  required Map<String, HoistModel> hoistOutlets,
  required Map<String, HoistMultiModel> hoistMultis,
}) {
  final cablesByOutletId = cables.values.groupListsBy((item) => item.outletId);

  final powerMultisByLocationId =
      powerMultiOutlets.values.groupListsBy((element) => element.locationId);
  final dataMultisByLocationId =
      dataMultis.values.groupListsBy((element) => element.locationId);
  final dataPatchesByLocationId =
      dataPatches.values.groupListsBy((element) => element.locationId);
  final hoistOutletsByLocationId =
      hoistOutlets.values.groupListsBy((element) => element.locationId);
  final hoistMultisByLocationId =
      hoistMultis.values.groupListsBy((element) => element.locationId);

  final orderedOutletIds = [
    ...powerMultisByLocationId.values
        .map((outletsInLocation) => outletsInLocation.sorted())
        .flattened
        .map((item) => item.uid),
    ...dataMultisByLocationId.values
        .map((outletsInLocation) => outletsInLocation.sorted())
        .flattened
        .map((item) => item.uid),
    ...dataPatchesByLocationId.values
        .map((outletsInLocation) => outletsInLocation.sorted())
        .flattened
        .map((item) => item.uid),
    ...hoistMultisByLocationId.values
        .map((outletsInLocation) => outletsInLocation.sorted())
        .flattened
        .map((item) => item.uid),
    ...hoistOutletsByLocationId.values
        .map((outletsInLocation) => outletsInLocation.sorted())
        .flattened
        .map((item) => item.uid),

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
