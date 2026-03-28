import 'package:sidekick/balancer/balancer_result.dart';
import 'package:sidekick/balancer/models/balancer_fixture_model.dart';
import 'package:sidekick/balancer/models/balancer_location_model.dart';
import 'package:sidekick/balancer/models/balancer_multi_outlet_model.dart';
import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/redux/models/fixture_type_pool_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/balancer/models/balancer_outlet_model.dart';

abstract class Balancer {
  List<BalancerMultiOutletModel> assignToOutlets({
    required List<BalancerFixtureModel> fixtures,
    required List<PowerMultiOutletModel> multiOutlets,
    required Map<String, BalancerLocationModel> locations,
    required Map<String, FixtureTypePoolModel> allFixtureTypePools,
    int globalMaxSequenceBreak = 4,
  });

  BalancerResult balanceOutlets(
    List<BalancerOutletModel> outlets, {
    double balanceTolerance = 0.5,
    PhaseLoad initialLoad = const PhaseLoad.zero(),
  });
}
