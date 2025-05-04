import 'package:collection/collection.dart';
import 'package:sidekick/assert_outlet_name_and_number.dart';
import 'package:sidekick/balancer/models/balancer_fixture_model.dart';
import 'package:sidekick/balancer/models/balancer_power_outlet_model.dart';
import 'package:sidekick/balancer/naive_balancer.dart';
import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';

class PowerPatchResult {
  final List<PowerOutletModel> powerOutlets;
  final Map<String, PowerMultiOutletModel> powerMultiOutlets;

  PowerPatchResult({
    required this.powerMultiOutlets,
    required this.powerOutlets,
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

  final unbalancedMultiOutlets = balancer.assignToOutlets(
    fixtures: fixtures.values
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

  final withDefaultMultiOutletNames =
      _applyDefaultMultiOutletNames(balancedMultiOutlets, locations);

  return PowerPatchResult(
      powerMultiOutlets: _assertPowerMultiState(
          Map<String, PowerMultiOutletModel>.from(
              withDefaultMultiOutletNames.keys.toModelMap()),
          locations),
      powerOutlets: withDefaultMultiOutletNames.values.flattened.toList());
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

Map<PowerMultiOutletModel, List<PowerOutletModel>> _balanceOutlets({
  required Map<PowerMultiOutletModel, List<BalancerPowerOutletModel>>
      unbalancedMultiOutlets,
  required NaiveBalancer balancer,
  required double balanceTolerance,
}) {
  PhaseLoad currentLoad = PhaseLoad(0, 0, 0);

  return unbalancedMultiOutlets.map((multiOutlet, outlets) {
    final result = balancer.balanceOutlets(
      outlets,
      balanceTolerance: balanceTolerance,
      initialLoad: currentLoad,
    );

    currentLoad = result.load;

    return MapEntry(
        multiOutlet,
        result.outlets
            .map((balancerOutlet) => PowerOutletModel(
                phase: balancerOutlet.phase,
                multiOutletId: multiOutlet.uid,
                multiPatch: balancerOutlet.multiPatch,
                locationId: balancerOutlet.locationId,
                fixtureIds: balancerOutlet.child.fixtures
                    .map((fixture) => fixture.uid)
                    .toList(),
                load: balancerOutlet.child.amps))
            .toList());
  });
}

/// Looks up the default Multi Outlet names for outlets that have not been assigned a name.
Map<PowerMultiOutletModel, List<PowerOutletModel>>
    _applyDefaultMultiOutletNames(
  Map<PowerMultiOutletModel, List<PowerOutletModel>> balancedMultiOutlets,
  Map<String, LocationModel> locations,
) {
  return Map<PowerMultiOutletModel, List<PowerOutletModel>>.fromEntries(
      balancedMultiOutlets.entries.map((entry) {
    final outlet = entry.key;

    final location = locations[outlet.locationId];

    if (location == null) {
      return entry;
    }

    final multisInLocation = balancedMultiOutlets.keys
        .where((multi) => multi.locationId == location.uid)
        .toList();

    final outletName = location.getPrefixedPowerMulti(
        multisInLocation.length > 1 ? outlet.number : null);

    return MapEntry(
      outlet.copyWith(name: outletName),
      entry.value,
    );
  }));
}
