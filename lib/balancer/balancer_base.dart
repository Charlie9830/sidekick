import 'package:sidekick/balancer/balancer_result.dart';
import 'package:sidekick/balancer/models/balancer_fixture_model.dart';
import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/balancer/models/balancer_power_outlet_model.dart';

abstract class Balancer {
  Map<PowerMultiOutletModel, List<BalancerPowerOutletModel>> assignToOutlets({
    required List<BalancerFixtureModel> fixtures,
    required List<PowerMultiOutletModel> multiOutlets,
    int maxSequenceBreak = 4,
  });

  BalancerResult balanceOutlets(
    List<BalancerPowerOutletModel> outlets, {
    double balanceTolerance = 0.5,
    PhaseLoad initialLoad = const PhaseLoad.zero(),
  });
}
