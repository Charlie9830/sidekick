import 'package:collection/collection.dart';
import 'package:sidekick/multi_outlet_asserts.dart';
import 'package:sidekick/assert_outlet_name_and_number.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/perform_power_patch.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/redux/reducers/fixture_state/assert_cable_state.dart';

/// Handles location-related actions. Returns null when the action
/// is not handled here.
FixtureState? reduceLocationActions(FixtureState state, dynamic a) {
  if (a is RemoveLocation) {
    return _removeLocation(state, a.location);
  }

  if (a is UpdateLocationDelimiter) {
    return state.copyWith(
      locations: state.locations.clone()
        ..update(
          a.locationId,
          (existing) => existing.copyWith(delimiter: a.newValue),
        ),
    );
  }

  if (a is UpdateLocationColor) {
    return state.copyWith(
      locations: state.locations.clone()
        ..update(
          a.locationId,
          (existing) => existing.copyWith(color: a.newValue),
        ),
    );
  }

  if (a is SetLocations) {
    final outlets = performPowerPatch(
      fixtures: state.fixtures,
      fixtureTypes: state.fixtureTypes,
      powerMultiOutlets: state.powerMultiOutlets,
      locations: a.locations,
      maxSequenceBreak: state.maxSequenceBreak,
      balanceTolerance: state.balanceTolerance,
      powerRacks: state.powerRacks,
      fixtureTypePools: state.fixtureTypePools,
    );

    return state.copyWith(
      locations: a.locations,
      fixtures: outlets.fixtures,
      dataMultis: assertOutletNameAndNumbers<DataMultiModel>(
        state.dataMultis.values,
        a.locations,
      ).toModelMap(),
      powerMultiOutlets: assertOutletNameAndNumbers<PowerMultiOutletModel>(
        outlets.powerMultiOutlets.values,
        a.locations,
      ).toModelMap(),
      dataPatches: assertOutletNameAndNumbers<DataPatchModel>(
        state.dataPatches.values,
        a.locations,
      ).toModelMap(),
      // Don't Assert hoist Outlet Names and Numbers here.
      // Because we let the User customize the name of Hoists,
      // Asserting it will bork what they have entered.
      hoistMultis: assertOutletNameAndNumbers<HoistMultiModel>(
        state.hoistMultis.values,
        a.locations,
      ).toModelMap(),
    );
  }

  return null;
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
    final idMoves = hybridLocationsToRemove.map(
      (location) => LocationIDReferenceMove(
        oldId: location.uid,
        newId: location.hybridIds.firstWhere((id) => id != location.uid),
      ),
    );

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

  final hybridLocationIdsToRemove = hybridLocationsToRemove
      .map((location) => location.uid)
      .toSet();

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
      updatedDataMultis,
    ); // Data Multis may have an updated locationId if it was previously pointing to a hybrid location that we removed.

  final hoistOutlets = state.hoists.clone()
    ..removeWhere((id, _) => hoistIdsToRemove.contains(id))
    ..values;

  final hoistMultis = state.hoistMultis.clone()
    ..addAll(updatedHoistMultis)
    ..removeWhere((id, _) => hoistMultisToRemove.contains(id));

  final cables = assertCableState(
    cables: state.cables,
    powerMultiOutlets: state.powerMultiOutlets,
    dataMultis: dataMultis,
    dataPatches: state.dataPatches,
    hoistMultis: hoistMultis,
    hoistOutlets: hoistOutlets,
  );

  final locations = state.locations.clone()
    ..removeWhere(
      (id, location) => hybridLocationIdsToRemove.contains(id),
    ) // Remove any Hybrid Locations that no longer need to be hybrid.
    ..updateAll(
      (
        id,
        existing,
      ) => // Remove the reference to the location from any existing Hybrid Locations.
      existing.isHybrid && existing.hybridIds.contains(location.uid)
          ? existing.copyWith(
              hybridIds: existing.hybridIds.toSet()..remove(location.uid),
            )
          : existing,
    )
    ..remove(location.uid); // Remove the actual Location.

  return state.copyWith(
    locations: locations,
    cables: cables,
    dataMultis: assertMultiOutletState<DataMultiModel>(
      multiOutlets: dataMultis,
      locations: locations,
      cables: cables,
    ),
    hoistMultis: assertMultiOutletState<HoistMultiModel>(
      multiOutlets: hoistMultis,
      locations: locations,
      cables: cables,
    ),
  );
}

class LocationIDReferenceMove {
  final String oldId;
  final String newId;

  LocationIDReferenceMove({required this.oldId, required this.newId});
}
