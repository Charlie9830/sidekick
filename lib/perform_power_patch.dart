import 'package:collection/collection.dart';
import 'package:sidekick/assert_outlet_name_and_number.dart';
import 'package:sidekick/balancer/models/balancer_fixture_model.dart';
import 'package:sidekick/balancer/models/balancer_multi_outlet_model.dart';
import 'package:sidekick/balancer/naive_balancer.dart';
import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';

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
  required int maxSequenceBreak,
  required double balanceTolerance,
}) {
  final balancer = NaiveBalancer();

  final sortedFixtures = FixtureModel.sort(fixtures, locations);

  final unbalancedMultiOutlets = balancer.assignToOutlets(
    fixtures: sortedFixtures.values
        .map((fixture) => BalancerFixtureModel.fromFixture(
            fixture: fixture, type: fixtureTypes[fixture.typeId]!))
        .toList(),
    multiOutlets: powerMultiOutlets.values.toList(),
    maxSequenceBreak: maxSequenceBreak,
  );

  final balancedMultiOutlets = _balanceOutlets(
    unbalancedMultiOutlets: unbalancedMultiOutlets,
    balancer: balancer,
    balanceTolerance: balanceTolerance,
  );

  final withDefaultMultiOutletNamesAndAssertedState = _assertPowerMultiState(
      _applyDefaultMultiOutletNames(
              multiOutlets: balancedMultiOutlets, locations: locations)
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

List<PowerMultiOutletModel> _balanceOutlets({
  required List<BalancerMultiOutletModel> unbalancedMultiOutlets,
  required NaiveBalancer balancer,
  required double balanceTolerance,
}) {
  PhaseLoad currentLoad = PhaseLoad(0, 0, 0);

  final balancedMultiOutlets = unbalancedMultiOutlets.map((multiOutlet) {
    final balanceResult = balancer.balanceOutlets(multiOutlet.children,
        balanceTolerance: balanceTolerance, initialLoad: currentLoad);

    currentLoad = balanceResult.load;

    return multiOutlet.copyWith(children: balanceResult.outlets);
  });

  return balancedMultiOutlets.map((balancerMultiOutlet) {
    return PowerMultiOutletModel(
        uid: balancerMultiOutlet.uid,
        locationId: balancerMultiOutlet.locationId,
        desiredSpareCircuits: balancerMultiOutlet.desiredSpareCircuits,
        children: balancerMultiOutlet.children
            .map((balancerOutlet) => PowerOutletModel(
                phase: balancerOutlet.phase,
                multiPatch: balancerOutlet.multiPatch,
                fixtureIds: balancerOutlet.child.fixtures
                    .map((fixture) => fixture.uid)
                    .toList(),
                load: balancerOutlet.child.amps))
            .toList());
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
