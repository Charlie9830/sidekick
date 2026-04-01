import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:sidekick/assert_outlet_name_and_number.dart';
import 'package:sidekick/balancer/models/balancer_fixture_model.dart';
import 'package:sidekick/balancer/models/balancer_location_model.dart';
import 'package:sidekick/balancer/models/balancer_multi_outlet_model.dart';
import 'package:sidekick/balancer/naive_balancer.dart';
import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/fixture_type_pool_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_feed_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/redux/models/power_rack_model.dart';

class PowerPatchResult {
  final Map<String, PowerMultiOutletModel> powerMultiOutlets;
  final Map<String, FixtureModel> fixtures;

  PowerPatchResult({
    required this.powerMultiOutlets,
    required this.fixtures,
  });
}

PowerPatchResult performPowerPatch({
  required Map<String, FixtureModel> fixtures,
  required Map<String, FixtureTypeModel> fixtureTypes,
  required Map<String, PowerMultiOutletModel> powerMultiOutlets,
  required Map<String, LocationModel> locations,
  required Map<String, PowerRackModel> powerRacks,
  required Map<String, FixtureTypePoolModel> fixtureTypePools,
  required int maxSequenceBreak,
  required double balanceTolerance,
}) {
  final balancer = NaiveBalancer();

  final sortedFixtures = FixtureModel.sort(fixtures, locations).values.toList();

  final unbalancedMultiOutlets = balancer.assignToOutlets(
    fixtures: sortedFixtures
        .map((fixture) => BalancerFixtureModel.fromFixture(
            fixture: fixture, type: fixtureTypes[fixture.typeId]!))
        .toList(),
    allFixtureTypePools: fixtureTypePools,
    multiOutlets: powerMultiOutlets.values.toList(),
    globalMaxSequenceBreak: maxSequenceBreak,
    locations: Map<String, BalancerLocationModel>.from(locations.map(
        (key, value) =>
            MapEntry(key, BalancerLocationModel.fromLocation(value)))),
  );

  final unbalancedMultiOutletsByPowerFeedId =
      unbalancedMultiOutlets.groupListsBy((outlet) {
    final rackId = outlet.parentRack.rackId;

    if (rackId.isEmpty) {
      return const PowerFeedModel.defaultFeed().uid;
    }

    final rack = powerRacks[rackId];

    if (rack == null || rack.powerFeedId.isEmpty) {
      return const PowerFeedModel.defaultFeed().uid;
    }

    return rack.powerFeedId;
  });

  final balancedIntermediateMultiOutlets =
      unbalancedMultiOutletsByPowerFeedId.entries
          .map((entry) {
            // ignore: unused_local_variable
            final feedId = entry
                .key; // TODO: Keep this handy, we may use it to then lookup feed specific properties, like balance tolerance.
            final associatedOutlets = entry.value;

            return _balanceOutlets(
              unbalancedMultiOutlets: associatedOutlets,
              balancer: balancer,
              balanceTolerance: balanceTolerance,
            );
          })
          .flattened
          .toList();

  final updatedPowerMultiOutlets = _mapToMultiOutlets(
      balancerOutlets: balancedIntermediateMultiOutlets,
      fixtures: sortedFixtures,
      locations: locations.values.toList());

  if (kDebugMode) {
    _validateState(
        fixtures: fixtures,
        multis: updatedPowerMultiOutlets,
        fixtureTypes: fixtureTypes,
        locations: locations);
  }

  final withDefaultMultiOutletNamesAndAssertedState = _assertPowerMultiState(
      _applyDefaultMultiOutletNames(
              multiOutlets: updatedPowerMultiOutlets, locations: locations)
          .toModelMap(),
      locations);

  return PowerPatchResult(
    powerMultiOutlets: withDefaultMultiOutletNamesAndAssertedState,
    fixtures: _applyPowerPatchData(
        _extractPowerPatchDataByFixtureId(
            withDefaultMultiOutletNamesAndAssertedState),
        fixtures),
  );
}

List<PowerMultiOutletModel> _mapToMultiOutlets({
  required List<BalancerMultiOutletModel> balancerOutlets,
  required List<FixtureModel> fixtures,
  required List<LocationModel> locations,
}) {
  // It is extremely important that we ensure the Outlets have the same sorting structure as the Fixtures we are about to feed into them.
  // If not, then we could be blindly placing the wrong fixtures into the wrong outlets.
  // This is because we now separate the Fixture from it's fixture id and essentially pass it through the balancer as just a Fixture type only.
  // This saves us the hassle of having to clean up and reorder fixture numbers after balancing, but means we have to pull a pro manouver where we
  // remap all of the Fixtures back onto their correct Outlets.
  // If the Ordering of the outlets has changed, then we will end up assigning the wrong fixtures to the wrong outlets, this is a critical error.
  // Therefore its of upmost importance that we ensure the outlet ordering matches Natural ordering
  final outletsByLocationId =
      balancerOutlets.groupListsBy((outlet) => outlet.locationId);
  final outletGroupsSortedByLocationId =
      Map<String, List<BalancerMultiOutletModel>>.fromEntries(locations.map(
          (location) =>
              MapEntry(location.uid, outletsByLocationId[location.uid] ?? [])));
  final sortedBalancerMultiOutlets = outletGroupsSortedByLocationId
      .values.flattened
      .toList(); // You may be tempted to sort these outlets by their number property, dont, that number property has not been set yet.
  // We have to trust the iteration order.

  final fixturesByTypeQueues = fixtures.groupListsBy((fix) => fix.typeId).map(
        (typeId, fixtures) => MapEntry(
          typeId,
          Queue<FixtureModel>.from(fixtures),
        ),
      );

  final result = sortedBalancerMultiOutlets.map((multi) {
    return PowerMultiOutletModel(
        uid: multi.uid,
        locationId: multi.locationId,
        parentRack: multi.parentRack,
        desiredSpareCircuits: multi.desiredSpareCircuits,
        children: multi.children.map((outlet) {
          return PowerOutletModel(
              fixtureTypePoolId: outlet.contents.fixtureTypePoolId,
              load: outlet.contents.amps,
              multiPatch: outlet.multiPatch,
              phase: outlet.phase,
              isSpare: outlet.isSpare,
              fixtureIds: outlet.contents.fixtures
                  .map((intermediate) => fixturesByTypeQueues[
                          intermediate.type.uid]!
                      .removeFirst()) // Uh oh. If you are here, we have some critical issues with how these fixtures are getting married by together with their outlets.
                  .nonNulls
                  .map((fixture) => fixture.uid)
                  .toList());
        }).toList());
  }).toList();

  assert(
      fixturesByTypeQueues.values.every(
        (queue) => queue.isEmpty,
      ),
      "Not every Fixture queue was completely flushed, this suggests a critical error has occured with mapping fixtures back to their assigned Power outlets.");

  return result;
}

Map<String, FixtureModel> _applyPowerPatchData(
    Map<String, String> powerPatchData, Map<String, FixtureModel> fixtures) {
  return fixtures.clone()
    ..updateAll((id, fixture) =>
        fixture.copyWith(powerPatch: powerPatchData[id] ?? ''));
}

// Returns a Map<String, String> where the key is the fixture Id and the value is the formatted Power patch data for the fixture.
Map<String, String> _extractPowerPatchDataByFixtureId(
    Map<String, PowerMultiOutletModel> multiOutlets) {
  return Map<String, String>.fromEntries(multiOutlets.values.map((multi) {
    final fixtureIdsWithOutlets = multi.children
        .map((outlet) => outlet.fixtureIds.map((id) => (id, outlet)))
        .flattened;

    return fixtureIdsWithOutlets.map((tuple) =>
        MapEntry(tuple.$1, "${multi.name} - ${tuple.$2.multiPatch}"));
  }).flattened);
}

Map<String, PowerMultiOutletModel> _assertPowerMultiState(
    Map<String, PowerMultiOutletModel> multiOutlets,
    Map<String, LocationModel> locations) {
  final outletsByLocationId =
      multiOutlets.values.groupListsBy((item) => item.locationId);

  final sortedOutlets = locations.values
      .map((location) => (outletsByLocationId[location.uid] ?? []).sorted())
      .flattened;

  return assertOutletNameAndNumbers<PowerMultiOutletModel>(
          sortedOutlets, locations)
      .toModelMap();
}

List<BalancerMultiOutletModel> _balanceOutlets({
  required List<BalancerMultiOutletModel> unbalancedMultiOutlets,
  required NaiveBalancer balancer,
  required double balanceTolerance,
}) {
  PhaseLoad currentLoad = PhaseLoad(0, 0, 0);

  return unbalancedMultiOutlets.map((multiOutlet) {
    final balanceResult = balancer.balanceOutlets(multiOutlet.children,
        balanceTolerance: balanceTolerance, initialLoad: currentLoad);

    currentLoad = balanceResult.load;

    return multiOutlet.copyWith(children: balanceResult.outlets);
  }).toList();
}

List<PowerMultiOutletModel> _applyDefaultMultiOutletNames({
  required List<PowerMultiOutletModel> multiOutlets,
  required Map<String, LocationModel> locations,
}) {
  final multisByLocationId =
      multiOutlets.groupListsBy((multi) => multi.locationId);

  return multiOutlets.map((multi) {
    final location = locations[multi.locationId];

    if (location == null) {
      return multi;
    }

    final multisInLocation = multisByLocationId[location.uid]!;

    final multiName = location.getPrefixedPowerMulti(
        multisInLocation.length > 1 ? multi.number : null);

    return multi.copyWith(
      name: multiName,
    );
  }).toList();
}

void _validateState({
  required List<PowerMultiOutletModel> multis,
  required Map<String, FixtureModel> fixtures,
  required Map<String, LocationModel> locations,
  required Map<String, FixtureTypeModel> fixtureTypes,
}) {
  final validationItems = multis.map(
    (multi) => _ValidationItem(
      locationIdFromMultiOutlet: multi.locationId,
      fixtures: multi.children
          .map((outlet) => outlet.fixtureIds.map((id) => fixtures[id]!))
          .flattened
          .toList(),
    ),
  );

  final validationResults = validationItems.map((item) =>
      item.runValidation(locations: locations, fixtureTypes: fixtureTypes));

  if (validationResults.any((result) => result != null)) {
    throw 'Critical Balancing Error:\n${validationResults.nonNulls.join('\n')}';
  }
}

class _ValidationItem {
  final String locationIdFromMultiOutlet;
  final List<FixtureModel> fixtures;

  _ValidationItem({
    required this.locationIdFromMultiOutlet,
    required this.fixtures,
  });

  String? runValidation({
    required Map<String, LocationModel> locations,
    required Map<String, FixtureTypeModel> fixtureTypes,
  }) {
    if (fixtures
        .any((fixture) => fixture.locationId != locationIdFromMultiOutlet)) {
      return "Fixture Location Mismatch(s):"
          "\n"
          "${fixtures.where((fixture) => fixture.locationId != locationIdFromMultiOutlet).map((fixture) {
        return "Fixture #${fixture.fid}, a ${fixtureTypes[fixture.typeId]?.shortName} "
            "should belong to a Power Multi assigned to ${locations[fixture.locationId]?.name} "
            "but instead it has been assigned to ${locations[locationIdFromMultiOutlet]}.\n";
      })}";
    }

    return null;
  }
}
